local math = require('math')
local EASE = require('vimade.style.value.ease')
local CONDITION = require('vimade.style.value.condition')
local DIRECTION = require('vimade.style.value.direction')
local ANIMATOR = require('vimade.animator')
local COLOR_UTIL = require('vimade.util.color')
local TYPE = require('vimade.util.type')
local M = {}
local GLOBALS

local MATH_MIN = math.min
local MATH_MAX = math.max
local INTERPOLATE_FLOAT = COLOR_UTIL.interpolateFloat
local INTERPOLATE_RGB = COLOR_UTIL.interpolateRgb

M.__init = function (args)
  GLOBALS = args.GLOBALS
end

local DEFAULT_DURATION = 300
local DEFAULT_DELAY = 0
local DEFAULT_EASE = EASE.OUT_QUART
local DEFAULT_DIRECTION = DIRECTION.OUT

local ids = 0
local get_next_id = function ()
  ids = ids + 1
  return ids
end

M.EASE = EASE
M.DIRECTION = DIRECTION 

--@param config {
--  @required to = number | function -> number
--  @optional id: string | number | function -> string = 0 -- used to share state between values that might cross over between filters, exclusions, and other rules
--  @optional start: number | function -> number = 0
--  @optional duration: number | function -> number = 300
--  @optional delay: number | function -> number = 0
--  @optional ease: EASE | function -> EASE = EASE.OUT_QUART
--  @optional direction: DIRECTION | function -> DIRECTION 
--}
M.Number = function (config)
  config = TYPE.shallow_copy(config)
  config.interpolate = INTERPOLATE_FLOAT
  config.compare = function (value, last)
    return value == last
  end
  return M.Animate(config)
end

M.Rgb = function(config)
  config = TYPE.shallow_copy(config)
  config.interpolate = INTERPOLATE_RGB
  config.compare = TYPE.shallow_compare
  return M.Animate(config)
end

M.Invert = function(config)
  config = TYPE.shallow_copy(config)
  config.interpolate = function (to, start, pct_time, style, state)
    local result = {}
    to = to or {}
    start = start or {}
    result.fg = INTERPOLATE_FLOAT(to.fg or 0, start.fg or 0, pct_time)
    result.bg = INTERPOLATE_FLOAT(to.bg or 0, start.bg or 0, pct_time)
    result.sp = INTERPOLATE_FLOAT(to.sp or 0, start.sp or 0, pct_time)
    return result
  end
  config.compare = TYPE.deep_compare
  return M.Animate(config)
end

-- interpolate the entire available tint object
M.Tint = function(config)
  config = TYPE.shallow_copy(config)

  config.interpolate = function (to, start, pct_time)
    if not start and not to then
      return nil
    end
    to = to or {}
    start = start or {}
    local result = {}
    for key, value in pairs(to) do
      if start[key] == nil then
        start[key] = {rgb = value.rgb, intensity = 0}
      end
    end
    for key, value in pairs(start) do
      if to[key] == nil then
        to[key] = {rgb = value.rgb, intensity = 0}
      end
    end
    for key, value in pairs(to) do
      result[key] = {
        rgb = INTERPOLATE_RGB(value.rgb, start[key].rgb, pct_time),
        intensity = INTERPOLATE_FLOAT(value.intensity, start[key].intensity, pct_time),
      }
    end
    return result
  end
  config.compare = TYPE.deep_compare
  return M.Animate(config)
end

--@param config {
--  @required to = number | function -> number
--  @required interpolate = function(pct_time, start_value, to_value) -> value
--  @optional id: string | number | function -> string = 0 -- used to share state between values that might cross over between filters, exclusions, and other rules
--  @optional start: number | function -> number = 0
--  @optional duration: number | function -> number = 300
--  @optional delay: number | function -> number = 0
--  @optional ease: EASE | function -> EASE = EASE.OUT_QUART
--  @optional direction: DIRECTION | function -> DIRECTION 
--}
M.Animate = function (config)
  -- TODO abstract this part (to use with all animations)
  local _custom_id = config.id
  local _id = _custom_id or get_next_id()
  local _interpolate = config.interpolate
  local _start = config.start
  local _to = config.to
  local _duration = config.duration or DEFAULT_DURATION
  local _delay = config.delay or DEFAULT_DELAY
  local _ease = config.ease or DEFAULT_EASE
  local _direction = config.direction or DEFAULT_DIRECTION
  local _reset = config.reset or _direction ~= DIRECTION.IN_OUT
  local _compare = config.compare or nil
  return function(style, state)
    local id
    local win = style.win
    if _custom_id then
      state = state.custom
      if type(_custom_id) == 'function' then
        id = _custom_id(style, state)
      else
        id = _custom_id
      end
    else
      state = state.animations
      id = _id
    end
    if not state[id] then
      state[id] = {}
    end
    state = state[id]
    local to = style.resolve(_to, state)
    local start = style.resolve(_start, state)
    local compare = _compare
    if type(compare) == 'function' then
      compare = compare(to, state.last_to)
    end
    if compare == false then
      state.change_timestamp = GLOBALS.now
    end
    state.last_to = to
    local delay = _delay
    if type(delay) == 'function' then
      delay = delay(style, state)
    end
    local duration = _duration
    if type(duration) == 'function' then
      duration = duration(style, state)
    end
    local direction = _direction
    if type(direction) == 'function' then
      direction = direction(style, state)
    end
    local reset = _reset
    if type(reset) == 'function' then
      reset = reset(style, state)
    end
    -- TODO this logic is nc specific and should be abstracted
    local time = GLOBALS.now - (MATH_MAX(win.timestamps.nc, state.change_timestamp or 0) + delay)
    if (direction == DIRECTION.OUT and style._condition == CONDITION.ACTIVE and style.win.nc == false)
      or (direction == DIRECTION.IN and style._condition == CONDITION.INACTIVE and style.win.nc == true) then
       state.value = to
       state.start = to
       style._animating = false
       return to
    elseif (direction == DIRECTION.OUT and style._condition == CONDITION.ACTIVE and style.win.nc == true)
      or (direction == DIRECTION.IN and style._condition == CONDITION.INACTIVE and style.win.nc == false) then
        local swp = start
        start = to
        to = swp
    elseif (direction == DIRECTION.OUT and style._condition == CONDITION.INACTIVE and style.win.nc == false)
      or (direction == DIRECTION.IN and style._condition == CONDITION.ACTIVE and style.win.nc == true) then
      state.value = start
      state.start = start
      style._animating = false
      return start
    elseif (direction == DIRECTION.OUT and style._condition == CONDITION.INACTIVE and style.win.nc == true)
      or (direction == DIRECTION.IN and style._condition == CONDITION.ACTIVE and style.win.nc == false) then
      -- pass
    end

    if state.value == nil then
      state.value = start
      state.start = start
    end
    if time <= 0 then
      if reset == true then
        state.start = start
        state.value = start
      else
        state.start = state.value
      end
      style._animating = true
      ANIMATOR.schedule(win)
      return state.start
    end
    if time >= duration then
      state.value = to
      style._animating = false
      return to
    end
    local elapsed = time / duration
    elapsed = MATH_MIN(MATH_MAX(_ease(elapsed), 0), 1)
    state.value = _interpolate(to, state.start, elapsed, style, state)
    style._animating = true
    ANIMATOR.schedule(win)
    return state.value
  end
end

return M

local math = require('math')
local EASE = require('vimade.style.value.ease')
local ANIMATOR = require('vimade.animator')
local COLOR_UTIL = require('vimade.util.color')
local TYPE = require('vimade.util.type')
local M = {}

local DEFAULT_DURATION = 300
local DEFAULT_EASE = EASE.OUT_QUART
local DEFAULT_DELAY = 0

local ids = 0
local get_next_id = function ()
  ids = ids + 1
  return ids
end

M.EASE = EASE
M.DIRECTION = {
  IN = 'in',
  OUT = 'out',
  INOUT = function (win, state)
    if win.faded then
      return 'out'
    else
      return 'in'
    end
  end
}

--@param config {
--  @required to = number | function -> number
--  @optional id: string | number | function -> string = 0 -- used to share state between values that might cross over between filters, exclusions, and other rules
--  @optional from: number | function -> number = 0
--  @optional duration: number | function -> number = 300
--  @optional delay: number | function -> number = 0
--  @optional ease: EASE | function -> EASE = EASE.OUT_QUART
--  @optional direction: DIRECTION | function -> DIRECTION 
--}
M.Number = function (config)
  config = TYPE.shallow_copy(config)
  config.interpolate = COLOR_UTIL.interpolateFloat
  return M.Animate(config)
end

M.Rgb = function(config)
  config = TYPE.shallow_copy(config)
  config.interpolate = COLOR_UTIL.interpolateRgb
  return M.Animate(config)
end

-- interpolate the entire available tint object
M.Tint = function(config)
  config = TYPE.shallow_copy(config)

  config.interpolate = function (to, start, pct_time)
    start = start or {}
    to = to or {}
    local result = {}
    local start_fg_rgb = (start.fg and start.fg.rgb) or (to.fg and to.fg.rgb)
    local to_fg_rgb = (to.fg and to.fg.rgb) or start_fg_rgb
    local start_bg_rgb = (start.bg and start.bg.rgb) or (to.bg and to.bg.rgb)
    local to_bg_rgb = (to.bg and to.bg.rgb) or start_bg_rgb
    local start_sp_rgb = (start.sp and start.sp.rgb) or (to.sp and to.sp.rgb)
    local to_sp_rgb = (to.sp and to.sp.rgb) or start_sp_rgb
    local start_fg_intensity = start.fg and start.fg.intensity or 0
    local start_bg_intensity = start.bg and start.bg.intensity or 0
    local start_sp_intensity = start.sp and start.sp.intensity or 0
    local to_fg_intensity = to.fg and to.fg.intensity or 0
    local to_bg_intensity = to.bg and to.bg.intensity or 0
    local to_sp_intensity = to.sp and to.sp.intensity or 0

    if to_fg_rgb then
      result.fg = {}
      result.fg.rgb = COLOR_UTIL.interpolateRgb(to_fg_rgb, start_fg_rgb, pct_time)
      result.fg.intensity = COLOR_UTIL.interpolateFloat(to_fg_intensity, start_fg_intensity, pct_time)
    end

    if to_bg_rgb then
      result.bg = {}
      result.bg.rgb = COLOR_UTIL.interpolateRgb(to_bg_rgb, start_bg_rgb, pct_time)
      result.bg.intensity = COLOR_UTIL.interpolateFloat(to_bg_intensity, start_bg_intensity, pct_time)
    end

    if to_sp_rgb then
      result.sp = {}
      result.sp.rgb = COLOR_UTIL.interpolateRgb(to_sp_rgb, start_sp_rgb, pct_time)
      result.sp.intensity = COLOR_UTIL.interpolateFloat(to_sp_intensity, start_sp_intensity, pct_time)
    end

    return result
  end
  return M.Animate(config)
end

--@param config {
--  @required to = number | function -> number
--  @required interpolate = function(pct_time, start_value, to_value) -> value
--  @optional id: string | number | function -> string = 0 -- used to share state between values that might cross over between filters, exclusions, and other rules
--  @optional from: number | function -> number = 0
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
  local _from = config.from
  local _to = config.to
  local _duration = config.duration or DEFAULT_DURATION
  local _delay = config.delay or DEFAULT_DELAY
  local _ease = config.ease or DEFAULT_EASE
  local _direction = config.direction or M.DIRECTION.OUT
  local _reset = config.reset or (_direction ~= M.DIRECTION.INOUT)
  return function(win, state)
    local id
    if _custom_id then
      state = state.custom
      if type(_custom_id) == 'function' then
        id = _custom_id(win, state)
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
    local from = _from
    if type(from) == 'function' then
      from = from(win, state)
    end
    state = state[id]
    local delay = _delay
    if type(delay) == 'function' then
      delay = delay(win, state)
    end
    local duration = _duration
    if type(duration) == 'function' then
      duration = duration(win, state)
    end
    local to = _to
    if type(to) == 'function' then
      to = to(win, state)
    end
    local direction = _direction
    if type(direction) == 'function' then
      direction = direction(win, state)
    end
    local reset = _reset
    if type(reset) == 'function' then
      reset = direction(win, state)
    end
    local time = GLOBALS.now - (win.timestamps.faded + delay)
    if direction == M.DIRECTION.IN then
      local swp = from
      from = to
      to = swp
    end
    if state.value == nil then
      state.value = from
      state.start = from
    end
    if time == 0 then
      if reset == true then
        state.start = from
      else
        state.start = state.value
      end
    elseif time < 0 then
      state.value = from
      return from
    end
    if time > duration then
      state.value = to
      return to
    end
    local elapsed = time / duration
    elapsed = math.min(math.max(_ease(elapsed), 0), 1)
    state.value = _interpolate(to, state.start, elapsed)
    ANIMATOR.schedule(win)
    return state.value
  end
end

return M

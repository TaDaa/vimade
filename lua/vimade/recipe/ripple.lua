local M = {}
local Include = require('vimade.style.include').Include
local Exclude = require('vimade.style.exclude').Exclude
local ANIMATE = require('vimade.style.value.animate')
local DIRECTION = require('vimade.style.value.direction')
local EASE = require('vimade.style.value.ease')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')
local GLOBALS = require('vimade.state.globals')

local get_win_infos = function ()
  local distance = function (a1, a2, b1, b2)
    return math.sqrt(math.pow(a1-b1, 2) + math.pow(a2-b2, 2))
  end
  local distance_between = function (info_a, info_b)
    local left_a = info_a.wincol * 0.75
    local left_b = info_b.wincol * 0.75
    local right_a = info_a.wincol + info_a.width * 0.75
    local right_b = info_b.wincol + info_b.width * 0.75
    local top_a = info_a.winrow
    local top_b = info_b.winrow
    local bottom_a = info_a.winrow + info_a.height
    local bottom_b = info_b.winrow + info_b.height
    if (bottom_a < top_b) and (right_b < left_a) then
      return distance(left_a, bottom_a, right_b, top_b)
    elseif (right_b < left_a) and (bottom_b < top_a) then
      return distance(left_a, top_a, right_b, bottom_b)
    elseif (bottom_b < top_a) and  (right_a < left_b) then
      return distance(right_a, top_a, left_b, bottom_b)
    elseif (right_a < left_b) and (bottom_a < top_b) then
      return distance(right_a, bottom_a, left_b, top_b)
    elseif (right_b < left_a) then
      return left_a - right_b
    elseif (right_a < left_b) then
      return left_b - right_a
    elseif (bottom_b < top_a) then
      return top_a - bottom_b
    elseif (bottom_a < top_b) then
      return top_b - bottom_a
    else
      return 0
    end
  end
  local wininfo = vim.fn.getwininfo()
  local current_win = GLOBALS.current.winid
  local found_cur = nil
  for i, info in ipairs(wininfo) do
    if info.winid == current_win then
      found_cur = info
      break
    end
  end
  local result = {}
  for i, info in ipairs(wininfo) do
    if GLOBALS.current.tabnr == info.tabnr then
      result[info.winid] = {
        info = info,
        dist = distance_between(info, found_cur),
        area = info.width * info.height
      }
    end
  end
  return result
end

local win_infos = nil
local max_distance = nil
local max_area = nil
local ripple_tick = function()
  win_infos = get_win_infos()
  max_distance = 0
  max_area = 0
  for winid, info in pairs(win_infos) do
    max_distance = math.max(info.dist, max_distance)
    max_area = math.max(info.area, max_area)
  end
end
local ripple_to_tint = function (style, state)
  local to = TINT.Default().value()(style, state)
  local m_dist = max_distance
  if m_dist == 0 then
    m_dist = 1
  end
  if to then
    for i, color in pairs(to) do
      if color.rgb then
        if color.intensity == nil then
          color.intensity = 1
        end
        color.intensity = (win_infos[style.win.winid].dist / m_dist) * color.intensity
      end
    end
  end
  return to
end
local ripple_to_fade = function (style, state)
  local to = FADE.Default().value()(style, state)
  local m_dist = max_distance
  if m_dist == 0 then
    m_dist = 1
  end
  return to + (1-win_infos[style.win.winid].dist / m_dist) * ((1-to) * 0.5)
end
local ripple_duration = function(style, state)
  local m_dist = max_distance
  if m_dist == 0 then
    return 0
  end
  return 100 + (win_infos[style.win.winid].dist / m_dist) * 200
end
local ripple_delay = function(style, state)
  local m_dist = max_distance
  if m_dist == 0 then
    return 0
  end
  return (win_infos[style.win.winid].dist / m_dist) * 300
end
local animate_ripple = function (config)
  local result = {
    TINT.Tint({
      tick = ripple_tick,
      condition = config.condition,
      value = ANIMATE.Tint({
        start = function (style, state)
          local start = TINT.Default().value()(style, state)
          if start then
            for i, color in pairs(start) do
              color.intensity = 0
            end
          end
          return start
        end,
        to = ripple_to_tint,
        direction = config.direction,
        duration = config.duration,
        delay = config.delay,
        ease = config.ease,
      })
    }),
    FADE.Fade({
      condition = config.condition,
      value = ANIMATE.Number({
        to = ripple_to_fade,
        start = 1,
        direction = config.direction,
        duration = config.duration,
        delay = config.delay,
        ease = config.ease,
      }),
    })
  }
  return result
end

local ripple = function (config)
  return {
    TINT.Tint({
      tick = ripple_tick,
      condition = config.condition,
      value = ripple_to_tint,
    }),
    FADE.Fade({
      condition = config.condition,
      value = ripple_to_fade,
    }),
  }
end

--@param config {
  -- @optional animate: boolean = false
  -- @optional condition: CONDITION = CONDITION.INACTIVE
  -- @optional delay: number = ANIMATE.DEFAULT_DELAY
  -- @optional direction: DIRECTION = ANIMATE.DEFAULT_DIRECTION
  -- @optional duration: number = ANIMATE.DEFAULT_DURATION
  -- @optional ease: EASE = ANIMATE.DEFAULT_EASE
--}
M.Ripple = function(config)
  config = TYPE.shallow_copy(config)
  config.direction = config.direction or DIRECTION.IN_OUT
  config.delay = config.delay or ripple_delay
  config.duration = config.duration or ripple_duration
  config.ease = config.ease or EASE.LINEAR
  config.ncmode = config.ncmode or 'windows'
  return {
    style = config.animate and animate_ripple(config) or ripple(config),
    ncmode = config.ncmode
  }
end

return M

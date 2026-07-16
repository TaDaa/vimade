local M = {}

local Include = require('vimade.style.include').Include
local Exclude = require('vimade.style.exclude').Exclude
local ANIMATE = require('vimade.style.value.animate')
local CONDITION = require('vimade.style.value.condition')
local DIRECTION = require('vimade.style.value.direction')
local EASE = require('vimade.style.value.ease')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')
local GLOBALS = require('vimade.state.globals')
local Component = require('vimade.style.component').Component
local Link = require('vimade.style.link').Link
local Invert = require('vimade.style.invert').Invert
local Fade = FADE.Fade
local Tint = TINT.Tint

local default_tint = TINT.Default().value()
local default_fade = FADE.Default().value()

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
    if GLOBALS.current.tabnr == info.tabnr
        and vim.api.nvim_win_is_valid(info.winid)
        and vim.api.nvim_win_get_config(info.winid).relative == '' then
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
  local to = style.resolve(default_tint, state)
  local m_dist = max_distance
  if m_dist == 0 then
    m_dist = 1
  end
  local winid = (style.win.area_owner or style.win).winid
  local dist = win_infos[winid] and (win_infos[winid].dist / m_dist) or 0
  if to then
    for i, color in pairs(to) do
      if color.rgb then
        if color.intensity == nil then
          color.intensity = 1
        end
        color.intensity = dist * color.intensity
      end
    end
  end
  return to
end
local ripple_to_fade = function (style, state)
  local to = style.resolve(default_fade, state)
  if (style.win.area_owner or style.win).nc and GLOBALS.vimade_focus_active then
    return to
  end
  local m_dist = max_distance
  if m_dist == 0 then
    m_dist = 1
  end
  local winid = (style.win.area_owner or style.win).winid
  local dist = win_infos[winid] and (1 - win_infos[winid].dist / m_dist) or 1
  return to + dist * ((1-to) * 0.5)
end
local ripple_duration = function(style, state)
  local m_dist = max_distance
  if not win_infos[style.win.winid] or m_dist == 0 then
    return 0
  end
  return 100 + (win_infos[style.win.winid].dist / m_dist) * 200
end
local ripple_delay = function(style, state)
  local m_dist = max_distance
  if not win_infos[style.win.winid] or m_dist == 0 then
    return 0
  end
  return (win_infos[style.win.winid].dist / m_dist) * 300
end

local ripple_tint = function(config, animation)
  return Tint({
    condition = config.condition,
    value = animation and ANIMATE.Tint({
      start = function (style, state)
        local start = style.resolve(default_tint, state)
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
    }) or ripple_to_tint,
  })
end

local ripple_fade = function(config, animation)
  return Fade({
    condition = config.condition,
    value = animation and ANIMATE.Number({
      to = ripple_to_fade,
      start = animation.start or 1,
      direction = config.direction,
      duration = config.duration,
      delay = config.delay,
      ease = config.ease,
    }) or ripple_to_fade,
  })
end

local ripple = function (config)
  local animation = config.animate and {
    duration = config.duration,
    delay = config.delay,
    ease = config.ease,
    direction = config.direction,
  } or nil
  return {
    Component('Mark', {
      condition = CONDITION.IS_MARK,
      tick = ripple_tick,
      style = {
        Link({
          condition = CONDITION.ALL,
          value = {{from='NormalFloat', to='Normal'}, {from='NormalNC', to='Normal'}}
        }),
        ripple_tint(TYPE.extend({}, config, {
          condition = CONDITION.INACTIVE,
        }), animation),
        Invert({
          condition = CONDITION.ALL,
          value = 0.02,
        })
      },
    }),
    Component('Focus', {
      condition = CONDITION.IS_FOCUS,
      style = {
        Link({
          condition = CONDITION.ALL,
          value = {{from='NormalFloat', to='Normal'}, {from='NormalNC', to='Normal'}}
        }),
        ripple_tint(
          TYPE.extend({}, config, {
            condition = CONDITION.INACTIVE,
          }),
          animation and TYPE.extend({}, animation, {
            direction = DIRECTION.OUT,
          }) or nil
        ),
        ripple_fade(
          TYPE.extend({}, config, {
            condition = CONDITION.INACTIVE,
          }),
          animation and TYPE.extend({}, animation, {
            direction = DIRECTION.OUT,
          }) or nil
        ),
      }
    }),
    Component('Pane', {
      condition = CONDITION.IS_PANE,
      style = {
        ripple_tint(TYPE.extend({}, config, {
          condition = CONDITION.INACTIVE_OR_FOCUS,
        }), animation),
        ripple_fade(
          TYPE.extend({}, config, {
            condition = CONDITION.INACTIVE_OR_FOCUS,
          }),
          animation and TYPE.extend({}, animation, {
            start = function (style, state)
              if GLOBALS.vimade_focus_active then
                return default_fade(style, state)
              else
                return 1
              end
            end
          }) or nil
        )
      },
    })
  }
end

--@param config {
  -- @optional animate: boolean = false
  -- @optional condition: CONDITION = CONDITION.INACTIVE
  -- @optional delay: number = function_gradual_based_on_dist
  -- @optional direction: DIRECTION = DIRECTION.IN_OUT
  -- @optional duration: number = function_gradual_based_on_dist
  -- @optional ease: EASE = EASE.LINEAR
  -- @optional ncmode: 'windows'|'buffers' = 'windows'
--}
M.Ripple = function(config)
  config = TYPE.shallow_copy(config)
  config.direction = config.direction or DIRECTION.IN_OUT
  config.delay = config.delay or ripple_delay
  config.duration = config.duration or ripple_duration
  config.ease = config.ease or EASE.LINEAR
  config.ncmode = config.ncmode or 'windows'
  return {
    style = ripple(config),
    ncmode = config.ncmode
  }
end

return M

local M = {}

local ANIMATE = require('vimade.style.value.animate')
local CONDITION = require('vimade.style.value.condition')
local DIRECTION = require('vimade.style.value.direction')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')
local GLOBALS = require('vimade.state.globals')
local Component = require('vimade.style.component').Component
local Invert = require('vimade.style.invert').Invert
local Link = require('vimade.style.link').Link
local Fade = FADE.Fade
local Tint = TINT.Tint

local default_tint = TINT.Default().value()
local default_fade = FADE.Default().value()

local duo_tint_to = function(config)
  return function (style, state)
    local to = style.resolve(default_tint, state)
    if to then
      local pct = config.window_pct
      if not (style.win.area_owner or style.win).nc then
        pct = 0
      elseif (style.win.area_owner or style.win).bufnr == GLOBALS.current.bufnr then
        pct = config.buffer_pct
      end
      for i, color in pairs(to) do
        if color.rgb then
          if color.intensity == nil then
            color.intensity = 0
          end
          color.intensity = color.intensity * pct
        end
      end
    end
    return to
  end
end
local duo_fade_to = function(config)
  return function (style, state)
    if not (style.win.area_owner or style.win).nc and not GLOBALS.vimade_focus_active then
      return 1
    end
    local to = style.resolve(fade_default, state)
    local pct = config.window_pct
    if to and (style.win.area_owner or style.win).bufnr == GLOBALS.current.bufnr then
      pct = config.buffer_pct
    end
    return to + (1 - to) * (1 - pct)
  end
end
local duo = function (config)
  local animation = config.animate and {
    duration = config.duration,
    delay = config.delay,
    ease = config.ease,
    direction = config.direction,
  } or nil
  return {
    Component('Mark', {
      condition = CONDITION.IS_MARK,
      style = {
        Link({
          condition = CONDITION.ALL,
          value = {{from='NormalFloat', to='Normal'}, {from='NormalNC', to='Normal'}}
        }),
        Tint({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Tint(TYPE.extend({}, animation, {
            to = duo_tint_to(config),
          })) or duo_tint_to(config)
        }),
        Invert({
          condition = CONDITION.ALL,
          value = 0.02,
        })
      }
    }),
    Component('Focus', {
      condition = CONDITION.IS_FOCUS,
      style = {
        Link({
          condition = CONDITION.ALL,
          value = {{from='NormalFloat', to='Normal'}, {from='NormalNC', to='Normal'}}
        }),
        Tint({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Tint(TYPE.extend({}, animation, {
            to = duo_tint_to(config),
            direction = DIRECTION.OUT,
            start = function(style, state)
              return style.win.area_owner.style_state.custom['pane-tint'].start
                 or nil
            end
          })) or duo_tint_to(config)
        }),
        Fade({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Number(TYPE.extend({}, animation, {
            to = duo_fade_to(config),
            direction = DIRECTION.OUT,
            start = function(style, state)
              return style.win.area_owner.style_state.custom['pane-fade'].value
                 or 1
            end
          })) or duo_fade_to(config)
        }),
      }
    }),
    Component('Pane', {
      condition = CONDITION.IS_PANE,
      style = {
        TINT.Tint({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Tint(TYPE.extend({}, animation, {
            id = 'pane-tint',
            to = duo_tint_to(config),
            start = function(style, state)
              return state.start or nil
            end
          })) or duo_tint_to(config)
        }),
        FADE.Fade({
          condition = CONDITION.INACTIVE_OR_FOCUS,
          value = animation and ANIMATE.Number(TYPE.extend({}, animation, {
            id = 'pane-fade',
            to = duo_fade_to(config),
            start = function(style, state)
              return
                (GLOBALS.vimade_focus_active and duo_fade_to(config)(style,state))
                or state.start
                or 1
            end
          })) or duo_fade_to(config),
        })
      }
    }),
  }
end

--@param config {
  -- @optional buffer_pct: number[0-1] = 0.382
  -- @optional window_pct: number[0-1] = 1
  -- @optional animate: boolean = false
  -- @optional condition: CONDITION = CONDITION.INACTIVE
  -- @optional delay: number = ANIMATE.DEFAULT_DELAY
  -- @optional direction: DIRECTION = DIRECTION.IN_OUT
  -- @optional duration: number = ANIMATE.DEFAULT_DURATION
  -- @optional ease: EASE = ANIMATE.DEFAULT_EASE
  -- @optional ncmode: 'windows'|'buffers' = 'windows'
--}
M.Duo = function(config)
  config = TYPE.shallow_copy(config)
  config.ncmode = config.ncmode or 'windows'
  config.buffer_pct = config.buffer_pct or 0.382
  config.window_pct = config.window_pct or 1
  config.direction = config.direction or DIRECTION.IN_OUT
  return {
    style = duo(config),
    ncmode = config.ncmode
  }
end

return M

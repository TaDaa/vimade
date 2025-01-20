local M = {}

local ANIMATE = require('vimade.style.value.animate')
local CONDITION = require('vimade.style.value.condition')
local DIRECTION = require('vimade.style.value.direction')
local GLOBALS
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')
local Component = require('vimade.style.component').Component
local Invert = require('vimade.style.invert').Invert
local Link = require('vimade.style.link').Link
local Fade = FADE.Fade
local Tint = TINT.Tint

M.__init = function(args)
  GLOBALS = args.GLOBALS
end


local default_fade = FADE.Default().value()
local default_tint = TINT.Default().value()

local default = function (config)
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
            to = default_tint,
          })) or default_tint
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
            to = default_tint,
          })) or default_tint
        }),
        Fade({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Number(TYPE.extend({}, animation, {
            to = default_fade,
            start = 1,
          })) or default_fade
        })
      }
    }),
    Component('Pane', {
      condition = CONDITION.IS_PANE,
      style = {
        Tint({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Tint(TYPE.extend({}, animation, {
            to = default_tint,
          })) or default_tint
        }),
        Fade({
          condition = CONDITION.INACTIVE_OR_FOCUS,
          value = animation and ANIMATE.Number(TYPE.extend({}, animation, {
            to = default_fade,
            start = function (style, state)
              if GLOBALS.vimade_focus_active then
                return default_fade(style, state)
              else
                return 1
              end
            end,
          })) or default_fade
        })
      }
    })
  }
end

--@param config {
  -- @optional condition: CONDITION = CONDITION.INACTIVE
  -- @optional animate: boolean = false
  -- @optional ease: EASE = ANIMATE.DEFAULT_EASE
  -- @optional delay: number = ANIMATE.DEFAULT_DELAY
  -- @optional duration: number = ANIMATE.DEFAULT_DURATION
  -- @optional direction: DIRECTION = ANIMATE.DEFAULT_DIRECTION
--}
M.Default = function(config)
  config = TYPE.shallow_copy(config)
  return {
    style = default(config)
  }
end

return M

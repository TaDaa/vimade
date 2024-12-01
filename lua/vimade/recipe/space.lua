local M = {}

local ANIMATE = require('vimade.style.value.animate')
local CONDITION = require('vimade.style.value.condition')
local DIRECTION = require('vimade.style.value.direction')
local EASE = require('vimade.style.value.ease')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')

local animate_space = function (config)
  local animation = {
    duration = config.duration,
    delay = config.delay,
    ease = config.ease,
    direction = config.direction,
  }
  return {
    TINT.Tint({
      condition = CONDITION.INACTIVE,
      value = ANIMATE.Tint(TYPE.extend({}, animation, {
        direction = DIRECTION.OUT,
        start = {
          fg = {
            rgb = {192,0,255},
            intensity = 0.7
          },
          bg = {
            rgb = {10,0,40},
            intensity = 1
          },
        },
        to = {
          fg = {
            rgb = {192,0,255},
            intensity = 0.35
          },
          bg = {
            rgb = {0,0,0},
            intensity = 1
          },
        },
      }))
    }),
    TINT.Tint({
      condition = CONDITION.ACTIVE,
      value = ANIMATE.Tint(TYPE.extend({}, animation, {
        direction = DIRECTION.IN,
        start = {
          fg = {
            rgb = {192,0,255},
            intensity = 0.35
          },
          bg = {
            rgb = {0,0,0},
            intensity = 1
          },
        },
        to = {
          fg = {
            rgb = {0,0,0},
            intensity = 0
          },
          bg = {
            rgb = {10,0,10},
            intensity = 1,
          },
        },
      }))
    }),
    FADE.Fade({
      condition = CONDITION.INACTIVE,
      direction = DIRECTION.OUT,
      value = ANIMATE.Number(TYPE.extend({}, animation, {
        to = FADE.Default().value(),
        start = 1,
      }))
    })
  }
end

local space = function()
  return {
    TINT.Tint({
      condition = CONDITION.INACTIVE,
      value = {
        fg = {
          rgb = {192,0,255},
          intensity = 0.35
        },
        bg = {
          rgb = {10,0,10},
          intensity = 1
        },
      },
    }),
    TINT.Tint({
      condition = CONDITION.ACTIVE,
      value = {
        bg = {
          rgb = {10,0,10},
          intensity = 1
        },
      },
    }),
    FADE.Fade({
      condition = CONDITION.INACTIVE,
      value = FADE.Default().value()
    })
  }
end

--@param config {
  -- @optional animate: boolean = false
  -- @optional ease: EASE = ANIMATE.DEFAULT_EASE
  -- @optional delay: number = ANIMATE.DEFAULT_DELAY
  -- @optional duration: number = 1500
--}
M.Space = function(config)
  config = TYPE.shallow_copy(config)
  config.duration = config.duration or 1000
  return {
    style = config.animate and animate_space(config) or space(config)
  }
end

return M

local M = {}
local ANIMATE = require('vimade.style.value.animate')
local CONDITION = require('vimade.style.value.condition')
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
        id = 'recipe-space-tint',
        from = {
          fg = {
            rgb = {235,0,217},
            intensity = 0.7
          },
          bg = {
            rgb = {30,0,30},
            intensity = 1
          },
        },
        to = {
          fg = {
            rgb = {235,0,217},
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
        id = 'recipe-space-tint',
        from = {
          fg = {
            rgb = {235,0,217},
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
      value = ANIMATE.Number(TYPE.extend({}, animation, {
        to = FADE.Default().value(),
        from = 1,
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
          rgb = {235,0,217},
          intensity = 0.35
        },
        bg = {
          rgb = {0,0,0},
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

M.Space = function(config)
  config = TYPE.shallow_copy(config)
  config.duration = config.duration or 1500
  -- sorry no overrides allowed
  config.direction = ANIMATE.DIRECTION.OUT
  return {
    style = config.animate and animate_space(config) or space(config)
  }
end

return M

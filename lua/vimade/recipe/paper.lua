local M = {}
local ANIMATE = require('vimade.style.value.animate')
local CONDITION = require('vimade.style.value.condition')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')

local animate_paper = function (config)
  local condition
  if config.direction ~= ANIMATE.DIRECTION.INOUT then
    condition = CONDITION.INACTIVE
  end
  local animation = {
    duration = config.duration,
    delay = config.delay,
    ease = config.ease,
    direction = config.direction,
  }
  return {
    TINT.Tint({
      condition = condition,
      value = ANIMATE.Tint(TYPE.extend({}, animation, {
        to = {
          fg = {
            rgb = {0,0,0},
            intensity = 1
          },
          bg = {
            rgb = {255,255,255},
            intensity = 1
          },
        },
      }))
    }),
    FADE.Fade({
      condition = condition,
      value = ANIMATE.Number(TYPE.extend({}, animation, {
        to = FADE.Default().value(),
        from = 1,
      }))
    })
  }
end

local paper = function()
  return {
    TINT.Tint({
      condition = CONDITION.INACTIVE,
      value = {
        fg = {
          rgb = {0,0,0},
          intensity = 0.35
        },
        bg = {
          rgb = {255,255,255},
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

M.Paper = function(config)
  config = TYPE.shallow_copy(config)
  return {
    style = config.animate and animate_paper(config) or paper(config)
  }
end

return M

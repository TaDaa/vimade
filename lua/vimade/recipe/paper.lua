local M = {}

local ANIMATE = require('vimade.style.value.animate')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')

local animate_paper = function (config)
  local animation = {
    duration = config.duration,
    delay = config.delay,
    ease = config.ease,
    direction = config.direction,
  }
  return {
    TINT.Tint({
      condition = config.condition,
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
      condition = config.condition,
      value = ANIMATE.Number(TYPE.extend({}, animation, {
        to = FADE.Default().value(),
        start = 1,
      }))
    })
  }
end

local paper = function(config)
  return {
    TINT.Tint({
      condition = config.condition,
      value = {
        fg = {
          rgb = {0,0,0},
          intensity = 1
        },
        bg = {
          rgb = {255,255,255},
          intensity = 1
        },
      },
    }),
    FADE.Fade({
      condition = config.condition,
      value = FADE.Default().value()
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
M.Paper = function(config)
  config = TYPE.shallow_copy(config)
  return {
    style = config.animate and animate_paper(config) or paper(config)
  }
end

return M

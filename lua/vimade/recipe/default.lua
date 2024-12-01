local M = {}

local ANIMATE = require('vimade.style.value.animate')
local CONDITION = require('vimade.style.value.condition')
local DIRECTION = require('vimade.style.value.direction')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')

local animate_default = function (config)
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
        to = TINT.Default().value(),
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

local default = function(config)
  return {
    TINT.Default(config),
    FADE.Default(config)
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
    style = config.animate and animate_default(config) or default(config)
  }
end

return M

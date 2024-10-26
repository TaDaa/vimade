local M = {}
local ANIMATE = require('vimade.style.value.animate')
local CONDITION = require('vimade.style.value.condition')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')

local animate_default = function (config)
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
        to = TINT.Default().value(),
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

local default = function()
  return {
    TINT.Default(),
    FADE.Default()
  }
end

--@param config {
  -- @optional fadein = boolean
  -- @optional animate = boolean
  -- @optional ease = EASE
  -- @optional delay = number milliseconds
  -- @optional duration = number milliseconds
  -- @optional direction = DIRECTION
--}
M.Default = function(config)
  config = TYPE.shallow_copy(config)
  return {
    style = config.animate and animate_default(config) or default(config)
  }
end

return M

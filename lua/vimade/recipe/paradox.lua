local M = {}

local ANIMATE = require('vimade.style.value.animate')
local CONDITION = require('vimade.style.value.condition')
local DIRECTION = require('vimade.style.value.direction')
local FADE = require('vimade.style.fade')
local INVERT = require('vimade.style.invert')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')

local animate_paradox = function (config)
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
    }),
    INVERT.Invert({
      condition = function(style)
        if config.invert.active and (not style.win.terminal and not style.win.nc) then
          return true
        elseif not config.invert.active and style.win.nc then
          return true
        end
        return false
      end,
      value = ANIMATE.Invert(TYPE.extend({}, animation, {
        to = config.invert.to,
        start = config.invert.start,
        duration = config.invert.duration,
        direction = config.invert.direction,
      }))
    }),
  }
end

local paradox = function(config)
  return {
    TINT.Default(config),
    FADE.Default(config),
    INVERT.Invert({
      condition = function(style)
        if config.invert.active and (not style.win.terminal or not style.win.nc) then
          return true
        elseif not config.invert.active and style.win.nc then
          return true
        end
        return false
      end,
      value = config.invert.to,
    }),
  }
end

--@param config {
  -- @optional invert = {
    --  @otional start = 0.15
    --  @otional to = 0.1
    --  @otional direction = DIRECTION.IN
    --  @otional duration = 1000
    --  @optional active = true (inverts the active window)
    -- }
  -- @optional condition: CONDITION = CONDITION.INACTIVE
  -- @optional animate: boolean = false
  -- @optional ease: EASE = ANIMATE.DEFAULT_EASE
  -- @optional delay: number = ANIMATE.DEFAULT_DELAY
  -- @optional duration: number = ANIMATE.DEFAULT_DURATION
  -- @optional direction: DIRECTION = ANIMATE.DEFAULT_DIRECTION
--}
M.Paradox = function(config)
  config = TYPE.shallow_copy(config)
  config.invert = config.invert or {}
  config.invert.start = config.invert.start or 0.15
  config.invert.to = config.invert.to or 0.1
  config.invert.direction = config.invert.direction or DIRECTION.IN
  config.invert.duration = config.invert.duration or 1000
  config.invert.active = config.invert.active or true
  return {
    style = config.animate and animate_paradox(config) or paradox(config),
    ncmode = 'windows',
  }
end

return M

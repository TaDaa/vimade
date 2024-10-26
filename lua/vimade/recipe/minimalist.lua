local M = {}
local Include = require('vimade.style.include').Include
local Exclude = require('vimade.style.exclude').Exclude
local ANIMATE = require('vimade.style.value.animate')
local CONDITION = require('vimade.style.value.condition')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')

local EXCLUDE_NAMES = {'LineNr', 'LineNrBelow', 'LineNrAbove', 'WinSeparator', 'EndOfBuffer'}
local NO_VISIBILITY_NAMES = {'LineNr', 'LineNrBelow', 'LineNrAbove', 'EndOfBuffer'}
local LOW_VISIBILITY_NAMES = {'WinSeparator'}

local animate_minimalist = function (config)
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
  local result = {
    TINT.Tint({
      condition = condition,
      value = ANIMATE.Tint(TYPE.extend({}, animation, {
        to = TINT.Default().value()
      }))
    }),
    Exclude({
      condition = condition,
      names = config.exclude_names,
      style = {
        FADE.Fade({
          value = ANIMATE.Number(TYPE.extend({}, animation, {
            to = FADE.Default().value(),
            from = 1,
          })),
        })
      }
    }),
    Include({
      condition = condition,
      names = config.no_visibility_names,
      style = {
        FADE.Fade({
          value = ANIMATE.Number(TYPE.extend({}, animation, {
            to = 0,
            from = 1,
          })),
        })
      }
    }),
    Include({
      condition = condition,
      names = config.low_visibility_names,
      style = {
        FADE.Fade({
          value = ANIMATE.Number(TYPE.extend({}, animation, {
              to = config.low_visibility_fadelevel,
            from = 1,
          })),
        })
      }
    }),
  }
  return result
end

local minimalist = function (config)
  return {
    Exclude({
      condition = CONDITION.INACTIVE,
      names = config.exclude_names,
      style = {TINT.Default(), FADE.Default()}
    }),
    Include({
      condition = CONDITION.INACTIVE,
      names = config.no_visibility_names,
      style = {TINT.Default(), FADE.Fade({value = 0})}
    }),
    Include({
      condition = CONDITION.INACTIVE,
      names = config.low_visibility_names,
      style = {TINT.Default(), FADE.Fade({value = config.low_visibility_fadelevel})}
    }),
  }
end

--@param config {
  -- @optional exclude_names = {string...}
  -- @optional no_visibility_names = {string...}
  -- @optional low_visibility_names = {string...}
  -- @optional low_visibility_fadelevel = number
  -- @optional animate = boolean
  -- @optional ease = EASE
  -- @optional delay = number milliseconds
  -- @optional duration = number milliseconds
  -- @optional direction = DIRECTION
--}
M.Minimalist = function(config)
  config = TYPE.shallow_copy(config)
  config.animate = config.animate or false
  config.direction = config.direction or ANIMATE.DIRECTION.OUT
  config.exclude_names = config.exclude_names or EXCLUDE_NAMES
  config.no_visibility_names = config.no_visibility_names or NO_VISIBILITY_NAMES
  config.low_visibility_names = config.low_visibility_names or LOW_VISIBILITY_NAMES
  config.low_visibility_fadelevel = config.low_visibility_fadelevel or 0.1

  return {
    style = config.animate and animate_minimalist(config) or minimalist(config)
  }
end

return M

local M = {}

local Include = require('vimade.style.include').Include
local Exclude = require('vimade.style.exclude').Exclude
local Link = require('vimade.style.link').Link
local ANIMATE = require('vimade.style.value.animate')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')

local EXCLUDE_NAMES = {'LineNr', 'LineNrBelow', 'LineNrAbove', 'WinSeparator', 'EndOfBuffer'}
local NO_VISIBILITY_NAMES = {'LineNr', 'LineNrBelow', 'LineNrAbove', 'EndOfBuffer'}
local LOW_VISIBILITY_NAMES = {'WinSeparator'}

local create_unlink = function(names)
  local result = {}
  for _, name in ipairs(names) do
    table.insert(result, {
      from = name,
      to = nil
    })
  end
  return result
end

local animate_minimalist = function (config)
  local animation = {
    duration = config.duration,
    delay = config.delay,
    ease = config.ease,
    direction = config.direction,
  }
  local result = {
    -- unlinks the targetted highlights ahead of time, this ensures that all styles apply on our selected names.
    Link({
      condition = config.condition,
      value = create_unlink(config.exclude_names),
    }),
    TINT.Tint({
      condition = config.condition,
      value = ANIMATE.Tint(TYPE.extend({}, animation, {
        to = TINT.Default().value()
      }))
    }),
    Exclude({
      condition = config.condition,
      value = config.exclude_names,
      style = {
        FADE.Fade({
          value = ANIMATE.Number(TYPE.extend({}, animation, {
            to = FADE.Default().value(),
            start = 1,
          })),
        })
      }
    }),
    Include({
      condition = config.condition,
      value = config.no_visibility_names,
      style = {
        FADE.Fade({
          value = ANIMATE.Number(TYPE.extend({}, animation, {
            to = 0,
            start = 1,
          })),
        })
      }
    }),
    Include({
      condition = config.condition,
      value = config.low_visibility_names,
      style = {
        FADE.Fade({
          value = ANIMATE.Number(TYPE.extend({}, animation, {
            to = config.low_visibility_fadelevel,
            start = 1,
          })),
        })
      }
    })
  }
  return result
end

local minimalist = function (config)
  return {
    -- unlinks the targetted highlights ahead of time, this ensures that all styles apply on our selected names.
    Link({
      condition = config.condition,
      value = create_unlink(config.exclude_names),
    }),
    TINT.Default(config),
    Exclude({
      condition = config.condition,
      value = config.exclude_names,
      style = {FADE.Default()}
    }),
    Include({
      condition = config.condition,
      value = config.no_visibility_names,
      style = {FADE.Fade({value = 0})}
    }),
    Include({
      condition = config.condition,
      value = config.low_visibility_names,
      style = {FADE.Fade({value = config.low_visibility_fadelevel})}
    })
  }
end

--@param config {
  -- @optional condition: CONDITION = CONDITION.INACTIVE
  -- @optional exclude_names: {string...} = {'LineNr', 'LineNrBelow', 'LineNrAbove', 'WinSeparator', 'EndOfBuffer'}
  -- @optional no_visibility_names: {string...} = {'LineNr', 'LineNrBelow', 'LineNrAbove', 'EndOfBuffer'}
  -- @optional low_visibility_names: {string...} = {'WinSeparator'}
  -- @optional low_visibility_fadelevel: number = 0.1
  -- @optional animate: boolean = false
  -- @optional ease: EASE = ANIMATE.DEFAULT_EASE
  -- @optional delay: number = ANIMATE.DEFAULT_DELAY
  -- @optional duration: number = ANIMATE.DEFAULT_DURATION
  -- @optional direction: DIRECTION = ANIMATE.DEFAULT_DIRECTION
--}
M.Minimalist = function(config)
  config = TYPE.shallow_copy(config)
  config.exclude_names = config.exclude_names or EXCLUDE_NAMES
  config.no_visibility_names = config.no_visibility_names or NO_VISIBILITY_NAMES
  config.low_visibility_names = config.low_visibility_names or LOW_VISIBILITY_NAMES
  config.low_visibility_fadelevel = config.low_visibility_fadelevel or 0.1

  return {
    style = config.animate and animate_minimalist(config) or minimalist(config)
  }
end

return M

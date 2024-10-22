local M = {}
local Animate = require('vimade.style.animate').Animate
local Include = require('vimade.style.include').Include
local Exclude = require('vimade.style.exclude').Exclude
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')

local EXCLUDE_NAMES = {'LineNr', 'LineNrBelow', 'LineNrAbove', 'WinSeparator', 'EndOfBuffer'}
local NO_VISIBILITY_NAMES = {'LineNr', 'LineNrBelow', 'LineNrAbove', 'EndOfBuffer'}
local LOW_VISIBILITY_NAMES = {'WinSeparator'}

local animate_minimalist = function (config)
  return {
    style = {
      Exclude({
        names = config.exclude_names,
        style = {
          TINT.DEFAULT,
          Animate({
            style = FADE.DEFAULT,
            from = 1,
            ease = config.ease,
            delay = config.delay,
            duration = config.duration
          })
        }
      }),
      Include({
        names = config.no_visibility_names,
        style = {
          TINT.DEFAULT,
          Animate({
            style = FADE.Fade(0),
            from = 1,
            ease = config.ease,
            delay = config.delay,
            duration = config.duration,
          })
        }
      }),
      Include({
        names = config.low_visibility_names,
        style = {
          TINT.DEFAULT,
          Animate({
            style = FADE.Fade(config.low_visibility_fadelevel),
            from = 1,
            ease = config.ease,
            delay = config.delay,
            duration = config.duration,
          })
        }
      }),
    }
  }
end

local minimalist = function (config)
  return {
    style = {
      Exclude({
        names = config.exclude_names,
        style = {TINT.DEFAULT, FADE.DEFAULT}
      }),
      Include({
        names = config.no_visibility_names,
        style = {TINT.DEFAULT, FADE.Fade(0)}
      }),
      Include({
        names = config.low_visibility_names,
        style = {TINT.DEFAULT, FADE.Fade(config.low_visibility_fadelevel)}
      }),
    }
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
--}
M.Minimalist = function(config)
  local next = TYPE.shallow_copy(config)
  next.animate = next.animate or false
  next.exclude_names = next.exclude_names or EXCLUDE_NAMES
  next.no_visibility_names = next.no_visibility_names or NO_VISIBILITY_NAMES
  next.low_visibility_names = next.low_visibility_names or LOW_VISIBILITY_NAMES
  next.low_visibility_fadelevel = next.low_visibility_fadelevel or 0.1

  if config.animate then
    return animate_minimalist(next)
  else
    return minimalist(next)
  end
end

return M

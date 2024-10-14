local M = {}
local vimade = require('vimade')
local Animate = require('vimade.style.animate').Animate
local Include = require('vimade.style.include').Include
local Exclude = require('vimade.style.exclude').Exclude
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')

local EXCLUDE_NAMES = {'LineNr', 'LineNrBelow', 'LineNrAbove', 'WinSeparator', 'EndOfBuffer'}
local NO_VISIBILITY_NAMES = {'LineNr', 'LineNrBelow', 'LineNrAbove', 'EndOfBuffer'}
local LOW_VISIBILITY_NAMES = {'WinSeparator'}

local animated_minimalist = function ()
  return {
    style = {
      Exclude({
        names = EXCLUDE_NAMES,
        style = {
          TINT.DEFAULT,
          Animate({
            style = FADE.DEFAULT,
            from =1
          })
        }
      }),
      Include({
        names = NO_VISIBILITY_NAMES,
        style = {
          TINT.DEFAULT,
          Animate({
            style = FADE.Fade(0),
            from = 1
          })
        }
      }),
      Include({
        names = LOW_VISIBILITY_NAMES,
        style = {
          TINT.DEFAULT,
          Animate({
            style = FADE.Fade(0.1),
            from = 1
          })
        }
      }),
    }
  }
end

local minimalist = function ()
  return {
    style = {
      Exclude({
        names = EXCLUDE_NAMES,
        style = {TINT.DEFAULT, FADE.DEFAULT}
      }),
      Include({
        names = NO_VISIBILITY_NAMES,
        style = {TINT.DEFAULT, FADE.Fade(0)}
      }),
      Include({
        names = LOW_VISIBILITY_NAMES,
        style = {TINT.DEFAULT, FADE.Fade(0.1)}
      }),
    }
  }
end

--@param config {
  --animated = boolean
--}
M.Minimalist = function(config)
  config = config or {animated = false}
  if config.animated then
    return animated_minimalist()
  else
    return minimalist()
  end
end

return M

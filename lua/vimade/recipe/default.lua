local M = {}
local Animate = require('vimade.style.animate').Animate
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')

local animate_default = function (config)
  return {
    style = {
      TINT.DEFAULT,
      Animate({
        style = FADE.DEFAULT,
        from = 1,
        ease = config.ease,
        delay = config.delay,
        duration = config.duration,
      })
    }
  }
end

local default = function()
  return {
    style = {
      TINT.DEFAULT, FADE.DEFAULT
    }
  }
end

M.Default = function(config)
  config = TYPE.shallow_copy(config)
  if config.animate then
    return animate_default(config)
  else
    return default(config)
  end
end

return M

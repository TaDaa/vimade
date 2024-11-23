local M = {}
local Include = require('vimade.style.include').Include
local Exclude = require('vimade.style.exclude').Exclude
local ANIMATE = require('vimade.style.value.animate')
local DIRECTION = require('vimade.style.value.direction')
local EASE = require('vimade.style.value.ease')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')
local GLOBALS = require('vimade.state.globals')

local duo_to_tint = function (style, state)
  local to = TINT.Default().value()(style, state)
  if to and style.win.tabnr == GLOBALS.current.tabnr and style.win.bufnr == GLOBALS.current.bufnr then
    for i, color in pairs(to) do
      if color.rgb then
        if color.intensity == nil then
          color.intensity = 1
        end
        color.intensity = color.intensity * 0.5
      end
    end
  end
  return to
end
local duo_to_fade = function (style, state)
  local to = FADE.Default().value()(style, state)
  if to and style.win.tabnr == GLOBALS.current.tabnr and style.win.bufnr == GLOBALS.current.bufnr then
    return (1+to) * 0.5
  end
  return to
end
local animate_duo = function (config)
  local result = {
    TINT.Tint({
      condition = config.condition,
      value = ANIMATE.Tint({
        start = function (style, state)
          local start = TINT.Default().value()(style, state)
          if start then
            for i, color in pairs(start) do
              color.intensity = 0
            end
          end
          return start
        end,
        to = duo_to_tint,
        direction = config.direction,
        duration = config.duration,
        delay = config.delay,
        ease = config.ease,
      })
    }),
    FADE.Fade({
      condition = config.condition,
      value = ANIMATE.Number({
        to = duo_to_fade,
        start = 1,
        direction = config.direction,
        duration = config.duration,
        delay = config.delay,
        ease = config.ease,
      }),
    })
  }
  return result
end

local duo = function (config)
  return {
    TINT.Tint({
      condition = config.condition,
      value = duo_to_tint,
    }),
    FADE.Fade({
      condition = config.condition,
      value = duo_to_fade,
    }),
  }
end

--@param config {
  -- @optional animate: boolean = false
  -- @optional condition: CONDITION = CONDITION.INACTIVE
  -- @optional delay: number = ANIMATE.DEFAULT_DELAY
  -- @optional direction: DIRECTION = ANIMATE.DEFAULT_DIRECTION
  -- @optional duration: number = ANIMATE.DEFAULT_DURATION
  -- @optional ease: EASE = ANIMATE.DEFAULT_EASE
--}
M.Duo = function(config)
  config = TYPE.shallow_copy(config)
  config.ncmode = config.ncmode or 'windows'
  --config.direction = config.direction or DIRECTION.IN_OUT
  return {
    style = config.animate and animate_duo(config) or duo(config),
    ncmode = config.ncmode
  }
end

return M

local M = {}

local ANIMATE = require('vimade.style.value.animate')
local DIRECTION = require('vimade.style.value.direction')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')
local GLOBALS = require('vimade.state.globals')

local duo_tint_to = function(config)
  return function (style, state)
    local to = style.resolve(TINT.Default().value(), state)
    if to and style.win.tabnr == GLOBALS.current.tabnr then
      local pct = config.window_pct
      if not style.win.nc then
        pct = 0
      elseif style.win.bufnr == GLOBALS.current.bufnr then
        pct = config.buffer_pct
      end
      for i, color in pairs(to) do
        if color.rgb then
          if color.intensity == nil then
            color.intensity = 0
          end
          color.intensity = color.intensity * pct
        end
      end
    end
    return to
  end
end
local duo_fade_to = function(config)
  return function (style, state)
    if not style.win.nc then
      return 1
    end
    local to = style.resolve(FADE.Default().value(), state)
    local pct = config.window_pct
    if to and style.win.tabnr == GLOBALS.current.tabnr and style.win.bufnr == GLOBALS.current.bufnr then
      pct = config.buffer_pct
    end
    return to + (1 - to) * (1 - pct)
  end
end
local animate_duo = function (config)
  local result = {
    TINT.Tint({
      condition = config.condition,
      value = ANIMATE.Tint({
        to = duo_tint_to(config),
        direction = config.direction,
        duration = config.duration,
        delay = config.delay,
        ease = config.ease,
      })
    }),
    FADE.Fade({
      condition = config.condition,
      value = ANIMATE.Number({
        to = duo_fade_to(config),
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
      value = duo_tint_to(config),
    }),
    FADE.Fade({
      condition = config.condition,
      value = duo_fade_to(config),
    }),
  }
end

--@param config {
  -- @optional buffer_pct: number[0-1] = 0.382
  -- @optional window_pct: number[0-1] = 1
  -- @optional animate: boolean = false
  -- @optional condition: CONDITION = CONDITION.INACTIVE
  -- @optional delay: number = ANIMATE.DEFAULT_DELAY
  -- @optional direction: DIRECTION = DIRECTION.IN_OUT
  -- @optional duration: number = ANIMATE.DEFAULT_DURATION
  -- @optional ease: EASE = ANIMATE.DEFAULT_EASE
  -- @optional ncmode: 'windows'|'buffers' = 'windows'
--}
M.Duo = function(config)
  config = TYPE.shallow_copy(config)
  config.ncmode = config.ncmode or 'windows'
  config.buffer_pct = config.buffer_pct or 0.382
  config.window_pct = config.window_pct or 1
  config.direction = config.direction or DIRECTION.IN_OUT
  return {
    style = config.animate and animate_duo(config) or duo(config),
    ncmode = config.ncmode
  }
end

return M

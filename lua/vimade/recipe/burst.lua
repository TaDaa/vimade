local M = {}

local ANIMATE = require('vimade.style.value.animate')
local GLOBALS = require('vimade.state.globals')
local CONDITION = require('vimade.style.value.condition')
local DIRECTION = require('vimade.style.value.direction')
local EASE = require('vimade.style.value.ease')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')
local Component = require('vimade.style.component').Component
local Invert = require('vimade.style.invert').Invert
local Link = require('vimade.style.link').Link
local Fade = FADE.Fade
local Tint = TINT.Tint

local default_fade = FADE.Default().value()
local active_duration = 1500
local burst_inactive_tint_start = function ()
  return {
    fg = {
      rgb = GLOBALS.is_dark and {200,98,0} or {150,74,0},
      intensity = 0.8
    },
  }
end
local burst_inactive_tint_to = function () 
  return {
    fg = {
      rgb = GLOBALS.is_dark and {255,100,0} or {175,70,0},
      intensity = 0.2
    },
  }
end
local burst_active_tint_start = function ()
  return {
    fg = {
      rgb = GLOBALS.is_dark and {255,100,0} or {175,70,0},
      intensity = 0.8
    },
    bg = {
      rgb = GLOBALS.is_dark and {200,98,0} or {150,74,0},
      intensity = GLOBALS.is_dark and 0.2 or 0.35
    },
  }
end
local burst_active_tint_to = function (style)
  return {
    fg = {
      rgb = GLOBALS.is_dark and {200,98,0} or {150,74,0},
      intensity = 0
    },
    bg = {
      rgb = GLOBALS.is_dark and {255,100,0} or {175,70,0},
      intensity = 0,
    },
  }
end

local burst = function (config)
  local animation = config.animate and {
    duration = config.duration,
    delay = config.delay,
    ease = config.ease,
    direction = config.direction,
  } or nil

  return {
    Component('Mark', {
      condition = CONDITION.IS_MARK,
      style = {
        Link({
          condition = CONDITION.ALL,
          value = {{from='NormalFloat', to='Normal'}, {from='NormalNC', to='Normal'}}
        }),
        Tint({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Tint(TYPE.extend({}, animation, {
            duration = config.burst.inactive.duration,
            to = config.burst.inactive.tint_to,
          })) or config.burst.inactive.tint_to,
        }),
        Tint({
          condition = CONDITION.ACTIVE,
          value = animation and ANIMATE.Tint(TYPE.extend({}, animation, {
            direction = DIRECTION.IN,
            duration = config.burst.active.duration,
            start = config.burst.active.tint_start,
            to = config.burst.active.tint_to,
          })) or config.burst.active.tint_to,
        }),
        Invert({
          condition = CONDITION.ALL,
          value = 0.02,
        })
      }
    }),
    Component('Focus', {
      condition = CONDITION.IS_FOCUS,
      style = {
        Link({
          condition = CONDITION.ALL,
          value = {{from='NormalFloat', to='Normal'}, {from='NormalNC', to='Normal'}}
        }),
        Tint({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Tint(TYPE.extend({}, animation, {
            duration = config.burst.inactive.duration,
            to = config.burst.inactive.tint_to,
          })) or config.burst.inactive.tint_to
        }),
        Tint({
          condition = CONDITION.ACTIVE,
          value = animation and ANIMATE.Tint(TYPE.extend({}, animation, {
            direction = DIRECTION.IN,
            duration = config.burst.active.duration,
            start = config.burst.active.tint_start,
            to = config.burst.active.tint_to,
          })) or config.burst.active.tint_to
        }),
        Fade({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Number(TYPE.extend({}, animation, {
            duration = config.burst.inactive.duration,
            to = default_fade,
            start = 1,
          })) or default_fade
        })
      }
    }),
    Component('Pane', {
      condition = CONDITION.IS_PANE,
      style = {
        TINT.Tint({
          condition = CONDITION.INACTIVE_OR_FOCUS,
          value = ANIMATE.Tint(TYPE.extend({}, animation, {
            duration = config.burst.inactive.duration,
            start = function (style, state)
              if GLOBALS.vimade_focus_active then
                return config.burst.inactive.tint_to 
              else
                return style.resolve(config.burst.inactive.tint_start)
              end
            end,
            to = config.burst.inactive.tint_to,
          }))
        }),
        TINT.Tint({
          condition = CONDITION.ACTIVE,
          value = ANIMATE.Tint(TYPE.extend({}, animation, {
            direction = DIRECTION.IN,
            duration = config.burst.active.duration,
            start = config.burst.active.tint_start,
            to = config.burst.active.tint_to,
          }))
        }),
        FADE.Fade({
          condition = CONDITION.INACTIVE_OR_FOCUS,
          value = ANIMATE.Number(TYPE.extend({}, animation, {
            duration = config.burst.inactive.duration,
            to = default_fade,
            start = function (style, state)
              if GLOBALS.vimade_focus_active then
                return default_fade(style, state)
              else
                return 1
              end
            end,
          }))
        })
      }
    })
  }
end

--@param config {
  -- @optional animate: boolean = false
  -- @optional ease: EASE = ANIMATE.DEFAULT_EASE
  -- @optional delay: number = ANIMATE.DEFAULT_DELAY
  -- @optional duration: number = 1500
  -- @optional burst: {
    -- @optional inactive: {
      -- @optional duration: number = 1000
      -- @optional fade_start: number = 1 
      -- @optional tint_start: TINT = function ()
      --   return {
      --     fg = {
      --       rgb = GLOBALS.is_dark and {200,98,0} or {150,74,0},
      --       intensity = 0.8
      --     },
      --   }
      -- end
      -- @optional tint_to: TINT = function () 
      --   return {
      --     fg = {
      --       rgb = GLOBALS.is_dark and {255,100,0} or {175,70,0},
      --       intensity = 0.2
      --     },
      --   }
      -- end
    -- @optional active: {
      -- @optional duration: number = 2000
      -- @optional tint_start: TINT = function ()
        --   return {
        --     fg = {
        --       rgb = GLOBALS.is_dark and {255,100,0} or {175,70,0},
        --       intensity = 0.8
        --     },
        --     bg = {
        --       rgb = GLOBALS.is_dark and {200,98,0} or {150,74,0},
        --       intensity = GLOBALS.is_dark and 0.2 or 0.35
        --     },
        --   }
        -- end
      -- @optional tint_to: TINT = function (style)
      --   return {
      --     fg = {
      --       rgb = GLOBALS.is_dark and {200,98,0} or {150,74,0},
      --       intensity = 0
      --     },
      --     bg = {
      --       rgb = GLOBALS.is_dark and {255,100,0} or {175,70,0},
      --       intensity = 0,
      --     },
      --   }
      -- end
    -- }
  -- }
--}
M.Burst = function(config)
  config = TYPE.shallow_copy(config)
  config.duration = config.duration or 1000
  config.burst = config.burst or {}
  config.burst.inactive = config.burst.inactive or {}
  config.burst.inactive.duration = config.burst.inactive.duration or config.duration
  config.burst.inactive.fade_start = config.burst.inactive.fade_start or 1
  config.burst.inactive.tint_start = config.burst.inactive.tint_start or burst_inactive_tint_start
  config.burst.inactive.tint_to = config.burst.inactive.tint_to or burst_inactive_tint_to
  config.burst.active = config.burst.active or {}
  config.burst.active.duration = config.burst.active.duration or active_duration
  config.burst.active.tint_start = config.burst.active.tint_start or burst_active_tint_start
  config.burst.active.tint_to = config.burst.active.tint_to or burst_active_tint_to
  return {
    style = burst(config)
  }
end

return M

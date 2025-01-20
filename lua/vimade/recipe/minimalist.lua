
local M = {}

local ANIMATE = require('vimade.style.value.animate')
local CONDITION = require('vimade.style.value.condition')
local DIRECTION = require('vimade.style.value.direction')
local GLOBALS = require('vimade.state.globals')
local FADE = require('vimade.style.fade')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')
local Include = require('vimade.style.include').Include
local Invert = require('vimade.style.invert').Invert
local Exclude = require('vimade.style.exclude').Exclude
local Component = require('vimade.style.component').Component
local Link = require('vimade.style.link').Link
local Fade = FADE.Fade
local Tint = TINT.Tint

local EXCLUDE_NAMES = {'LineNr', 'LineNrBelow', 'LineNrAbove', 'WinSeparator', 'EndOfBuffer'}
local NO_VISIBILITY_NAMES = {'LineNr', 'LineNrBelow', 'LineNrAbove', 'EndOfBuffer'}
local LOW_VISIBILITY_NAMES = {'WinSeparator'}

local default_fade = FADE.Default().value()
local default_tint = TINT.Default().value()

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

local get_fade_style = function(config, animation)
  config.default.start = config.default.start or 1
  config.default.to = config.default.to or default_fade
  config.low_visibility.start = config.low_visibility.start or 1
  config.low_visibility.to = config.low_visibility.to or 0.1
  config.no_visibility.start = config.no_visibility.start or 1
  config.no_visibility.to = config.no_visibility.to or 0
  return {
    Exclude({
      condition = config.condition,
      value = config.default.names,
      style = {
        Fade({
          condition = config.condition,
          value = animation and ANIMATE.Number(TYPE.extend({}, animation, {
            id = 'fade',
            reset = config.reset,
            direction = config.direction,
            to = config.default.to,
            start = config.default.start
          })) or config.default.to,
        })
      }
    }),
    Include({
      condition = config.condition,
      value = config.no_visibility.names,
      style = {
        Fade({
          condition = config.condition,
          value = animation and ANIMATE.Number(TYPE.extend({}, animation, {
            id = 'no-vis-fade',
            reset = config.reset,
            direction = config.direction,
            to = config.no_visibility.to,
            start = config.no_visibility.start,
          })) or config.no_visibility.to,
        })
      }
    }),
    Include({
      condition = config.condition,
      value = config.low_visibility.names,
      style = {
        Fade({
          value = animation and ANIMATE.Number(TYPE.extend({}, animation, {
            id = 'low-vis-fade',
            reset = config.reset,
            direction = config.direction,
            to = config.low_visibility.to,
            start = config.low_visibility.start,
          })) or config.low_visibility.to,
        })
      }
    })
  }
end

local minimalist = function (config)
  local animation = config.animate and {
    duration = config.duration,
    delay = config.delay,
    ease = config.ease,
    direction = config.direction,
  } or nil
  local result = {
    Component('Mark', {
      condition = CONDITION.IS_MARK,
      style = TYPE.style_concat({
        Link({
          condition = CONDITION.ALL,
          value = {{from='NormalFloat', to='Normal'}, {from='NormalNC', to='Normal'}}
        }),
        Link({
          condition = CONDITION.INACTIVE,
          value = create_unlink(config.exclude_names),
        }),
        TINT.Tint({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Tint(TYPE.extend({}, animation, {
            to = default_tint
          })) or default_tint
        })
      }, get_fade_style({
          condition = CONDITION.INACTIVE,
          default = {names = config.exclude_names, to = 1},
          low_visibility = {names = config.low_visibility_names, to = 1},
          no_visibility = {names = config.no_visibility_names, to = 0}
      }, animation), {
        Invert({
          condition = CONDITION.ALL,
          value = 0.02
        })
      })
    }),
    Component('Focus', {
      condition = CONDITION.IS_FOCUS,
      style = TYPE.style_concat({
        Link({
          condition = CONDITION.ALL,
          value = {{from='NormalFloat', to='Normal'}, {from='NormalNC', to='Normal'}}
        }),
        Link({
          condition = CONDITION.INACTIVE,
          value = create_unlink(config.exclude_names),
        }),
        TINT.Tint({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Tint(TYPE.extend({}, animation, {
            to = default_tint
          })) or default_tint
        })
      }, get_fade_style(TYPE.extend({}, config, {
        condition = CONDITION.INACTIVE,
        default = {names = config.exclude_names, to = default_fade},
        low_visibility = {names = config.low_visibility_names, to = config.low_visibility_fadelevel},
        no_visibility = {names = config.no_visibility_names, to = config.no_visibility_fadelevel or 0},
      }), animation))
    }),
    Component('Pane', {
      condition = CONDITION.IS_PANE,
      style = TYPE.style_concat({
        Link({
          condition = CONDITION.INACTIVE_OR_FOCUS,
          value = create_unlink(config.exclude_names),
        }),
        TINT.Tint({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Tint(TYPE.extend({}, animation, {
            to = default_tint
          })) or default_tint
        })
      }, get_fade_style(TYPE.extend({}, config, {
        condition = CONDITION.INACTIVE_OR_FOCUS,
        default = {
          names = config.exclude_names,
          start = function (style, state)
            if GLOBALS.vimade_focus_active then
              return default_fade(style, state)
            else
              return 1
            end
          end,
          to = default_fade,
        },
        low_visibility = {
          names = config.low_visibility_names,
          start = 1,
          to = function(style, state)
            return style.win.nc and
            (type(config.low_visibility_fadelevel) == 'function' and config.low_visibility_fadelevel(style, state) or config.low_visibility_fadelevel)
            or default_fade(style, state)
          end
        },
        no_visibility = {
          names = config.no_visibility_names,
          start = 1,
          to = function(style, state)
            return style.win.nc and
            (type(config.no_visibility_fadelevel) == 'function' and config.no_visibility_fadelevel(style, state) or 0)
            or default_fade(style, state)
          end
        }
      }), animation))
    })

  }
  return result
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
  config.condition = config.condition or CONDITION.INACTIVE
  config.exclude_names = config.exclude_names or EXCLUDE_NAMES
  config.no_visibility_names = config.no_visibility_names or NO_VISIBILITY_NAMES
  config.low_visibility_names = config.low_visibility_names or LOW_VISIBILITY_NAMES
  config.low_visibility_fadelevel = config.low_visibility_fadelevel or 0.1

  return {
    style = minimalist(config)
  }
end

return M

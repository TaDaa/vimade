local M = {}

local ANIMATE = require('vimade.style.value.animate')
local CONDITION = require('vimade.style.value.condition')
local DIRECTION = require('vimade.style.value.direction')
local FADE = require('vimade.style.fade')
local GLOBALS = require('vimade.state.globals')
local INVERT = require('vimade.style.invert')
local TINT = require('vimade.style.tint')
local TYPE = require('vimade.util.type')
local Component = require('vimade.style.component').Component
local Link = require('vimade.style.link').Link
local Invert = INVERT.Invert
local Fade = FADE.Fade
local Tint = TINT.Tint

local default_fade = FADE.Default().value()
local default_tint = TINT.Default().value()

local paradox = function (config)
  local invert_condition = function(style)
    if config.invert.active and (not style.win.terminal and not (style.win.area_owner or style.win).nc) then
      return true
    elseif not config.invert.active and (style.win.area_owner or style.win).nc then
      return true
    end
    return false
  end

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
            to = default_tint,
          })) or default_tint
        }),
        Invert({
          condition = config.invert.active and CONDITION.ACTIVE or CONDITION.INACTIVE,
          value = config.invert.to
        }),
        Invert({
          condition = CONDITION.ALL,
          value = 0.02,
        }),
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
            to = default_tint,
          })) or default_tint
        }),
        Fade({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Number(TYPE.extend({}, animation, {
            to = default_fade,
            start = 1,
          })) or default_fade
        }),
        Invert({
          condition = invert_condition,
          value = animation and ANIMATE.Invert(TYPE.extend({}, animation, {
            to = config.invert.focus_to,
            start = config.invert.start,
            duration = config.invert.duration,
            direction = config.invert.direction,
          })) or config.invert.focus_to
        })
      }
    }),
    Component('Pane', {
      condition = CONDITION.IS_PANE,
      style = {
        Tint({
          condition = CONDITION.INACTIVE,
          value = animation and ANIMATE.Tint(TYPE.extend({}, animation, {
            to = default_tint,
          })) or default_tint
        }),
        Fade({
          condition = CONDITION.INACTIVE_OR_FOCUS,
          value = animation and ANIMATE.Number(TYPE.extend({}, animation, {
            to = FADE.Default().value(),
            start = function (style, state)
              if GLOBALS.vimade_focus_active then
                return default_fade(style, state)
              else
                return 1
              end
            end,
          })) or default_fade
        }),
        Invert({
          condition = invert_condition,
          value = animation and ANIMATE.Invert(TYPE.extend({}, animation, {
            to = config.invert.to,
            start = config.invert.start,
            duration = config.invert.duration,
            direction = config.invert.direction,
          })) or config.invert.to
        }),
      }
    })
  }
end

--@param config {
  -- @optional invert = {
    --  @otional start = 0.15
    --  @otional to = 0.1
    --  @otional direction = DIRECTION.IN
    --  @otional duration = DEFAULT_DURATION
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
  config.invert.to = config.invert.to or 0.08
  config.invert.focus_to = config.invert.focus_to or 0.08
  config.invert.active = config.invert.active == nil and true or config.invert.active
  config.invert.direction = config.invert.direction and config.invert.direction or (config.invert.active and DIRECTION.IN or DIRECTION.OUT)
  return {
    style = paradox(config),
    ncmode = 'windows',
  }
end

return M

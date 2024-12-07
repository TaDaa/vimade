local M = {}

local math = require('math')

local CONDITION = require('vimade.style.value.condition')
local COLOR_UTIL = require('vimade.util.color')
local TYPE = require('vimade.util.type')
local VALIDATE = require('vimade.util.validate')
local GLOBALS

M.__init = function(args)
  GLOBALS = args.GLOBALS
end

-- @param config {
  -- @required value = number | function (win) -> number -- number is the fadelevel that is applied to each window
-- }
M.Fade = function(config)
  local result = {}
  local _value = config.value
  local _condition = config.condition or CONDITION.INACTIVE
  result.tick = config.tick
  result.attach = function (win)
    local fade = _value
    local condition = _condition
    local style = {}
    style.win = win
    style._condition = _condition
    style._animating = false
    style.resolve = function (value, state)
      return VALIDATE.fade(TYPE.resolve_all_fn(value, style, state))
    end
    style.before = function (win, state)
      fade = style.resolve(_value, state)
      -- condition needs to be the last check due to animation checks
      if type(_condition) == 'function' then
        condition = _condition(style, state)
      end
    end
    style.key = function (win, state)
      if condition == false then
        return ''
      end
      -- this function compounds the fadelevel only on the existing higlight
      -- only needs to be keyed by fadelevel
      return 'F-' .. fade
    end
    style.modify = function (hl, to_hl)
      -- fade modifies all layers against the background
      -- skip links by default, use include to target them
      if condition == false or hl.link or fade == nil then
        return
      end
      if to_hl.bg ~= nil then
        if hl.fg ~= nil then
          hl.fg = COLOR_UTIL.interpolate24b(hl.fg, to_hl.bg, fade)
        end
        if hl.bg ~= nil then
          hl.bg = COLOR_UTIL.interpolate24b(hl.bg, to_hl.bg, fade)
        end
        if hl.sp ~= nil then
          hl.sp = COLOR_UTIL.interpolate24b(hl.sp, to_hl.bg, fade)
        end
      end
      if hl.blend ~= nil then
        --always assume blend is 100
        --some easing functions can go beyond 100 and under 0, this causes a neovim error
        --cap it here.
        hl.blend = math.max(0, math.min(100, COLOR_UTIL.interpolateLinear(hl.blend, 100, fade)))
      end
      if to_hl.ctermbg ~= nil then
        if hl.ctermfg ~= nil then
          hl.ctermfg = COLOR_UTIL.interpolate256(hl.ctermfg, to_hl.ctermbg, fade)
        end
        if hl.ctermbg ~= nil then
          hl.ctermbg = COLOR_UTIL.interpolate256(hl.ctermbg, to_hl.ctermbg, fade)
        end
      end
    end
    return style
  end
  result.value = function (replacement)
    if replacement ~= nil then
      _value = replacement
      return result
    end
    return _value
  end
  return result
end

M.Default = function (config)
return M.Fade(TYPE.extend({
  condition = CONDITION.INACTIVE,
  value = function (style, state)
    local value = GLOBALS.fadelevel
    if type(value) == 'function' then
      value = value(style, state)
    end
    return value
  end
}, config))
end

return M

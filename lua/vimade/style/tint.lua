local M = {}

local CONDITION = require('vimade.style.value.condition')
local COLOR_UTIL = require('vimade.util.color')
local TYPE = require('vimade.util.type')
local VALIDATE = require('vimade.util.validate')
local GLOBALS

M.__init = function (args)
  GLOBALS = args.GLOBALS
end

M._create_tint = function (tint)
  if type(tint) ~= 'table' then
    return nil
  end
  local fg = tint.fg
  local bg = tint.bg
  local sp = tint.sp
  if not bg and not fg and not sp then
    return nil
  end

  return {
    fg = fg and COLOR_UTIL.to24b(fg.rgb) or nil,
    ctermfg = fg and COLOR_UTIL.toRgb(fg.rgb) or nil,
    fg_intensity = fg and (1 - fg.intensity),
    bg = bg and COLOR_UTIL.to24b(bg.rgb) or nil,
    bg_intensity = bg and (1 - bg.intensity),
    ctermbg = bg and COLOR_UTIL.toRgb(bg.rgb) or nil,
    sp = sp and COLOR_UTIL.to24b(sp) or nil,
    sp_intensity = sp and (1 - sp.intensity),
  }
end

M.Tint = function(config)
  local result = {}
  local _value = config.value
  local _condition = config.condition or CONDITION.INACTIVE
  result.tick = config.tick
  result.attach = function(win)
    local tint = _value
    local to_hl = nil
    local condition = _condition
    local style = {}
    style.win = win
    style._condition = _condition
    style._animating = false
    style.resolve = function (value, state)
       return VALIDATE.tint(TYPE.resolve_all_fn(value, style, state))
    end
    style.before = function (win, state)
      -- don't use style.resolve here for performance reasons
      tint = TYPE.resolve_all_fn(_value, style, state)
      if type(_condition) == 'function' then
        condition = _condition(style, state)
      end
      if condition == false then
        return
      end
      to_hl = M._create_tint(VALIDATE.tint(tint))
    end
    style.key = function (win, state)
      if not to_hl or condition == false then
        return ''
      end
      return 'T-'
      .. (to_hl.fg and ((to_hl.fg or '') .. ',' .. (to_hl.ctermfg and ('t:' .. to_hl.ctermfg[1]..'-'..to_hl.ctermfg[2]..'-'..to_hl.ctermfg[3]) or '') .. ',' .. to_hl.fg_intensity) or '') .. '|'
      .. (to_hl.bg and ((to_hl.bg or '') .. ',' .. (to_hl.ctermbg and ('t:' .. to_hl.ctermbg[1]..'-'..to_hl.ctermbg[2]..'-'..to_hl.ctermbg[3]) or '') .. ',' .. to_hl.bg_intensity) or '') .. '|'
      .. (to_hl.sp and ((to_hl.sp or '') .. to_hl.sp_intensity) or '')
    end
    style.modify = function (hl, target)
      if condition == false or not to_hl or hl.link then
        return
      end
      if target.bg and to_hl.bg then
        target.bg = COLOR_UTIL.interpolate24b(target.bg, to_hl.bg, to_hl.bg_intensity)
      end
      if target.ctermbg and to_hl.ctermbg then
        target.ctermbg = COLOR_UTIL.interpolate256(target.ctermbg, to_hl.ctermbg, to_hl.bg_intensity)
      end
      if hl.fg and to_hl.fg then
        hl.fg = COLOR_UTIL.interpolate24b(hl.fg, to_hl.fg, to_hl.fg_intensity)
      end
      if hl.sp and to_hl.sp then
        hl.sp = COLOR_UTIL.interpolate24b(hl.sp, to_hl.sp, to_hl.sp_intensity)
      end
      if hl.ctermfg and to_hl.ctermfg then
        hl.ctermfg = COLOR_UTIL.interpolate256(hl.ctermfg, to_hl.ctermfg, to_hl.fg_intensity)
      end
      if hl.bg and to_hl.bg then
        hl.bg = COLOR_UTIL.interpolate24b(hl.bg, to_hl.bg, to_hl.bg_intensity)
      end
      if hl.ctermbg and to_hl.ctermbg  then
        hl.ctermbg = COLOR_UTIL.interpolate256(hl.ctermbg, to_hl.ctermbg, to_hl.bg_intensity)
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
return M.Tint(TYPE.extend({
  condition = CONDITION.INACTIVE,
  value = function (style, state)
    if type(GLOBALS.tint) == 'function' then
      return GLOBALS.tint(style, state)
    elseif type(GLOBALS.tint) == 'table' then
      return TYPE.deep_copy(GLOBALS.tint)
    end
    return GLOBALS.tint
  end
}, config))
end

return M

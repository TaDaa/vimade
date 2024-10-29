local M = {}
local CONDITION = require('vimade.style.value.condition')
local COLOR_UTIL = require('vimade.util.color')
local TYPE = require('vimade.util.type')
local GLOBALS

M.__init = function (args)
  GLOBALS = args.GLOBALS
end

M._resolve_all_fn = function (obj, style, state)
  if type(obj) == 'function' then
    obj = obj(style, state)
  end
  if type(obj) == 'table' then
    local copy = {}
    for i, v in pairs(obj) do
      copy[i] = M._resolve_all_fn(v, style, state)
    end
    return copy
  end
  return obj
end

M._create_to_hl = function (tint)
  if not tint then
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
    ctermfg = fg and fg.rgb or nil,
    fg_intensity = fg and (1 - (fg.intensity or 0)),
    bg = bg and COLOR_UTIL.to24b(bg.rgb) or nil,
    bg_intensity = bg and (1 - (bg.intensity or 0)),
    ctermbg = bg and bg.rgb or nil,
    sp = sp and COLOR_UTIL.to24b(sp) or nil,
    sp_intensity = sp and (1 - (sp.intensity or 0)),
  }
end

M.Tint = function(config)
  local result = {}
  local _value = config.value
  local _condition = config.condition or CONDITION.INACTIVE
  result.attach = function(win)
    local tint = _value
    local to_hl = nil
    local condition = _condition
    local style = {}
    style.win = win
    style._condition = _condition
    style._animating = false
    style.before = function (win, state)
      tint = M._resolve_all_fn(_value, style, state)
      if type(_condition) == 'function' then
        condition = _condition(style, state)
      end
      if condition == false then
        return
      end
      to_hl = M._create_to_hl(tint)
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
return M.Tint({
  condition = CONDITION.INACTIVE,
  value = function (style, state)
  if type(GLOBALS.tint) == 'function' then
    return GLOBALS.tint(style, state)
  elseif type(GLOBALS.tint) == 'table' then
    return GLOBALS.tint
  elseif GLOBALS.basebg then
    return {
      fg = {
        rgb = COLOR_UTIL.toRgb(GLOBALS.basebg),
        intensity = 0.5
      }
    }
  end
  return GLOBALS.tint
end})
end

return M

local M = {}
local COLOR_UTIL = require('vimade.util.color')
local GLOBALS

M.__init = function (args)
  GLOBALS = args.GLOBALS
end

M.TINT = function(initial_tint)
  local result = {}
  result.attach = function(win)
    local tint = initial_tint
    local create_to_hl = function (tint)
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
    local to_hl = nil
    if initial_tint and type(initial_tint) ~= 'function' then
      to_hl = create_to_hl(initial_tint)
    end
    return {
      before = function ()
        if type(initial_tint) == 'function' then
          tint = initial_tint(win)
          to_hl = create_to_hl(tint)
        end
      end,
      key = function ()
        if not to_hl then
          return ''
        end
        return 'T-'
        .. (to_hl.fg and ((to_hl.fg or '') .. ',' .. (to_hl.ctermfg[1]..'-'..to_hl.ctermfg[2]..'-'..to_hl.ctermfg[3]) .. ',' .. to_hl.fg_intensity) or '') .. '|'
        .. (to_hl.bg and ((to_hl.bg or '') .. ',' .. (to_hl.ctermbg[1]..'-'..to_hl.ctermbg[2]..'-'..to_hl.ctermbg[3]) .. ',' .. to_hl.bg_intensity) or '') .. '|'
        .. (to_hl.sp and ((to_hl.sp or '') .. to_hl.sp_intensity) or '')
      end,
      modify = function (hl, target)
        if not to_hl then
          return
        end
        -- skip links by default, use include to target them
        if hl.link then
          return
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
    }
  end
  result.value = function (replacement)
    if replacement ~= nil then
      initial_tint = replacement
      return result
    end
    return initial_tint
  end
  return result
end

M.DEFAULT = M.TINT(function (win)
  if type(GLOBALS.tint) == 'function' then
    return GLOBALS.tint(win)
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
end)

return M

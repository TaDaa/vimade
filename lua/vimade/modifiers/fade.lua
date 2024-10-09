local M = {}
local COLOR_UTIL = require('vimade.util.color')

M.__init = function (globals)
  GLOBALS = globals
end

M.FADE = function(initial_fade)
  return function (win)
    local fade = initial_fade
    return {
      before = function ()
        -- before any ops related to this module, we want to ensure we have the most up-to-date fade
        -- for the window
        if type(initial_fade) == 'function' then
          fade = initial_fade(win)
        end
      end,
      key = function ()
        -- this function compounds the fadelevel only on the existing higlight
        -- only needs to be keyed by fadelevel
        return 'F-' .. fade
      end,
      modify = function (hl, to_hl)
        -- fade modifies all layers against the background
        if hl.fg ~= nil then
          hl.fg = COLOR_UTIL.interpolate24b(hl.fg, to_hl.bg, fade)
        end
        if hl.bg ~= nil then
          hl.bg = COLOR_UTIL.interpolate24b(hl.bg, to_hl.bg, fade)
        end
        if hl.sp ~= nil then
          hl.sp = COLOR_UTIL.interpolate24b(hl.sp, to_hl.bg, fade)
        end
        if hl.blend ~= nil then
          --always assume blend is 100
          hl.blend = COLOR_UTIL.interpolateLinear(hl.blend, 100, fade)
        end
        if hl.ctermfg ~= nil then
          hl.ctermfg = COLOR_UTIL.interpolate256(hl.ctermfg, to_hl.ctermbg, fade)
        end
        if hl.ctermbg ~= nil then
          hl.ctermbg = COLOR_UTIL.interpolate256(hl.ctermbg, to_hl.ctermbg, fade)
        end
      end,
    }
  end
end

M.DEFAULT = M.FADE(function (win)
  if type(GLOBALS.fadelevel) == 'function' then
    return GLOBALS.fadelevel(win)
  end
  return GLOBALS.fadelevel
end)

return M

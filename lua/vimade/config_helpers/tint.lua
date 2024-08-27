local M = {}
local COLOR_UTIL = require('vimade.util.color')
local GLOBALS

M.__init = function (globals)
  GLOBALS = globals
end

M.MIX = 'MIX' -- default
M.REPLACE = 'REPLACE' 

M.DEFAULT = function (win)
  if GLOBALS.basebg then
    return {
      -- basebg was previously used as a semi-tint mechanism used in place of the Normalbg
      -- this doesn't exactly reproduce the same colors but gets close
      fg = {
        rgb = COLOR_UTIL.toRgb(GLOBALS.basebg),
        intensity = 0.5,
        type = M.MIX,
      }
    }
  else
    return nil
  end
end

return M

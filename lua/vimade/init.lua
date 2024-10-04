local M = {}
FADER = require('vimade.fader')

if vim == nil or vim.api == nil then
    return
end

M.getInfo = function ()
  return FADER.getInfo()
end

M.unfadeAll = function ()
  FADER.unfadeAll()
end

M.fadeSigns = function ()
  -- no plans for implementation at this time (not needed)
end

M.unfadeSigns = function ()
  -- no plans for implementation at this time (not needed)
end

M.recalculate = function ()
  FADER.recalculate()
end

M.update = function ()
  FADER.tick();
end

M.softInvalidateBuffer = function ()
  -- no plans for implementation at this time (not needed)
end

M.softInvalidateSigns = function ()
  -- no plans for implementation at this time (not needed)
end

return M

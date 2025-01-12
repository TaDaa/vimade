local M = {}
local FADER = require('vimade.fader')

if vim == nil or vim.api == nil then
    return
end

M.setup = function(config)
  return FADER.setup(config)
end

M.getInfo = function ()
  return FADER.getInfo()
end

M.disable = function ()
  FADER.disable()
end

M.redraw = function ()
  FADER.unhighlightAll()
  vim.schedule(FADER.redraw)
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

M.animate = function ()
  FADER.animate()
end

return M

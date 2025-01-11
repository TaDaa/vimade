local M = {}

local events = require('vimade.util.events')()

M.on = events.on

local scheduled = nil
local animating = nil

M.__init = function (args)
  args.FADER.on('tick:before', function()
    if scheduled then
      animating = scheduled
      scheduled = nil
    end
  end)
  args.FADER.on('tick:after', function ()
    if animating then
      animating = nil
    end
    if scheduled then
      vim.schedule(vim.fn['vimade#StartAnimationTimer'])
    end
    events.notify('animator:after')
  end)
end

M.schedule = function (win)
  -- this is also doable via lua code and then scheduling a vim-safe callback
  -- but there appears to be no benefit. Sharing the code across all supported
  -- versions seems much more maintainable currently AND
  -- there also seems to be much less flickering with this approach when compared
  -- to the lua alternative.
  if not scheduled then
    scheduled = {}
  end
  scheduled[win.winid] = true
end

M.is_animating = function(winid)
  return (scheduled[winid] or animating[winid]) or false
end

return M

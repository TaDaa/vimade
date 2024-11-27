local M = {}
local queued_windows = {}
M.scheduled = false
M.animating = false
local FADER

M.__init = function (args)
  FADER = args.FADER
  GLOBALS = args.GLOBALS
  FADER.on('tick:before', function()
    if M.scheduled == true then
      M.scheduled = false
      M.animating = true
    end
  end)
  FADER.on('tick:after', function ()
    if M.animating == true then
      M.animating = false
      -- no more animations are queued, we are going to do one final flush
      -- due to the amount of issues when animating in fademode windows
      -- namespaces colors break in a wide array of scenarios in the internal
      -- Neovim api which can cause all the get queries to return nonsensical results.
      -- usually this is due to the circular highlight pattern many plugins are using.
      if M.scheduled == false then
        vim.schedule(FADER.tick)
      end
    end
    if M.scheduled == true then
      vim.schedule(vim.fn['vimade#StartAnimationTimer'])
    end
  end)
end

M.schedule = function (win)
  -- this is also doable via lua code and then scheduling a vim-safe callback
  -- but there appears to be no benefit. Sharing the code across all supported
  -- versions seems much more maintainable currently
  -- there also seems to be much less flickering with this approach when compared
  -- to the lua alternative.
  --
  -- the below queued_windows cannot be supported in lua at this time, but we should add
  -- it consider adding it back once neovim fixes set_hl issues that break the entire
  -- namespace (not setting each window is currently unsafe).
  -- queued_windows[win.winid] = true
  M.scheduled = true
end

return M

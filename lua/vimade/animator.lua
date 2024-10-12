local M = {}
local queued_windows = {}

M.schedule = function (win)
  -- this is also doable via lua code and then scheduling a vim-safe callback
  -- but there appears to be no benefit. Sharing the code across all supported
  -- versions seems much more maintainable currently
  -- there also seems to be much less flickering with this approach
  if not queued_windows[win.winid] then
    queued_windows[win.winid] = true
  end
  vim.fn['vimade#StartAnimationTimer']()
end

M.refresh = function ()
  only_these_windows = queued_windows
  queued_windows = {}
  return only_these_windows
end

return M

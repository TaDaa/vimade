local M = {}

M.is_type = function(win)
  if win.terminal_match and not win.terminal then
    M.unhighlight(win)
  end
  return win.terminal
end

M.highlight = function(win)
  if not win.terminal_match then
    win.terminal_match = vim.fn.matchadd('Normal', '.*', 0, -1, {window = win.winid})
  end
end

M.unhighlight = function(win)
  if win.terminal_match then
    vim.fn.matchdelete(win.terminal_match, win.winid)
    win.terminal_match = nil
  end
end

return M

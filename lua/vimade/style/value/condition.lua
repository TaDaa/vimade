local M = {}

M.ACTIVE = function (win, state)
  return win.faded == false
end
M.INACTIVE = function (win, state)
  return win.faded == true
end

return M

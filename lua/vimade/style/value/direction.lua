local M = {}

M.IN = 'in'
M.OUT = 'out'
M.IN_OUT = function (style, state)
  if style.win.nc == true then
    return M.OUT
  else
    return M.IN
  end
end
return M

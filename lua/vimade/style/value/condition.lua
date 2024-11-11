local M = {}

-- TODO represent these as behaviors
M.ACTIVE = function (style, state)
  return style.win.nc ~= true or style._animating == true
end
M.INACTIVE = function (style, state)
  return style.win.nc == true or style._animating == true
end
M.ALL = function (style, state)
  return true
end

return M

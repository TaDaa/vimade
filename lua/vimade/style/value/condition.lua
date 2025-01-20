local M = {}

local GLOBALS

M.__init = function (args)
  GLOBALS = args.GLOBALS
end

-- area_owner is the window owning a given area.
M.ACTIVE = function (style, state)
  return ((style.win.area_owner or style.win).nc ~= true or style._animating) and true or false
end
M.INACTIVE = function (style, state)
  return ((style.win.area_owner or style.win).nc == true or style._animating) and true or false
end
M.FOCUS = function (style, state)
  return (((style.win.area_owner or style.win).nc ~= true and GLOBALS.vimade_focus_active) or style._animating) and true or false
end
M.INACTIVE_OR_FOCUS = function(style, state)
  return (((style.win.area_owner or style.win).nc == true or GLOBALS.vimade_focus_active) or style._animating) and true or false
end

M.ALL = function (style, state)
  return true
end

-- mark and focus are subtypes of area
M.IS_MARK = function (style, state)
  return style.win.is_mark and true or false
end
M.IS_FOCUS = function (style, state)
  return style.win.is_focus and true or false
end
M.IS_AREA = function(style, state)
  return style.win.area and true or false
end
-- pane represents anything that can be faded except areas
M.IS_PANE = function (style, state)
  return (not style.win.area) and true or false
end

return M

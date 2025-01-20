local TYPE = require('vimade.util.type')
local MATH_CEIL = math.ceil
local MATH_FLOOR = math.floor
local MATH_MAX = math.max
local MATH_MIN = math.min

-- configure through vimade.setup({
  -- focus = {
    -- providers = {
      -- filetypes = {
        -- default = {
          -- static = {
            -- size is the number of lines that will be returned. Default is 0.5
            -- size = number [1-N] -> number of lines.
            --            number [0.00001-0.99999] or '10%' -> percentage of height
          -- }
        -- }
      -- }
    -- }
  -- }
-- })
return function(config)
  config = config or {}
  if type(config) == 'function' then
    config = config(win)
  end
  local size = TYPE.str_to_pct(config.size)
  local size_is_pct = size and true or false
  size = size or tonumber(config.size) or 0
  return {
    name = 'static',
    get = function (top, bottom, win)
      local size_t = size
      if size_is_pct then
        size_t = MATH_CEIL(win.height * size)
      end
      local above = win.cursor[1] - MATH_FLOOR(size_t / 2)
      local below = win.cursor[1] + MATH_CEIL(size_t / 2) - 1 -- (for current row)
      if above < top then
        below = below + (top - above)
        above = top
      end
      if below > bottom then
        above = above - (below - bottom)
        below = bottom
      end
      return {MATH_MAX(top, above), MATH_MIN(below, bottom)}
    end
  }
end

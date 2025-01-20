local TYPE = require('vimade.util.type')
local MATH_CEIL = math.ceil

local SNACKS_SCOPE = require('snacks.scope')

-- configure through vimade.setup({
  -- focus = {
    -- providers = {
      -- filetypes = {
        -- default = {
          -- snacks = {
            -- args = {} (plugin config to be merged)
            -- -- anything not included in min_size -> max_size gets dropped, allowing providers to chain
            -- max_size is the maximum number of lines allowed to return. If the limit is exceeded, nothing is returned, 
            -- and the next provider is checked. Default is 0 (infinity).
            -- max_size = number [1-N] -> number of lines.
            --            number [0.00001-0.99999] or '10%' -> percentage of height
            --
            -- min_size is the minimum number of lines allowed to return. If the limit is not reached, nothing is returned, 
            -- and the next provider is checked. Default is 1.
            -- min_size = number [1-N] -> number of lines.
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

  local args = config.args or {}
  local min_size = TYPE.str_to_pct(config.min_size)
  local min_size_is_pct = min_size and true or false
  min_size = min_size or tonumber(config.min_size) or 0
  min_size_is_pct = min_size_is_pct or (min_size > 0 and min_size < 1)

  local max_size = TYPE.str_to_pct(config.max_size) or 0
  local max_size_is_pct = min_size and true or false
  max_size = max_size or tonumber(config.max_size) or 0
  max_size_is_pct = max_size_is_pct or (max_size > 0 and max_size < 1)
  return {
    get = function (top, bottom, win)
      local min_size_t = min_size
      if min_size_is_pct then
        min_size_t = MATH_CEIL(win.height * min_size)
      end
      local max_size_t = max_size
      if max_size_is_pct then
        max_size_t = MATH_CEIL(win.height * max_size)
      end

      local scope = SNACKS_SCOPE.get(TYPE.extend(args, {
        buf = win.bufnr,
        pos = win.cursor
      }))
      if scope.from == -1 or scope.to == -1 then
        return nil
      end
      local diff = scope.to - scope.from
      if (min_size_t > 0 and diff < min_size_t) or (max_size_t > 0 and diff > max_size_t) then
        return nil
      end
      -- increase each by 1 to show the owner scope lines
      return {scope.from, scope.to}
    end
  }
end

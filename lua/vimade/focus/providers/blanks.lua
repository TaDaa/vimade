local TYPE = require('vimade.util.type')
local MATH_CEIL = math.ceil

-- configure through vimade.setup({
  -- focus = {
    -- providers = {
      -- filetypes = {
        -- default = {
          -- blanks = {
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

      local lines = vim.api.nvim_buf_get_lines(win.bufnr, top - 1, bottom - 1, false)
      local i = win.cursor[1] - top + 1
      local result = {0, 0}
      while i >= 1 do
        if lines[i] == '' then
          break
        end
        i = i - 1
      end
      result[1] = i + top - 1
      i = win.cursor[1] - top + 1
      while i <= (bottom - top) do
        if lines[i] == '' then
          break
        end
        i = i + 1
      end
      result[2] = i + top - 1
      local diff = result[2] - result[1]
      if (min_size_t > 0 and diff < min_size_t) or (max_size_t > 0 and diff > max_size_t) then
        return nil
      end
      return result
    end
  }
end

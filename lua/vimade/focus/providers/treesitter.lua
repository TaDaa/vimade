local TYPE = require('vimade.util.type')
local MATH_CEIL = math.ceil

-- configure through vimade.setup({
  -- focus = {
    -- providers = {
      -- filetypes = {
        -- default = {
          -- treesitter = {
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
            --
            -- min_node_size is the minimum number of lines in a treesitter node to be considered valid.
            -- and the next provider is checked. Default is 2.
            -- min_node_size = number [1-N] -> number of lines.
            --            number [0.00001-0.99999] or '10%' -> percentage of height
            --
            -- include is a list of node names that are considered valid. Anything outside this list is excluded.
            -- Default is nil.
            -- include = {'if_statement', 'block', ...}
            --
            -- exclude is a list of node names that are excluded. Anything inside this list is excluded.
            -- Default is {'block'}.
            -- exclude = {'if_statement', 'block', ...}
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
  min_size = min_size or tonumber(config.min_size) or 1
  min_size_is_pct = min_size_is_pct or (min_size > 0 and min_size < 1)

  local max_size = TYPE.str_to_pct(config.max_size)
  local max_size_is_pct = max_size and true or false
  max_size = max_size or tonumber(config.max_size) or 0
  max_size_is_pct = max_size_is_pct or (max_size > 0 and max_size < 1)

  local min_node_size = TYPE.str_to_pct(config.min_node_size)
  local min_node_size_is_pct = min_node_size and true or false
  min_node_size = min_node_size or tonumber(config.min_node_size) or 2
  min_node_size_is_pct = min_node_size_is_pct or (min_node_size > 0 and min_node_size < 1)

  local include = config.include or nil
  local exclude = config.exclude or nil
  local include_map
  local exclude_map = {}

  if include then
    include_map = {}
    for _, name in ipairs(include) do
      include_map[name] = true
    end
  end

  if exclude then
    for _, name in ipairs(exclude) do
      exclude_map[name] = true
    end
  end

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
      local min_node_size_t = min_node_size
      if min_node_size_is_pct then
        min_node_size_t = MATH_CEIL(win.height * min_node_size)
      end

      local status, parser = pcall(vim.treesitter.get_parser, win.bufnr)
      if not status or not parser then
        return nil
      end
      pcall(parser.parse, parser, top, bottom)
      local status, node = pcall(vim.treesitter.get_node,{bufnr=win.bufnr, pos={win.cursor[1]-1,win.cursor[2]}})

      if not status or not node then
        return nil
      end

      while (
        node and (
          exclude_map[node:type()]
          or (include_map and not include_map[node:type()])
          or (min_node_size_t > 0 and (node:end_() - node:start()) < min_node_size_t)
        )) do 
        node = node:parent()
      end
      if node then
        local result = {node:start() + 1, node:end_() + 1}
        local diff = result[2] - result[1]
        if (min_size_t > 0 and diff < min_size_t) or (max_size_t > 0 and diff > max_size_t) then
          return nil
        end
        return result
      end
      return nil
    end
  }
end

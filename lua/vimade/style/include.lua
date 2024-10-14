local M = {}
local COMPAT = require('vimade.util.compat')

M.__init = function (globals)
  GLOBALS = globals
end

M.include_names = {}
M.include_id = 1

-- @param config = {
--  names= {'Folded', 'VertSplit', 'Normal', ...}, # list of names that should be skipped on the style array
--  style = {Fade(0.4)} # style to run on all names that aren included
--}
M.Include = function(config)
  local result = {}
  result.attach = function (win)
    local names = config.names
    local style = {}
    for i, s in ipairs(config.style) do
      table.insert(style, s.attach(win))
    end
    local include = {}
    local include_ids = {}
    return {
      before = function ()
        include = {}
        include_ids = {}
        local input

        if type(names) == 'function' then
          input = names(win)
        else
          input = names
        end
        if type(input) == 'string' then
          input = {input}
        end
        -- order required to prevent invalidation
        for i, name in ipairs(input) do
          local name_id = M.include_names[name]
          if name_id == nil then
            name_id = M.include_id
            M.include_names[name] = name_id
            M.include_id = M.include_id + 1
          end
          if include[name] == nil then
            include[name] = name_id
            table.insert(include_ids, name_id)
          end
        end
        for i, s in ipairs(style) do
          s.before()
        end
      end,
      key = function (i)
        local key ='I-' .. table.concat(include_ids, ',') .. '('
        for j, s in ipairs(style) do
          if j ~= 0 then
            key = key .. ','
          end
          key = key .. s.key(j)
        end
        key = key .. ')'
        return key
      end,
      modify = function (hl, to_hl)
        if include[hl.name] then
          -- anything that is "Included' needs to be unlinked so that it visually changes
          -- the highlights here should already be correct (see namespace.lua - resolve_all_links)
          if hl.link then
            hl.link = nil
          end
          for i, s in ipairs(style) do
            s.modify(hl, to_hl)
          end
        end
      end,
    }
  end
  -- value is not exposed here, no use-case currently
  return result
end
return M

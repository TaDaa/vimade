local M = {}
local COMPAT = require('vimade.util.compat')

M.__init = function (args)
  GLOBALS = args.GLOBALS
end

M.include_names = {}
M.include_id = 1

-- @param config = {
--  names= {'Folded', 'VertSplit', 'Normal', ...}, # list of names that should be skipped on the style array
--  style = {Fade(0.4)} # style to run on all names that aren included
--}
M.Include = function(config)
  local result = {}
  local _condition = config.condition
  result.attach = function (win)
    local condition = _condition
    local names = config.names
    local style = {}
    for i, s in ipairs(config.style) do
      table.insert(style, s.attach(win))
    end
    local include = {}
    local include_ids = {}
    return {
      before = function (win, state)
        if type(_condition) == 'function' then
          condition = _condition(win, state)
        end
        if condition == false then
          return
        end
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
          s.before(win, state)
        end
      end,
      key = function (win, state)
        if condition == false then
          return ''
        end
        local key ='I-' .. table.concat(include_ids, ',') .. '('
        for j, s in ipairs(style) do
          if j ~= 0 then
            key = key .. ','
          end
          key = key .. s.key(win, state)
        end
        key = key .. ')'
        return key
      end,
      modify = function (hl, to_hl)
        if condition == false then
          return
        end
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

local M = {}
local COMPAT = require('vimade.util.compat')
local CONDITION = require('vimade.style.value.condition')

M.__init = function (args)
  GLOBALS = args.GLOBALS
end

M.include_names = {}
M.include_id = 1

-- @param config = {
--  value= {'Folded', 'VertSplit', 'Normal', ...}, # list of names that should be skipped on the style array
--  style = {Fade(0.4)} # style to run on all names that aren included
--}
M.Include = function(config)
  local result = {}
  local _condition = config.condition or CONDITION.INACTIVE
  result.tick = config.tick
  result.attach = function (win)
    local condition = _condition
    local names = config.value
    local children = {}
    for i, s in ipairs(config.style) do
      table.insert(children, s.attach(win))
    end
    local include = {}
    local include_ids = {}
    local style = {}
    style.win = win
    style._condition = _condition
    style._animating = false
    style.before = function (win, state)
      if type(_condition) == 'function' then
        condition = _condition(style, state)
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
      for i, s in ipairs(children) do
        s.before(win, state)
      end
    end
    style.key = function (win, state)
      if condition == false then
        return ''
      end
      local key ='I-' .. table.concat(include_ids, ',') .. '('
      local s_active = 0
      for j, s in ipairs(children) do
        if j ~= 0 then
          key = key .. ','
        end
        local s_key = s.key(win, state)
        key = key .. s_key
        if string.len(s_key) > 0 then
          s_active = s_active + 1
        end
      end
      if s_active == 0 then
        return ''
      end
      key = key .. ')'
      return key
    end
    style.modify = function (hl, to_hl)
      if condition == false then
        return
      end
      if include[hl.name] then
        -- anything that is "Included' needs to be unlinked so that it visually changes
        -- the highlights here should already be correct (see namespace.lua - resolve_all_links)
        if hl.link then
          hl.link = nil
        end
        -- force include our bg if it hasn't been included since we are intending
        -- to highlight these
        if hl.bg == nil and to_hl.bg ~= nil then
          hl.bg = to_hl.bg
        end
        if hl.ctermbg == nil and to_hl.ctermbg ~= nil then
          hl.ctermbg = to_hl.ctermbg
        end
        for i, s in ipairs(children) do
          s.modify(hl, to_hl)
        end
      end
    end
    return style
  end
  -- value is not exposed here, no use-case currently
  return result
end
return M

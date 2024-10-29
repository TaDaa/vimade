local M = {}
local CONDITION = require('vimade.style.value.condition')

M.__init = function (args)
  GLOBALS = args.GLOBALS
end

M.exclude_names = {}
M.exclude_id = 1

-- @param config = {
--  names= {'Folded', 'VertSplit', 'Normal', ...}, # list of names that should be skipped on the style array
--  style = {Fade(0.4)} # styles to run on all names that aren't excluded
--}
M.Exclude = function(config)
  local result = {}
  local _condition = config.condition or CONDITION.INACTIVE
  result.attach = function (win)
    local names = config.names
    local condition = _condition
    local children = {}
    for i, s in ipairs(config.style) do
      table.insert(children, s.attach(win))
    end
    local exclude = {}
    local exclude_ids = {}
    local style = {}
    style.win = win
    style._condition = _condition
    style._animating = false
    style.before =  function (win, state)
      if type(_condition) == 'function' then
        condition = _condition(style, state)
      end
      if condition == false then
        return
      end
      exclude = {}
      exclude_ids = {}
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
        local name_id = M.exclude_names[name]
        if name_id == nil then
          name_id = M.exclude_id
          M.exclude_names[name] = name_id
          M.exclude_id = M.exclude_id + 1
        end
        if exclude[name] == nil then
          exclude[name] = name_id
          table.insert(exclude_ids, name_id)
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
      local key ='E-' .. table.concat(exclude_ids, ',') .. '('
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
      if condition == false or exclude[hl.name] then
        return
      end
      for i, s in ipairs(children) do
        s.modify(hl, to_hl)
      end
    end
    return style
  end
  -- value is not exposed here, no use-case currently
  return result
end
return M

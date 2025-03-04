local M = {}

local CONDITION = require('vimade.style.value.condition')

local exclude_key_reducer = require('vimade.util.key_reducer')()

-- @param config = {
--  value= {'Folded', 'VertSplit', 'Normal', ...}, # list of names that should be skipped on the style array
--  style = {Fade(0.4)} # styles to run on all names that aren't excluded
--}
M.Exclude = function(config)
  local result = {}
  local _condition = config.condition or CONDITION.INACTIVE
  result.tick = config.tick
  result.attach = function (win)
    local names = config.value
    local condition = _condition
    local children = {}
    for i, s in ipairs(config.style) do
      table.insert(children, s.attach(win))
    end
    local exclude = {}
    local exclude_key = ''
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
      local input

      if type(names) == 'function' then
        input = names(win)
      else
        input = names
      end
      if type(input) == 'string' then
        input = {input}
      end

      exclude_key = exclude_key_reducer.reduce_ipairs(input)

      exclude = {}
      for i, name in ipairs(input) do
        exclude[name] = true
      end

      for i, s in ipairs(children) do
        s.before(win, state)
      end
    end
    style.key = function (win, state)
      if condition == false then
        return ''
      end
      local key ='E-' .. exclude_key .. '('
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
    style.modify = function (highlights, to_hl)
      if condition == false then
        return
      end
      local excluded_for_children = {} 
      for name, _ in pairs(exclude) do
        excluded_for_children[name] = highlights[name]
        highlights[name] = nil
      end
      for i, s in ipairs(children) do
        s.modify(highlights, to_hl)
      end
      for name, value in pairs(excluded_for_children) do
        highlights[name] = excluded_for_children[name]
      end
    end
    return style
  end
  -- value is not exposed here, no use-case currently
  return result
end
return M

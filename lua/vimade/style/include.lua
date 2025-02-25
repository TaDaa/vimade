local M = {}

local COMPAT = require('vimade.util.compat')
local CONDITION = require('vimade.style.value.condition')
local GLOBALS

local include_key_reducer = require('vimade.util.key_reducer')()

M.__init = function (args)
  GLOBALS = args.GLOBALS
end

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
    local include_key = ''
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
      local input

      if type(names) == 'function' then
        input = names(win)
      else
        input = names
      end
      if type(input) == 'string' then
        input = {input}
      end

      include_key = include_key_reducer.reduce_ipairs(input)

      include = {}
      for i, name in ipairs(input) do
        include[name] = true
      end

      for i, s in ipairs(children) do
        s.before(win, state)
      end
    end
    style.key = function (win, state)
      if condition == false then
        return ''
      end
      local key ='I-' .. include_key .. '('
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
      local highlights_for_children = {}
      for name, _ in pairs(include) do
        highlights_for_children[name] = highlights[name]
      end
      for i, s in ipairs(children) do
        s.modify(highlights_for_children, to_hl)
      end
      for name, value in pairs(highlights_for_children) do
        highlights[name] = value
      end
    end
    return style
  end
  -- value is not exposed here, no use-case currently
  return result
end
return M

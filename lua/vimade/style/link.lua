local M = {}

local CONDITION = require('vimade.style.value.condition')

local TABLE_INSERT = table.insert

local link_key_reducer = require('vimade.util.key_reducer')()

-- @param config = {
--  value= {{from='Folded'= , to={nil or 'LinkTarget'} ...}}, # list of names that should be linked or unlinked.
--}
M.Link = function(config)
  local result = {}
  local _condition = config.condition or CONDITION.INACTIVE
  result.tick = config.tick
  result.attach = function (win)
    local value = config.value
    local condition = _condition
    local link = {}
    local link_key = ''
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
      if type(value) == 'function' then
        input = value(win)
      else
        input = value
      end

      link = {}
      local key_input = {}
      for _, v in ipairs(input) do
        TABLE_INSERT(key_input, v.from .. (v.to or ''))
        TABLE_INSERT(link, v)
      end
      link_key = link_key_reducer.reduce_ipairs(key_input)
    end
    style.key = function (win, state)
      if condition == false then
        return ''
      end
      return 'L-' .. link_key 
    end
    style.modify = function (highlights, to_hl)
      if condition == false then
        return
      end
      local hl
      local to
      for _, li in ipairs(link) do
        hl = highlights[li.from]
        to = li.to
        if hl and to and to ~= '' then
          hl.link = to
        end
      end
    end
    return style
  end
  -- value is not exposed here, no use-case currently
  return result
end
return M

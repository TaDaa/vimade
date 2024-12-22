local M = {}

local CONDITION = require('vimade.style.value.condition')
local GLOBALS

local unlink_key_reducer = require('vimade.util.key_reducer')()

M.__init = function (args)
  GLOBALS = args.GLOBALS
end

-- @param config = {
--  value= {'Folded', 'VertSplit', 'Normal', ...}, # list of names that should be unlinked.
--}
M.Unlink = function(config)
  local result = {}
  local _condition = config.condition or CONDITION.INACTIVE
  result.tick = config.tick
  result.attach = function (win)
    local names = config.value
    local condition = _condition
    local unlink = {}
    local unlink_key = ''
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

      unlink_key = unlink_key_reducer.reduce_ipairs(input)

      unlink = {}
      for i, name in ipairs(input) do
        unlink[name] = true
      end
    end
    style.key = function (win, state)
      if condition == false then
        return ''
      end
      return 'U-' .. unlink_key 
    end
    style.modify = function (hl, to_hl)
      if unlink[hl.name] then
        hl.link = nil
      end
    end
    return style
  end
  -- value is not exposed here, no use-case currently
  return result
end
return M

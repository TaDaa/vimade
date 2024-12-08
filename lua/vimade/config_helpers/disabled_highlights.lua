local M = {}
local MATCHERS = require('vimade.util.matchers')
local FADER
local GLOBALS

local tick_rules = {fn = {}, name = {}}

M.__init = function (args)
  GLOBALS = args.GLOBALS
  args.FADER.on('tick:refresh', function()
    local fn = {}
    local name = {}
    tick_rules.fn = fn
    tick_rules.name = name
    for rule_name, rule in pairs(GLOBALS.disabled_highlights) do
      if type(rule) == 'function' then
        table.insert(fn)
      elseif type(rule) == 'table' then
        for key, value in ipairs(rule) do
          if type(value) == 'function' then
            table.insert(fn, value)
          else
            name[value] = true
          end
        end
      end
    end
  end)
end

M.is_disabled = function (hl_name)
  if tick_rules.name[hl_name] == true then
    return true
  end
  for key, value in ipairs(tick_rules.fn) do
    if value(hl_name) == true then
      return true
    end
  end
  return false
end

return M

local M = {}

local MATCHERS = require('vimade.util.matchers')
local GLOBALS = require('vimade.state.globals')

local TABLE_INSERT = table.insert

local minimap_matcher = MATCHERS.StringMatcher('-minimap')
local highlight_key_reducer = require('vimade.util.key_reducer')()

M.DEFAULT = function (win, active, config)
  local legacy
  if GLOBALS.fademinimap == false or config.buf_name then
    legacy = (GLOBALS.fademinimap == false and minimap_matcher(win.buf_name))
  end
  return
    legacy
    or (config.buf_name and MATCHERS.ContainsString(config.buf_name)(win.buf_name))
    or (config.win_type and MATCHERS.ContainsString(config.win_type)(win.win_type))
    or (config.buf_opts and MATCHERS.ContainsAny(config.buf_opts)(win.buf_opts))
    or (config.buf_vars and MATCHERS.ContainsAny(config.buf_vars)(win.buf_vars))
    or (config.win_opts and MATCHERS.ContainsAny(config.win_opts)(win.win_opts))
    or (config.win_vars and MATCHERS.ContainsAny(config.win_vars)(win.win_vars))
    or (config.win_config and MATCHERS.ContainsAny(config.win_config)(win.win_config))
end

M.TO_HIGHLIGHTS_KEY = function(blocked_highlights)
  local result1 = highlight_key_reducer.reduce_ipairs(blocked_highlights.exact)
  local result2 = highlight_key_reducer.reduce_ipairs(blocked_highlights.pattern)
  return result1 .. '+' .. result2
end

M.HIGHLIGHTS = function(win, active)
  -- result is a simple map of names that are blocked
  local result = {exact = {}, pattern = {}}
  local exact = result.exact
  local pattern = result.pattern
  local include = function(name)
    if name:sub(1,1) == '/' and name:sub(-1) == '/' then
      TABLE_INSERT(pattern, name:sub(2,-2))
    else
      TABLE_INSERT(exact, name)
    end
  end
  if GLOBALS.blocklist then
    for rule_name, rule in pairs(GLOBALS.blocklist) do
      if type(rule) == 'table' and rule.highlights then
        for key, value in pairs(rule.highlights) do
          if type(value) == 'function' then
            value = value(win, active)
            if type(value) == 'string' then
              include(value)
            elseif type(value) == 'table' then
              for k, v in pairs(value) do
                include(v)
              end
            end
          else
            include(value)
          end
        end
      end
    end
  end
  return result
end

return M

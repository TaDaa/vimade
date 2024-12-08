local M = {}

local MATCHERS = require('vimade.util.matchers')
local GLOBALS = require('vimade.state.globals')

local minimap_matcher = MATCHERS.StringMatcher('-minimap')

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

local cache_names = {}
local cache_name_cnt = 0
-- TODO this should be moved into a generic helper, we use this a lot
-- to reduce key size.  Can also abtract to alpha.
M.TO_HIGHLIGHTS_KEY = function(blocked_highlights)
  local key = ''
  for name, value in pairs(blocked_highlights) do
    if not cache_names[name] then
      cache_names[name] = cache_name_cnt
      cache_name_cnt = cache_name_cnt + 1
    end
    key = key .. ',' .. cache_names[name]
  end
  return key
end

M.HIGHLIGHTS = function(win, active)
  -- result is a simple map of names that are blocked
  local result = {}
  if GLOBALS.blocklist then
    for rule_name, rule in pairs(GLOBALS.blocklist) do
      if type(rule) == 'table' and rule.highlights then
        for key, value in pairs(rule.highlights) do
          if type(value) == 'function' then
            value = value(win, active)
            if type(value) == 'string' then
              result[value] = true
            elseif type(value) == 'table' then
              for k, v in pairs(value) do
                result[v] = true
              end
            end
          else
            result[value] = true
          end
        end
      end
    end
  end
  return result
end

return M

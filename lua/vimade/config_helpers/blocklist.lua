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
    or (config.buf_opts and MATCHERS.ContainsAny(config.buf_opts)(win:buf_opts()))
    or (config.buf_vars and MATCHERS.ContainsAny(config.buf_vars)(win:buf_vars()))
    or (config.win_opts and MATCHERS.ContainsAny(config.win_opts)(win:win_opts()))
    or (config.win_vars and MATCHERS.ContainsAny(config.win_vars)(win:win_vars()))
    or (config.win_config and MATCHERS.ContainsAny(config.win_config)(win.win_config))
end

return M

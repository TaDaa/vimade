import sys
M = sys.modules[__name__]

from vimade.state.util import matchers as MATCHERS
from vimade.state import globals as GLOBALS

_minimap_matcher = MATCHERS.StringMatcher('-minimap')

def DEFAULT(win, active, config):
  legacy = None
  if GLOBALS.fademinimap == False or config.buf_names:
    legacy = (GLOBALS.fademinimap == False and _minimap_matcher(win.buf_name))
  return
    legacy
    or (config.buf_names and MATCHERS.ContainsString(config.buf_names)(win.buf_name))
    or (config.buf_opts and MATCHERS.ContainsAny(config.buf_opts)(win.buf_opts()))
    or (config.buf_vars and MATCHERS.ContainsAny(config.buf_vars)(win.buf_vars()))
    or (config.win_opts and MATCHERS.ContainsAny(config.win_opts)(win.win_opts()))
    or (config.win_vars and MATCHERS.ContainsAny(config.win_vars)(win.win_vars()))
    or (config.win_config and MATCHERS.ContainsAny(config.win_config)(win.win_config))

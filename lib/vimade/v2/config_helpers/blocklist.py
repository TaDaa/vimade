import sys
M = sys.modules[__name__]

from vimade.state.util import matchers as MATCHERS
from vimade.state import globals as GLOBALS

_minimap_matcher = MATCHERS.StringMatcher('-minimap')

def DEFAULT(win, active, config):
  legacy = None
  if GLOBALS.fademinimap == False or buf_names in config:
    legacy = (_minimap_matcher(win.buf_name) if GLOBALS.fademinimap == False else False)
  return
    legacy
    or (MATCHERS.ContainsString(config.buf_names)(win.buf_name) if 'buf_names' in config else False)
    or (MATCHERS.ContainsAny(config.buf_opts)(win.buf_opts()) if 'buf_opts' in config else False)
    or (MATCHERS.ContainsAny(config.buf_vars)(win.buf_vars()) if 'buf_vars' in config else False)
    or (MATCHERS.ContainsAny(config.win_opts)(win.win_opts()) if 'win_opts' in config else False)
    or (MATCHERS.ContainsAny(config.win_vars)(win.win_vars()) if 'win_vars' in config else False)
    or (MATCHERS.ContainsAny(config.win_config)(win.win_config) if 'win_config' in config else False)

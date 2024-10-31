import sys
M = sys.modules[__name__]

from vimade.util import matchers as MATCHERS
from vimade.state import globals as GLOBALS

_minimap_matcher = MATCHERS.StringMatcher('-minimap')

def DEFAULT(win, active, config):
  legacy = None
  if GLOBALS.fademinimap == False or 'buf_name' in config:
    legacy = (_minimap_matcher(win.buf_name) if GLOBALS.fademinimap == False else False)
  return legacy \
    or (MATCHERS.ContainsString(config['buf_name'])(win.buf_name) if config.get('buf_name') else False) \
    or (MATCHERS.ContainsString(config['win_type'])(win.win_type) if config.get('win_type') else False) \
    or (MATCHERS.ContainsAny(config['buf_opts'])(win.buf_opts) if config.get('buf_opts') else False) \
    or (MATCHERS.ContainsAny(config['buf_vars'])(win.buf_vars) if config.get('buf_vars') else False) \
    or (MATCHERS.ContainsAny(config['win_opts'])(win.win_opts) if config.get('win_opts') else False) \
    or (MATCHERS.ContainsAny(config['win_vars'])(win.win_vars) if config.get('win_vars') else False) \
    or (MATCHERS.ContainsAny(config['win_config'])(win.win_config) if config.get('win_config') else False)

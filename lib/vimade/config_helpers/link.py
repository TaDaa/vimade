import sys
M = sys.modules[__name__]

from vimade.util import matchers as MATCHERS
from vimade.state import globals as GLOBALS

def DEFAULT(win, active, config):
  legacy = False
  if GLOBALS.groupdiff == True or GLOBALS.groupscrollbind == True:
    win_wo = win.win_opts
    active_wo = active.win_opts
    legacy = (GLOBALS.groupdiff and MATCHERS.EachContainsAny({'diff': True})([active_wo, win_wo])) \
      or (GLOBALS.groupscrollbind and MATCHERS.EachContainsAny({'scrollbind': True})([active_wo, win_wo]))
  return legacy \
    or (MATCHERS.ContainsString(config['buf_name'])(win.buf_name) and MATCHERS.ContainsString(config.buf_name)(active.buf_name) if config.get('buf_name') else False) \
    or (MATCHERS.ContainsString(config['win_type'])(win.win_type) and MATCHERS.ContainsString(config.win_type)(active.win_type) if config.get('win_type') else False) \
    or (MATCHERS.EachContainsAny(config['buf_opts'])([active.buf_opts, win.buf_opts]) if config.get('buf_opts') else False) \
    or (MATCHERS.EachContainsAny(config['buf_vars'])([active.buf_vars, win.buf_vars]) if config.get('buf_vars') else False) \
    or (MATCHERS.EachContainsAny(config['win_opts'])([active.win_opts, win.win_opts]) if config.get('win_opts') else False) \
    or (MATCHERS.EachContainsAny(config['win_vars'])([active.win_vars, win.win_vars]) if config.get('win_vars') else False) \
    or (MATCHERS.EachContainsAny(config['win_config'])([active.win_config, win.win_config]) if config.get('win_config') else False)

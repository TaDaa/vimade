import sys
M = sys.modules[__name__]

from vimade.state.util import matchers as MATCHERS
from vimade.state import globals as GLOBALS

def DEFAULT(win, active, config):
  legacy = False
  if GLOBALS.groupdiff == True or GLOBALS.groupscrollbind == True then
    win_wo = win.win_opts()
    active_wo = active.win_opts()
    legacy = (GLOBALS.groupdiff and MATCHERS.EachContainsAny({'diff': True})([active_wo, win_wo]))
     or (GLOBALS.groupscrollbind and MATCHERS.EachContainsAny({'scrollbind': True})([active_wo, win_wo]))
  return
    legacy
    or (config.buf_names and MATCHERS.ContainsString(config.buf_names)(win.buf_name) and MATCHERS.ContainsString(config.buf_names)(active.buf_name))
    or (config.buf_opts and MATCHERS.EachContainsAny(config.buf_opts)([active.buf_opts(), win.buf_opts()]))
    or (config.buf_vars and MATCHERS.EachContainsAny(config.buf_vars)([active.buf_vars(), win.buf_vars()]))
    or (config.win_opts and MATCHERS.EachContainsAny(config.win_opts)([active.win_opts(), win.win_opts()]))
    or (config.win_vars and MATCHERS.EachContainsAny(config.win_vars)([active.win_vars(), win.win_vars()]))
    or (config.win_config and MATCHERS.EachContainsAny(config.win_config)([active.win_config, win.win_config]))

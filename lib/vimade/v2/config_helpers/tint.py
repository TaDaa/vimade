import sys
M = sys.modules[__name__]

from vimade.v2.util import color as COLOR_UTIL
GLOBALS = None

def __init(globals):
  global GLOBALS
  GLOBALS = globals
M.__init = __init

M.MIX = 'MIX'
M.REPLACE = 'REPLACE'

def DEFAULT(win, current):
  if GLOBALS.basebg:
    ## basebg was previously used as a semi-tint mechanism used in place of the Normalbg
    ## this doesn't exactly reproduce the same colors but gets close
    return {
      'fg': {
        'rgb': COLOR_UTIL.toRgb(GLOBALS.basebg),
        'intensity': 0.5,
        'type': M.MIX,
      }
    }
  else:
    return None 
  

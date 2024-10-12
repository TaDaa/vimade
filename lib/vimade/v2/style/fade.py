import sys
import time
M = sys.modules[__name__]

from vimade.v2.util import color as COLOR_UTIL
GLOBALS = None

def __init(globals):
  global GLOBALS
  GLOBALS = globals
M.__init = __init

class Fade():
  def __init__(parent, initial_fade):
    parent.initial_fade = initial_fade
    class __Fade():
      def __init__(self, win):
        self.fade = parent.initial_fade
        self.win = win
      def before(self):
        if callable(parent.initial_fade):
          self.fade = parent.initial_fade(self.win)
      def key(self, i):
        return 'F-' + str(self.fade)
      def modify(self, hl, to_hl):
        fade = self.fade
        fg = hl['fg']
        bg = hl['bg']
        sp = hl['sp']
        ctermfg = hl['ctermfg']
        ctermbg = hl['ctermbg']
        if fg != None:
          hl['fg'] = COLOR_UTIL.interpolate24b(fg, to_hl['bg'], fade)
        if bg != None:
          hl['bg'] = COLOR_UTIL.interpolate24b(bg, to_hl['bg'], fade)
        if sp != None:
          hl['sp'] = COLOR_UTIL.interpolate24b(sp, to_hl['bg'], fade)
        if ctermfg != None:
          hl['ctermfg'] = COLOR_UTIL.interpolate256(ctermfg, to_hl['ctermbg'], fade)
        if ctermbg != None:
          hl['ctermbg'] = COLOR_UTIL.interpolate256(ctermbg, to_hl['ctermbg'], fade)
        return
    parent.attach = __Fade
  def value(parent, replacement = None):
    if replacement != None:
      parent.initial_fade = replacement
      return parent
    return parent.initial_fade

M.DEFAULT = Fade(lambda win: GLOBALS.fadelevel(win) if callable(GLOBALS.fadelevel) else GLOBALS.fadelevel)

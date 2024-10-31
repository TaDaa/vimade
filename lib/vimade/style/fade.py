import sys
import time
M = sys.modules[__name__]

from vimade.util import color as COLOR_UTIL
from vimade.style.value import condition as CONDITION
GLOBALS = None

def __init(args):
  global GLOBALS
  GLOBALS = args['GLOBALS']
M.__init = __init

class Fade():
  def __init__(parent, **kwargs):
    _condition = kwargs.get('condition')
    _condition = _condition if _condition != None else CONDITION.INACTIVE
    parent._value = kwargs.get('value')
    class __Fade():
      def __init__(self, win, state):
        self.win = win
        self._condition = _condition
        self.condition = None
        self.fade = parent._value
        self._animating = False
      def before(self, win, state):
        self.fade = parent._value(self, state) if callable(parent._value) else parent._value
        self.condition = _condition(self, state) if callable(_condition) else _condition
      def key(self, win, state):
        if self.condition == False:
          return ''
        return 'F-' + str(self.fade)
      def modify(self, hl, to_hl):
        if self.condition == False:
          return
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
      parent._value = replacement
      return parent
    return parent._value

def Default(**kwardgs):
  return Fade(condition = CONDITION.INACTIVE,
    value = lambda style, state: GLOBALS.fadelevel(style, state) if callable(GLOBALS.fadelevel) else GLOBALS.fadelevel)

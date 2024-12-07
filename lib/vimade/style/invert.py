import sys
import time
M = sys.modules[__name__]

from vimade.util import color as COLOR_UTIL
from vimade.style.value import condition as CONDITION
from vimade.util import type as TYPE
from vimade.util import validate as VALIDATE

GLOBALS = None

def __init(args):
  global GLOBALS
  GLOBALS = args['GLOBALS']
M.__init = __init

# @required
# number | {
#   @optional 'fg': 0-1,         # applies the given intensity to text
#   @optional 'bg': 0-1,         # applies the given intensity to background
#   @optional 'sp': 0-1,         # applies the given intensity to special
# }
class Invert():
  def __init__(parent, **kwargs):
    _condition = kwargs.get('condition')
    _condition = _condition if _condition != None else CONDITION.INACTIVE
    parent._value = kwargs.get('value')
    parent.tick = kwargs.get('tick')
    class __Invert():
      def __init__(self, win, state):
        self.win = win
        self._condition = _condition
        self.condition = None
        self.invert = parent._value
        self._animating = False
      def resolve(self, value, state):
        return VALIDATE.invert(TYPE.resolve_all_fn(value, self, state))
      def before(self, win, state):
        invert = self.resolve(parent._value, state)
        self.condition = _condition(self, state) if callable(_condition) else _condition
        if self.condition == False:
          return
        self.invert = invert
      def key(self, win, state):
        if self.condition == False or not self.invert:
          return ''
        # TODO shrink
        return 'INV-' + str(self.invert.get('fg',0)) + '-' + str(self.invert.get('bg',0)) + '-' + str(self.invert.get('sp',0))
      def modify(self, hl, to_hl):
        if self.condition == False or not self.invert:
          return
        invert = self.invert
        for hi in (hl, to_hl):
          for key in ('fg', 'bg', 'sp'):
            color = hi.get(key)
            if color != None:
              hi[key] = COLOR_UTIL.interpolate24b(color, 0XFFFFFF - color, 1 - invert[key])
          for (key, i_key) in (('ctermfg', 'fg'), ('ctermbg', 'bg')):
            color = hi.get(key)
            if color != None:
              color = COLOR_UTIL.toRgb(color, True)
              target = [255 - color[0], 255 - color[1], 255 - color[2]]
              hi[key] = COLOR_UTIL.interpolate256(color, target, 1 - invert[i_key])
    parent.attach = __Invert
  def value(parent, replacement = None):
    if replacement != None:
      parent._value = replacement
      return parent
    return parent._value

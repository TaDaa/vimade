import sys
M = sys.modules[__name__]

from vimade.v2.style.value import condition as CONDITION

GLOBALS = None

def __init(args):
  global GLOBALS
  GLOBALS = args['GLOBALS']
M.__init = __init


M.exclude_names = {}
M.exclude_id = 1
# @param **kwargs {
#  names: ['Folded', 'VertSplit', 'Normal', ...], # list of names that should be skipped on the style array
#  style: [Fade(0.4)] # style to run on all names that aren't excluded
# }
class Exclude():
  def __init__(self, **kwargs):
    _condition = kwargs.get('condition')
    _condition = _condition if _condition != None else CONDITION.INACTIVE
    _names = kwargs.get('names', [])
    class __Exclude():
      def __init__(self, win, state):
        self.win = win
        self.condition = None
        self.names = []
        self.style = [s.attach(win, state) for s in kwargs.get('style', [])]
        self.exclude = {}
        self._animating = False
      def before(self, win, state):
        self.condition = _condition(self, state) if callable(_condition) else _condition
        if self.condition == False:
          return
        names = self.names = _names(self, state) if callable(_names) else _names
        self.exclude = exclude = {}
        if type(names) == str:
          names = [names]
        for name in names:
          name_id = M.exclude_names.get(name)
          if not name_id:
            M.exclude_names[name] = name_id = str(M.exclude_id)
            M.exclude_id += 1
          exclude[name] = name_id
        for s in self.style:
          s.before(win, state)
      def key(self, win, state):
        if self.condition == False:
          return ''
        style_key = ','.join([s.key(win, state) for j, s in enumerate(self.style)])
        if len(style_key) == 0:
          return ''
        return 'E-' + ','.join(self.exclude.values()) + '(' \
            + style_key + ')'
      def modify(self, hl, to_hl):
        if self.condition == False or (hl['name'] in self.exclude):
          return
        else:
          for s in self.style:
            s.modify(hl, to_hl)
    self.attach = __Exclude

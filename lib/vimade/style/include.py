import sys
M = sys.modules[__name__]

from vimade.style.value import condition as CONDITION

GLOBALS = None

def __init(args):
  global GLOBALS
  GLOBALS = args['GLOBALS']
M.__init = __init


M.include_names = {}
M.include_id = 1
# @param config = {
#  'names': ['Folded', 'VertSplit', 'Normal', ...], # list of names that should be skipped on the style array
#  'style': [Fade(0.4)] # style to run on all names that are include
# }
class Include():
  def __init__(self, **kwargs):
    _condition = kwargs.get('condition')
    _condition = _condition if _condition != None else CONDITION.INACTIVE
    _names = kwargs.get('names', [])
    class __Include():
      def __init__(self, win, state):
        self.win = win
        self.condition = None
        self._condition = _condition
        self.names = []
        self.style = [s.attach(win, state) for s in kwargs.get('style', [])]
        self.include = {}
        self._animating = False
      def before(self, win, state):
        self.condition = _condition(self, state) if callable(_condition) else _condition
        if self.condition == False:
          return
        names = self.names = _names(self, state) if callable(_names) else _names
        self.include = include = {}
        if type(names) == str:
          names = [names]
        for name in names:
          name_id = M.include_names.get(name)
          if not name_id:
            M.include_names[name] = name_id = str(M.include_id)
            M.include_id += 1
          include[name] = name_id
        for s in self.style:
          s.before(win, state)
      def key(self, win, state):
        if self.condition == False:
          return ''
        style_key = ','.join([s.key(win, state) for j, s in enumerate(self.style)])
        if len(style_key) == 0:
          return ''
        return 'I-' + ','.join(self.include.values()) + '(' \
            + style_key + ')'
      def modify(self, hl, to_hl):
        if self.condition == False:
          return
        # we don't need to foce set the bg,ctermbg here for Vim as targetting works slightly differently
        if hl['name'] in self.include:
          for s in self.style:
            s.modify(hl, to_hl)
    self.attach = __Include

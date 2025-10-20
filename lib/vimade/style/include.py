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
#  'value': ['Folded', 'VertSplit', 'Normal', ...], # list of names that should be skipped on the style array
#  'style': [Fade(0.4)] # style to run on all names that are include
# }
class Include():
  def __init__(self, **kwargs):
    _condition = kwargs.get('condition')
    _condition = _condition if _condition != None else CONDITION.INACTIVE
    _names = kwargs.get('value', [])
    self.tick = kwargs.get('tick')
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
        style_keys = [s.key(win, state) for j, s in enumerate(self.style)]
        style_key = ','.join([s for s in style_keys if s])
        if not style_key:
          return ''
        return 'I-' + ','.join(self.include.values()) + '(' \
            + style_key + ')'
      def modify(self, highlights, to_hl):
        if self.condition == False:
          return
        highlights_for_children = {}
        for name in self.include:
          if name in highlights:
            highlights_for_children[name] = highlights[name]
        for s in self.style:
          s.modify(highlights_for_children, to_hl)
        for (name, value) in highlights_for_children.items():
          highlights[name] = value
    self.attach = __Include

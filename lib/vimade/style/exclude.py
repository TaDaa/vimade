import sys
M = sys.modules[__name__]

from vimade.style.value import condition as CONDITION

GLOBALS = None

def __init(args):
  global GLOBALS
  GLOBALS = args['GLOBALS']
M.__init = __init


M.exclude_names = {}
M.exclude_id = 1
# @param **kwargs {
#  value: ['Folded', 'VertSplit', 'Normal', ...], # list of names that should be skipped on the style array
#  style: [Fade(0.4)] # style to run on all names that aren't excluded
# }
class Exclude():
  def __init__(self, **kwargs):
    _condition = kwargs.get('condition')
    _condition = _condition if _condition != None else CONDITION.INACTIVE
    _names = kwargs.get('value', [])
    self.tick = kwargs.get('tick')
    class __Exclude():
      def __init__(self, win, state):
        self.win = win
        self._condition = _condition
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
        style_keys = [s.key(win, state) for j, s in enumerate(self.style)]
        style_key = ','.join([s for s in style_keys if s])
        if not style_key:
          return ''
        return 'E-' + ','.join(self.exclude.values()) + '(' \
            + style_key + ')'
      def modify(self, highlights, to_hl):
        if self.condition == False:
          return
        else:
          excluded_for_children = {}
          for name in self.exclude:
            if name in highlights:
              excluded_for_children[name] = highlights[name]
              del highlights[name]
          for s in self.style:
            s.modify(highlights, to_hl)
          for (name, value) in excluded_for_children.items():
            highlights[name] = value
    self.attach = __Exclude

import sys
M = sys.modules[__name__]

GLOBALS = None

def __init(globals):
  global GLOBALS
  GLOBALS = globals
M.__init = __init


M.exclude_names = {}
M.exclude_id = 1
# @param config = {
#  'names': ['Folded', 'VertSplit', 'Normal', ...], # list of names that should be skipped on the style array
#  'style': [Fade(0.4)] # style to run on all names that aren't excluded
# }
class Exclude():
  def __init__(self, config):
    class __Exclude():
      def __init__(self, win):
        self.win = win
        self.names = config['names']
        self.style = [s.attach(win) for s in config['style']]
        self.exclude = {}
      def before(self):
        names = self.names
        self.exclude = exclude = {}
        input = names(self.win) if callable(names) else names
        if type(input) == str:
          input = [input]
        for name in input:
          name_id = M.exclude_names.get(name)
          if not name_id:
            M.exclude_names[name] = name_id = str(M.exclude_id)
            M.exclude_id += 1
          exclude[name] = name_id
        for s in self.style:
          s.before()
      def key(self, i):
        return 'E-' + ','.join(self.exclude.values()) + '(' \
            + ','.join([s.key(j) for j, s in enumerate(self.style)]) + ')'
      def modify(self, hl, to_hl):
        if hl['name'] in self.exclude:
          return
        else:
          for s in self.style:
            s.modify(hl, to_hl)
    self.attach = __Exclude

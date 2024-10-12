import sys
M = sys.modules[__name__]

GLOBALS = None

def __init(globals):
  global GLOBALS
  GLOBALS = globals
M.__init = __init


M.include_names = {}
M.include_id = 1
# @param config = {
#  'names': ['Folded', 'VertSplit', 'Normal', ...], # list of names that should be skipped on the style array
#  'style': [Fade(0.4)] # style to run on all names that are include
# }
class Include():
  def __init__(self, config):
    class __Include():
      def __init__(self, win):
        self.win = win
        self.names = config['names']
        self.style = [s.attach(win) for s in config['style']]
        self.include = {}
      def before(self):
        self.include = include = {}
        names = self.names
        input = names(win) if callable(names) else names
        if type(input) == str:
          input = [input]
        for name in input:
          name_id = M.include_names.get(name)
          if not name_id:
            M.include_names[name] = name_id = str(M.include_id)
            M.include_id += 1
          include[name] = name_id
        for s in self.style:
          s.before()
      def key(self, i):
        return 'I-' + ','.join(self.include.values()) + '(' \
            + ','.join([s.key(j) for j, s in enumerate(self.style)]) + ')'
      def modify(self, hl, to_hl):
        if hl['name'] in self.include:
          for s in self.style:
            s.modify(hl, to_hl)
    self.attach = __Include

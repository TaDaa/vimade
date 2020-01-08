class WinState:
  def __init__(self, id, window, hasActiveBuffer = False, hasActiveWindow = False):
    self.win = window
    self.id = id
    self.diff = False
    self.wrap = False
    self.number = None
    self.height = None
    self.width = None
    self.hasActiveBuffer = hasActiveBuffer
    self.hasActiveWindow = hasActiveWindow
    self.matches = []
    self.invalid = False
    self.cursor = (-1, -1)
    self.buffer = None
    self.tab = None
    self.buftype = None
    self.faded = False
    self.is_minimap = False
    self.is_explorer = False
    self.syntax =  None
    self.clear_syntax = False
    self.name = ''

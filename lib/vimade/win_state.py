class WinState:
  def __init__(self, id, window, hasActiveBuffer = False, hasActiveWindow = False):
    self.win = window
    self.id = id
    self.diff = False
    self.wrap = False
    self.number = window.number
    self.height = window.height
    self.width = window.width
    self.hasActiveBuffer = hasActiveBuffer
    self.hasActiveWindow = hasActiveWindow
    self.matches = []
    self.invalid = False
    self.cursor = (window.cursor[0], window.cursor[1])
    self.buffer = window.buffer.number
    self.tab = window.tabpage.number
    self.buftype = None
    self.faded = False
    self.is_minimap = False
    self.syntax =  None
    self.clear_syntax = False

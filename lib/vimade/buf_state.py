class BufState:
  def __init__(self, bufnr):
    self.coords = {}
    self.last = ''
    self.faded = 0
    self.bufnr = bufnr
    self.signs = []

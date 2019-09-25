class BufState:
  def __init__(self, bufnr):
    self.coords = None
    self.last = ''
    self.faded = 0
    self.bufnr = bufnr


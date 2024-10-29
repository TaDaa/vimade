import sys
M = sys.modules[__name__]

M.IN = 'in'
M.OUT = 'out'
def IN_OUT(style, state):
  if style.win.nc == True:
    return M.OUT
  else:
    return M.IN

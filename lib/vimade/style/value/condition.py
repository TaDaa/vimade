# TODO represent these as behaviors
def ACTIVE (style, state):
  return style.win.nc != True or style._animating == True

def INACTIVE (style, state):
  return style.win.nc == True or style._animating == True

def ALL (style, state):
  return True

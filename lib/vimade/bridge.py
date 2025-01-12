from vimade import fader as FADER

def setup(**kwargs):
  return FADER.setup(**kwargs)

def getInfo():
  return FADER.getInfo()

def disable():
  FADER.disable()

def invalidate():
  # distinction between buffer and signs invalidation is not needed, this basically just mean
  # recheck the screen.
  FADER.invalidate()

def recalculate():
  FADER.recalculate()

def update():
  FADER.tick()

def animate():
  FADER.animate()

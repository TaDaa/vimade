from vimade.v2 import fader as FADER

def setup(config):
  return FADER.setup(config)

def getInfo():
  return FADER.getInfo()

def detectTermColors():
  #  TODO: NOT HAPPENING. Remove from v1 as well
  pass

def unhighlightAll():
  FADER.unhighlightAll()

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

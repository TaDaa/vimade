from vimade.v2 import fader as FADER

def getInfo():
  #  TODO
  pass

def detectTermColors():
  #  TODO: NOT HAPPENING. Remove from v1 as well
  pass

def unfadeAll():
  FADER.unfadeAll()

def softInvalidateBuffer(bufnr):
  # distinction between buffer and signs is not needed, this basically just mean
  # recheck the screen.
  FADER.invalidate()
  pass

def softInvalidateSigns():
  # distinction between buffer and signs is not needed, this basically just mean
  # recheck the screen.
  FADER.invalidate()
  pass

def recalculate():
  FADER.recalculate()
  pass

def update():
  FADER.tick()

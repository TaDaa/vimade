from vimade.v2 import fader as FADER

def getInfo():
  #  TODO
  pass

def detectTermColors():
  #  TODO: NOT HAPPENING. Remove from v1 as well
  pass

def unfadeAll():
  #  TODO
  pass

def fadeSigns(bufnr):
  #  TODO
  pass

def unfadeSigns(bufnr):
  #  TODO
  pass

def softInvalidateBuffer(bufnr):
  #  TODO
  pass

def softInvalidateSigns():
  #  TODO
  pass

def recalculate():
  FADER.recalculate()
  pass

def update():
  FADER.tick()

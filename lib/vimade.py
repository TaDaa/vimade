import terminal
import signs
import fader
import global_state as GLOBALS

def getInfo():
  return GLOBALS.getInfo()

def detectTermColors():
  terminal.detectColors()

def unfadeAll():
  fader.unfadeAll()

def fadeSigns(bufnr):
  signs.fade_bufs([bufnr])

def unfadeSigns(bufnr):
  signs.unfade_bufs([bufnr])

def softInvalidateBuffer(bufnr):
  fader.softInvalidateBuffer(bufnr)

def update(nextState = None):
  fader.update(nextState)

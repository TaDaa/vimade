import sys
M = sys.modules[__name__]

from vimade.v2.util import ipc as IPC

FADER = None
GLOBALS = None

M.scheduled = False
M.animating = False
M.queued_windows = {}

def __init(args):
  global FADER
  global GLOBALS
  FADER = args['FADER']
  GLOBALS = args['GLOBALS']
  FADER.on('tick:before', _tick_before)
  FADER.on('tick:after', _tick_after)

def _tick_before():
  if M.scheduled == True:
    M.scheduled = False
    M.animating = True

def _tick_after():
  if M.animating == True:
    M.animating = False
  if M.scheduled == True:
    IPC.eval_and_return('vimade#StartAnimationTimer()')

def schedule(win):
  if not win.winid in queued_windows:
    queued_windows[win.winid] = True
    M.scheduled = True

def refresh():
  only_these_windows = M.queued_windows
  M.queued_windows = {}
  return only_these_windows

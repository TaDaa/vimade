import sys
from vimade.v2.util import ipc as IPC
M = sys.modules[__name__]

M.queued_windows = {}

def schedule(win):
  if not win.winid in queued_windows:
    queued_windows[win.winid] = True
  # we batch this for later (no reason to invoke immediately)
  IPC.batch_eval_and_return('vimade#StartAnimationTimer()')

def refresh():
  only_these_windows = M.queued_windows
  M.queued_windows = {}
  return only_these_windows

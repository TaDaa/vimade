import sys
import time
M = sys.modules[__name__]

import vim
from vimade.v2 import animator as ANIMATOR
from vimade.v2 import highlighter as HIGHLIGHTER
from vimade.v2 import signs as SIGNS
from vimade.v2.state import globals as GLOBALS
from vimade.v2.state import win as WIN_STATE
from vimade.v2.util import ipc as IPC

def _pairs(input):
  if type(input) == list:
    return enumerate(input)
  elif type(input) == dict:
    return input.items()

def _return_to_win():
  current_winid = int(IPC.eval_and_return('win_getid()'))
  start_winid = GLOBALS.current['winid']
  if current_winid != start_winid:
    vim.command('noautocmd call win_gotoid(%d)' % (start_winid))

def _update(only_these_windows):
  # start_time = time.time()
  windows = IPC.eval_and_return('getwininfo()')
  fade_windows = GLOBALS.fade_windows
  fade_buffers = not fade_windows
  current = GLOBALS.current
  updated_cache = {}

  # if highlights are invalidated at the global level, we need to 
  if (GLOBALS.RECALCULATE & GLOBALS.tick_state) > 0:
    HIGHLIGHTER.clear_base_cache()
    HIGHLIGHTER.create_vimade_0()
    unfadeAll(windows)


  for wininfo in windows:
    # we skip only_these_windows here because we need to know who the active window is
    # for linking and other ops
    if current['winid'] == int(wininfo['winid']):
      WIN_STATE.refresh_active(wininfo)
      break
    
  for wininfo in windows:
    if current['tabnr'] == int(wininfo['tabnr']) and current['winid'] != int(wininfo['winid']) and \
        (not only_these_windows or only_these_windows.get(int(wininfo['winid']))):
          WIN_STATE.refresh(wininfo)

  def next(val):
    def complete(val):
      # delta = time.time() - start_time
      # if delta * 1000 > 3:
         # print('d', delta*1000)
      pass
    WIN_STATE.cleanup(windows)
    _return_to_win()
    # start_time = time.time()
    SIGNS.flush().then(complete)

  IPC.flush_batch().then(next)


def _after_promise(val):
  _return_to_win()

def setup(config):
  return GLOBALS.setup(config)

def getInfo():
  return GLOBALS.getInfo()

def recalculate():
  tick(GLOBALS.RECALCULATE | GLOBALS.INVALIDATE_HIGHLIGHTS | GLOBALS.CHANGED)

def invalidate():
  tick(GLOBALS.CHANGED)

def tick(tick_state = GLOBALS.READY, only_these_windows = None):
  GLOBALS.refresh(tick_state)
  last_ei = vim.options['ei']
  vim.options['ei'] = 'all'

  # if the tick_state changed during an animation, we need to use that frame
  # to sync the windows
  if GLOBALS.tick_state > 0 and only_these_windows:
    only_these_windows = None

  _update(only_these_windows)
  vim.options['ei'] = last_ei

def animate():
  only_these_windows = ANIMATOR.refresh()
  tick(GLOBALS.READY, only_these_windows)


def unfadeAll(windows = None):
  if windows == None:
    windows = IPC.eval_and_return('getwininfo()')
  for wininfo in windows:
    WIN_STATE.unfade(int(wininfo['winid']))
  SIGNS.flush()

import sys
import time
M = sys.modules[__name__]

import vim
from vimade.v2.state import globals as GLOBALS
from vimade.v2 import highlighter as HIGHLIGHTER
from vimade.v2.state import win as WIN_STATE
from vimade import util as UTIL

def _pairs(input):
  if type(input) == list:
    return enumerate(input)
  elif type(input) == dict:
    return input.items()

def _fade(win, updated_cache):
  if not updated_cache.get(win.winid) and win.ns:
    updated_cache[win.winid] = True
    win.ns.fade()

def _unfade(win):
  if win.ns:
    win.ns.unfade()

def _invalidate(win):
  if win.ns:
    win.ns.invalidate()

def _return_to_win():
  current_winid = int(UTIL.eval_and_return('win_getid()'))
  start_winid = GLOBALS.current['winid']
  if current_winid != start_winid:
    cmd = ('| let g:vimade_cmd="noautocmd vert resize ".winwidth(".") |  noautocmd set winwidth=' + str(GLOBALS.winwidth) + ' | execute g:vimade_cmd')
    vim.command('noautocmd call win_gotoid(%d) %s' % (start_winid, cmd))

def _update():
  windows = UTIL.eval_and_return('getwininfo()')
  fade_windows = GLOBALS.fade_windows
  fade_buffers = not fade_windows
  current = GLOBALS.current
  updated_cache = {}
  for i, wininfo in _pairs(windows):
    wininfo['winid'] = int(wininfo['winid'])
    wininfo['winnr'] = int(wininfo['winnr'])
    wininfo['bufnr'] = int(wininfo['bufnr'])
    wininfo['tabnr'] = int(wininfo['tabnr'])
    if current['winid'] == wininfo['winid']:
      win = WIN_STATE.from_current(wininfo)
      if (GLOBALS.INVALIDATE & GLOBALS.tick_state > 0) or (WIN_STATE.INVALIDATE & win.modified > 0):
        _invalidate(win)
      if (GLOBALS.CHANGED & GLOBALS.tick_state) > 0 or (WIN_STATE.CHANGED & win.modified) > 0:
        if win.faded:
          _fade(win, updated_cache)
        else:
          _unfade(win)
      break
    
  for i, wininfo in _pairs(windows):
    wininfo['winid'] = int(wininfo['winid'])
    wininfo['winnr'] = int(wininfo['winnr'])
    wininfo['bufnr'] = int(wininfo['bufnr'])
    wininfo['tabnr'] = int(wininfo['tabnr'])
    if current['tabnr'] == wininfo['tabnr'] and current['winid'] != wininfo['winid']:
      win = WIN_STATE.from_other(wininfo)
      if (GLOBALS.INVALIDATE & GLOBALS.tick_state > 0) or (WIN_STATE.INVALIDATE & win.modified > 0):
        _invalidate(win)
      if (GLOBALS.CHANGED & GLOBALS.tick_state) > 0 or (WIN_STATE.CHANGED & win.modified) > 0:
        if win.faded:
          _fade(win, updated_cache)
        else:
          _unfade(win)

  WIN_STATE.cleanup(windows)
  _return_to_win()


# recalculate is likely too difficult to implement in this new setup
def recalculate():
  windows = UTIL.eval_and_return('getwininfo()')
  current = GLOBALS.current
  updated_cache = {}

  for i, wininfo in _pairs(windows):
    win = WIN_STATE.get(wininfo)
    if win != None:
      pass
        #  TODO

def tick():
  # start_time = time.time()
  GLOBALS.refresh()
  last_ei = vim.options['ei']
  vim.options['ei'] = 'all'

  if GLOBALS.RECALCULATE & GLOBALS.tick_state > 0:
    M.recalculate()

  _update()
  vim.options['ei'] = last_ei
  # delta = time.time() - start_time
  # time looks great about 0.1ms on average even with 8k screen filled with 9k loc windows
  # with fademode windows enabled
  # if delta > 1:
    # print(delta)

def unfadeAll():
  print('TODO')

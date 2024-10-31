import sys
import time
M = sys.modules[__name__]

import vim
from vimade.util.promise import Promise, all
from vimade.style.value import animate as ANIMATE
from vimade import animator as ANIMATOR
from vimade.style import exclude as EXCLUDE
from vimade.style import fade as FADE
from vimade.style import tint as TINT
from vimade.style import include as INCLUDE
from vimade import highlighter as HIGHLIGHTER
from vimade import signs as SIGNS
from vimade.state import globals as GLOBALS
from vimade.state import win as WIN_STATE
from vimade.util import ipc as IPC

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
  promise = Promise()
  # start_time = time.time()
  windows = IPC.eval_and_return('getwininfo()')
  current = GLOBALS.current
  current_promise = None
  other_promises = []
  updated_cache = {}

  # if highlights are invalidated at the global level, we need to 
  if (GLOBALS.RECALCULATE & GLOBALS.tick_state) > 0:
    HIGHLIGHTER.clear_base_cache()
    HIGHLIGHTER.create_vimade_0()
    unhighlightAll(windows)


  for wininfo in windows:
    # we skip only_these_windows here because we need to know who the active window is
    # for linking and other ops
    # python is a bit tricker because the diff window hl overrides the default
    # we get around this refreshing the active, but not determining its end state
    # we then complete the end state after all other windows have been refreshed
    if current['winid'] == int(wininfo['winid']):
      current_promise = WIN_STATE.refresh_active(wininfo)
      break
    
  for wininfo in windows:
    if current['tabnr'] == int(wininfo['tabnr']) and current['winid'] != int(wininfo['winid']) and \
        (not only_these_windows or only_these_windows.get(int(wininfo['winid']))):
          other_promises.append(WIN_STATE.refresh(wininfo))

  def finish(not_current_win):
    for win in not_current_win:
      win.finish()
    current_promise.then(lambda win: win.finish())
  all(other_promises).then(finish)

  def next(val):
    def complete(val):
      promise.resolve(None)
      # delta = time.time() - start_time
      # if delta * 1000 > 3:
         # print('d', delta*1000)
      pass
    WIN_STATE.cleanup(windows)
    _return_to_win()
    # start_time = time.time()
    SIGNS.flush().then(complete)

  IPC.flush_batch().then(next)
  return promise

def _after_promise(val):
  _return_to_win()

_callbacks = {}
def on(name, callback):
  callbacks = _callbacks.get(name)
  if not callbacks:
    _callbacks[name] = callbacks = []
  callbacks.append(callback)

def notify(name):
  callbacks = _callbacks.get(name)
  if callbacks:
    for callback in callbacks:
      callback()

def setup(**kwargs):
  return GLOBALS.setup(**kwargs)

def getInfo():
  return GLOBALS.getInfo()

def recalculate():
  tick(GLOBALS.RECALCULATE | GLOBALS.INVALIDATE_HIGHLIGHTS | GLOBALS.CHANGED)

def invalidate():
  tick(GLOBALS.CHANGED)

def tick(tick_state = GLOBALS.READY, only_these_windows = None):
  last_ei = vim.options['ei']
  vim.options['ei'] = 'all'
  notify('tick:before')
  GLOBALS.refresh(tick_state)

  # if the tick_state changed during an animation, we need to use that frame
  # to sync the windows
  if GLOBALS.tick_state > 0 and only_these_windows:
    only_these_windows = None

  def after_update(v):
    notify('tick:after')
  _update(only_these_windows).then(after_update)


  vim.options['ei'] = last_ei

def animate():
  only_these_windows = ANIMATOR.refresh()
  tick(GLOBALS.READY, only_these_windows)


def unhighlightAll(windows = None):
  if windows == None:
    windows = IPC.eval_and_return('getwininfo()')
  for wininfo in windows:
    WIN_STATE.unhighlight(int(wininfo['winid']))
  SIGNS.flush()

M.ANIMATE.__init({'FADER': M, 'GLOBALS': GLOBALS})
M.ANIMATOR.__init({'FADER': M, 'GLOBALS': GLOBALS})
M.FADE.__init({'FADER': M, 'GLOBALS': GLOBALS})
M.TINT.__init({'FADER': M, 'GLOBALS': GLOBALS})
M.EXCLUDE.__init({'FADER': M, 'GLOBALS': GLOBALS})
M.INCLUDE.__init({'FADER': M, 'GLOBALS': GLOBALS})
M.IPC.__init({'FADER': M, 'GLOBALS': GLOBALS})
M.WIN_STATE.__init({'FADER': M, 'GLOBALS': GLOBALS})

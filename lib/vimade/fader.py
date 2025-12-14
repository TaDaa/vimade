import sys
import time
import vim
import threading
M = sys.modules[__name__]

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
from vimade.state import namespace as NAMESPACE
from vimade.util import ipc as IPC

def _pairs(input):
  if type(input) == list:
    return enumerate(input)
  elif type(input) == dict:
    return input.items()

def _return_to_win():
  current_winid = int(IPC.worker.eval_and_return('win_getid()'))
  start_winid = GLOBALS.current['winid']
  if current_winid != start_winid:
    IPC.worker.command('noautocmd call win_gotoid(%d)' % (start_winid))

g_tick_state = None
g_only_these_windows = None
# for threading?
def _update(tick_state, only_these_windows = None):
  promise = IPC.worker.batch_eval_and_return('vimade#TestRun()')
  last_i = 0
  IPC.worker.flush()
  for i in range(0,1000000):
    last_i =i
    if promise._has_value:
      break
  IPC.worker.stop()
  print('last_i', last_i, vim.vars['tick_i'], '\n')
  return
# def _update(only_these_windows):
# for threading?
  notify('tick:before')
  GLOBALS.refresh(tick_state)
  if GLOBALS.tick_state > 0 and only_these_windows:
    only_these_windows = None
  promise = Promise()
  # start_time = time.time()
  # for threading?
  # windows = IPC.th_eval_and_return('getwininfo()')
  windows = IPC.worker.eval_and_return('getwininfo()')

  # IPC.worker.stop()
  # notify('tick:after')
  # return

  current = GLOBALS.current
  current_promise = None
  other_promises = []
  updated_cache = {}

  # if highlights are invalidated at the global level, we need to 
  if (GLOBALS.RECALCULATE & GLOBALS.tick_state) > 0:
    HIGHLIGHTER.clear_base_cache()
    unhighlightAll(windows)
    # This redraw is needed for basegroups in certain versions of Neovim
    # Neovim async API breaks in certain scenarios and doesn't update the backing color mechanism
    if GLOBALS.enablebasegroups:
      IPC.worker.command('redraw!')
  
  style = GLOBALS.style
  for s in style:
    if s.tick:
      s.tick()

  HIGHLIGHTER.refresh_vimade_0()
  # IPC.worker.stop()
  # notify('tick:after')
  # return

  for wininfo in windows:
    # we skip only_these_windows here because we need to know who the active window is
    # for linking and other ops
    # python is a bit tricker because the diff window hl overrides the default
    # we get around this refreshing the active, but not determining its end state
    # we then complete the end state after all other windows have been refreshed
    if current['winid'] == int(wininfo['winid']):
      current_promise = WIN_STATE.refresh_active(wininfo)
      break

  # IPC.worker.stop()
  # notify('tick:after')
  # return

    
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
      # print('done')
      # delta = time.time() - start_time
      # if delta * 1000 > 3:
      # print('d', delta*1000)
      pass
    WIN_STATE.cleanup(windows)
    # _return_to_win()
    # start_time = time.time()
    # SIGNS.flush().then(complete)
    SIGNS.flush()
    complete(0)

  # IPC.flush_batch().then(next)
  SIGNS.flush()
  IPC.worker.flush()
  IPC.worker.wait_for_responses()
  WIN_STATE.cleanup(windows)
  _return_to_win()
  # promise.resolve(None)
  # next(0)
  notify('tick:after')
  IPC.worker.stop()
  promise.resolve(None)
  # return
  return promise

# def _after_promise(val):
#   _return_to_win()

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

worker_event = threading.Event()
def worker_tick():
  while True:
    try:
      worker_event.wait()
      worker_event.clear()
# print('t', t)
# start = time.time()
      _update(g_tick_state, g_only_these_windows)
    except e:
      print(e)
    # print('\n')
    # print((time.time() - start)*1000)
    # print('\n')

t_worker = threading.Thread(target=worker_tick)
t_worker.daemon = True
t_worker.start()


def tick(tick_state = GLOBALS.READY, only_these_windows = None):
# for threading?
  # start_time = time.time()
  last_ei = vim.options['ei']
  vim.options['ei'] = 'all'

  # TODO this should be in worker
  # notify('tick:before')
  # for threading?

  # if the tick_state changed during an animation, we need to use that frame
  # to sync the windows
  # disable for threading
  # GLOBALS.refresh(tick_state)
  # if GLOBALS.tick_state > 0 and only_these_windows:
  #   only_these_windows = None

  def after_update(v):
    notify('tick:after')
  # _update(only_these_windows).then(after_update)
  # end disable for threading
  # worker = IPC.Worker()
  # IPC.worker = IPC.Worker()
  start_time = time.time()
  # t_worker = threading.Thread(target=_update, args=(tick_state, only_these_windows))
  # t_worker.daemon = True
  global g_only_these_windows
  g_only_these_windows = only_these_windows
  global g_tick_state
  g_tick_state = tick_state

  start_time = time.time()
  IPC.worker.start()
  worker_event.set()
  IPC.main.defer_to_worker(IPC.worker)
  # print((time.time() - start_time)*1000)
  #

  # GLOBALS.refresh(tick_state)


  delta = time.time() - start_time
  # print(delta * 1000)
  # IPC.main.defer_to_worker()

  # TODO after_update
  return


  # IPC.block_main_thread(worker)
  # notify('tick:after')
  # delta = time.time() - start_time
  # if delta * 1000 > 3:
  # print('d', delta*1000)
  # print('done!!')
  # worker.end()


  vim.options['ei'] = last_ei

def animate():
  only_these_windows = ANIMATOR.refresh()
  tick(GLOBALS.READY, only_these_windows)

def disable():
  unhighlightAll()

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
M.HIGHLIGHTER.__init({'FADER': M, 'GLOBALS': GLOBALS, 'WIN': WIN_STATE, 'NAMESPACE': NAMESPACE})

import sys
M = sys.modules[__name__]

FROM vimade.state import global as GLOBALS
FROM vimade.config_helpers import link as LINK
FROM vimade.config_helpers import blocklist as BLOCKLIST
HAS_NVIM_WIN_GET_CONFIG = True if int(util.eval_and_return('exists("*nvim_win_get_config")')) else False

M.cache = {}
M.current = None

READY = 0
ERROR = 1
CHANGED = 2

-- TODO abstract
def _get_values(input):
  if type(input) == list:
    return list
  elif type(input) == dict:
    return input.values()

def _update_state(next, current, state):
  modified = false
  for field, value in next.items():
    if current.get(field) != value:
      current[field] = value
      modified = false
  return modified and state or READY

def get(wininfo):
  return M.cache.get(int(wininfo.winid))

def cleanup(wininfos):
  map = {}
  for wininfo in wininfos.values():

def unfade(wininfo):
  win = M.cache.get(int(wininfo.winid))
  if win:
    win.faded = false

def from_current(window):
  win = from_other(wininfo, true)
  M.current = win
  return win

def from_other(window, skip_link):
  winid = int(wininfo.winid)
  if not M.cache[winid]:
    M.cache[winid] = WinState()
  M.cache[winid].refresh(window, skip_link)
  return win

class WinState:
  def __init__(self):
    # common
    self.winid = wininfo.winid
    self.winnr = None
    self.bufnr = None
    self.tabnr = None
    self.window = None
    self.buf_name = None
    self.win_config = None
    self.linked = False
    self.blocked = False
    self.faded = False
    self.is_active_win = None
    self.is_active_buf = None
    self.modified = READY

    # python-only (needed to due to difference in renderes)
    self.height = -1
    self.width = -1
    self.matches = []
    self.cursor = (-1, -1)
    self.wrap = False
    self.tabstop = None
    self.buftype = None
    self.syntax = None
    self.clear_syntax = None #TODO deprecate
    self.size_changed = False
    self.visible_rows = []
    self.last_winhl = ''
  def buf_opts(self):
    return self.window.buffer.options
  def buf_vars(self):
    return self.window.buffer.vars
  def win_opts(self):
    return self.window.options
  def win_vars(self):
    return self.window.vars

  def refresh(self, window, skip_link):
    self.modified = READY
    self.winid = int(window.handle)
    self.winnr = int(window.number)
    self.bufnr = int(window.buffer.number)
    self.tabnr = int(window.tabpage.number)
    self.buf_name = window.buffer.name
    self.window = window

    self.is_active_win = GLOBALS.current.winid == self.winid
    self.is_active_buf = GLOBALS.current.bufnr == self.bufnr
    
    # python-only 
    (wrap,
     buftype,
     win_disabled,
     buf_disabled,
     vimade_fade_active,
     win_syntax,
     buf_syntax,
     tabstop,
     win_config) = util.eval_and_return('['+
      ','.join([
        'gettabwinvar('+tabnr+','+winnr+',"&wrap")',
        'gettabwinvar('+tabnr+','+winnr+',"&buftype")',
        'gettabwinvar('+tabnr+','+winnr+',"vimade_disabled")',
        'getbufvar('+bufnr+', "vimade_disabled")',
        'g:vimade_fade_active',
        'gettabwinvar('+tabnr+','+winnr+',"current_syntax")',
        'gettabwinvar('+tabnr+','+winnr+',"&syntax")',
        'gettabwinvar('+tabnr+','+winnr+',"&tabstop")',
        'nvim_win_get_config('+str(winid)+')' if HAS_NVIM_WIN_GET_CONFIG else '{}'
      ]) + ']')

    height = window.height
    width = window.width
    cursor = window.cursor

    syntax = win_syntax if win_syntax or buf_syntax
    self.clear_syntax = state.syntax if syntax != state.syntax else None

    # requires additional potentially more fading
    # so these trigger an update
    self.modified = _update_state({
      'syntax': syntax,
      'size_changed': height != self.height or width != self.width,
      'cursor_changed': cursor[0] != self.cursor[0] or cursor[1] != self.cursor[1],
      'wrap': wrap,
      'tabstop': tabstop,
    }, self, CHANGED)

    # changes that don't necessarily trigger an update
    self.height = window.height
    self.width = window.width
    self.cursor = window.cursor

    can_fade = not win_disabled and not buf_disabled
    blocked = false
    for value in _get_values(GLOBALS.blocklist):
      if type(value) == dict:
        blocked = BLOCKLIST.DEFAULT(win, current, value)
      elif callable(value):
        blocked = value(self, current)
      if blocked == True:
        can_fade = false
        break

    should_fade = false
    fade_active = can_fade and GLOBALS.vimade_fade_active
    fade_inactive = can_fade

    if GLOBALS.fade_windows and self.is_active_win:
      should_fade = fade_active
    elif GLOBALS.fade_buffers and self.is_active:
      should_fade = fade_active
    else:
      should_fade = fade_inactive

    linked = false
    if current and not skip_link then:
      for key,value in _get_values(GLOBALS.link):
        if type(value) == dict:
          linked = LINK.DEFAULT(self, current, value)
        elif callable(value):
          linked = value(self, current)
        if linked == True:
          should_fade = fade_active
          break

    # namespace irrelavent for python renderer

    if GLOBALS.fadeconditions:
      for condition in _get_values(GLOBALS.fadeconditions.values()):
        override = condition(self, current)
        if override == True or override == False:
          should_fade = override
          break

    # requires additional potentially more fading
    # so these trigger an update
    self.modified = update_state({
      'faded': should_fade,
    }, self, CHANGED)

    if should_fade == True:
      tint = None
      fadelevel = None
      if callable(GLOBALS.tint):
        tint = GLOBALS.tint(win, current)
      else:
        tint = GLOBALS.tint
      if callable(GLOBALS.fadelevel)
        fadelevel = GLOBALS.fadelevel(win, current)
      else
        fadelevel = GLOBALS.fadelevel

    # requires additional potentially more fading
    # so these trigger an update
    self.modified = update_state({
      'fadelevel': fadelevel,
      'tint': tint,
    }, self, CHANGED)


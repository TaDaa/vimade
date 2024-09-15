import sys
M = sys.modules[__name__]

import vim

from vimade.v2.state import globals as GLOBALS
from vimade.v2.state import namespace as NAMESPACE
from vimade.v2.config_helpers import link as LINK
from vimade.v2.config_helpers import blocklist as BLOCKLIST
from vimade.v2 import colors as COLORS
from vimade import util
HAS_NVIM_WIN_GET_CONFIG = True if int(util.eval_and_return('exists("*nvim_win_get_config")')) else False

M.cache = {}
M.current = None

READY = 0
ERROR = 1
CHANGED = 2
INVALIDATE = 4


# TODO abstract
def _get_values(input):
  if type(input) == list:
    return list
  elif type(input) == dict:
    return input.values()

def _update_state(next, current, state):
  modified = False
  for field, value in next.items():
    if current[field] != value:
      current[field] = value
      modified = True
  return modified and state or READY

def get(wininfo):
  return M.cache.get(int(wininfo['winid']))

def cleanup(wininfos):
  map = {}
  for wininfo in wininfos:
    map[wininfo['winid']] = True
  cache_keys = [key for key in cache.keys()]
  for winid in cache_keys:
    if not winid in map:
      cache[winid].cleanup()

def unfade(wininfo):
  win = M.cache.get(wininfo['winid'])
  if win:
    win.faded = False

def from_current(wininfo):
  win = from_other(wininfo, True)
  M.current = win
  return win

def from_other(wininfo, skip_link = False):
  winid = wininfo['winid']
  if not M.cache.get(winid):
    M.cache[winid] = WinState(wininfo)
  win = M.cache[winid]
  win.refresh(wininfo, skip_link)
  return win

class WinState:
  def __init__(self, wininfo):
    self.__internal = {
      # common
      'winid': wininfo['winid'],
      'winnr': None,
      'bufnr': None,
      'tabnr': None,
      'window': None,
      'buf_name': None,
      'win_config': None,
      'linked': False,
      'blocked': False,
      'faded': False,
      'fadelevel': None,
      'fadepriority': -1,
      'tint': None,
      'is_active_win': None,
      'is_active_buf': None,
      'modified': READY,

      # python-only (needed to due to difference in renderes)
      'coords_key': None,
      'hi_key': None,
      'ns': None,
      'height': -1,
      'width': -1,
      'matches': [],
      'cursor': (-1, -1),
      'wrap': False,
      'tabstop': None,
      'buftype': None,
      'syntax': None,
      'clear_syntax': None, #todo deprecate,
      'size_changed': False,
      'cursor_changed': False,
      'wincolorhl_changed': False,
      'is_explorer': False,
      'is_minimap': False,
      'topline': -1,
      'botline': -1,
      'textoff': -1,
      'wincolor': None,
      'wincolorhl': [],
      'winhl': '',
      'original_wincolor': '',
      'original_winhl': '',
    }
  def __getattr__(self, key):
    if key == '__internal':
      return self.__internal
    else:
      return self.__internal[key]
  def __getitem__(self, key):
    if key == '__internal':
      return self.__internal
    else:
      return self.__internal[key]
  def __setitem__(self, key, value):
    self.__internal[key] = value
  def buf_opts(self):
    window = self.get_window()
    return window.buffer.options if window else {}
  def buf_vars(self):
    window = self.get_window()
    return window.buffer.vars if window else {}
  def win_opts(self):
    window = self.get_window()
    return window.options if window else {}
  def win_vars(self):
    window = self.get_window()
    return window.vars if window else {}
  def cleanup(self):
    del M.cache[self.winid]
    if self.ns:
      self.ns.cleanup()
  def get_buffer(self):
    try:
      return vim.buffers[self.bufnr]
    except:
      return None
  def get_window(self):
    try:
      if self.window:
        return self.window
      if not self.window:
        for tabpage in vim.tabpages:
          if tabpage.number == self.tabnr:
            for window in tabpage.windows:
              if window.number == self.winnr:
                self.window = window
    except:
      return None
    return None

  # TODO self-manage window
  def refresh(self, wininfo, skip_link):
    self.modified = READY
    self.winid = winid = wininfo['winid']
    self.winnr = winnr = wininfo['winnr']
    self.tabnr = tabnr = wininfo['tabnr']
    self.bufnr = bufnr = wininfo['bufnr']

    window = self.get_window()
    if window == None:
      return

    self.buf_name = window.buffer.name
    if not self.ns:
      self.ns = NAMESPACE.Namespace(self)
    self.ns.refresh()

    self.is_active_win = GLOBALS.current['winid'] == self.winid
    self.is_active_buf = GLOBALS.current['bufnr'] == self.bufnr
    
    if GLOBALS.is_nvim:
      wincolor = 'Normal' if self.is_active_win else 'NormalNC'
    else:
      wincolor = (util.eval_and_return( \
             'gettabwinvar(%d,%d,"&wincolor")' % (tabnr, winnr)))

    self.wincolor = wincolor
    if wincolor.startswith('vimade_'):
      wincolor = self.original_wincolor or 'Normal'
    else:
      self.original_wincolor = wincolor
    
    if GLOBALS.is_nvim:
      wincolorhl_eval = ('vimade#GetNvimHi(hlID("%s") ?? hlID("Normal"))' % (wincolor or 'Normal'))
      normalhl_eval = 'vimade#GetNvimHi(hlID("Normal"))'
    else:
      wincolorhl_eval = ('vimade#GetHi(hlID("%s") ?? hlID("Normal"))' % (wincolor or 'Normal'))
      normalhl_eval = 'vimade#GetHi(hlID("Normal"))'


    # python-only 
    (wrap,
     buftype,
     win_disabled,
     buf_disabled,
     vimade_fade_active,
     win_syntax,
     buf_syntax,
     tabstop,
     normalhl,
     wincolorhl,
     winhl, #(local winhl)
     win_config) = util.eval_and_return('['+
      ','.join([
        'gettabwinvar(%d,%d,"&wrap")' % (tabnr, winnr),
        'gettabwinvar(%d,%d,"&buftype")' % (tabnr, winnr),
        'gettabwinvar(%d,%d,"vimade_disabled")' % (tabnr, winnr),
        'getbufvar(%d, "vimade_disabled")' % bufnr,
        'g:vimade_fade_active',
        'gettabwinvar(%d,%d,"current_syntax")' % (tabnr, winnr),
        'gettabwinvar(%d,%d,"&syntax")' % (tabnr, winnr),
        'gettabwinvar(%d,%d,"&tabstop")' % (tabnr, winnr),
        normalhl_eval,
        wincolorhl_eval,
        'gettabwinvar(%d,%d,"&winhl")' % (tabnr, winnr),
        'nvim_win_get_config('+str(winid)+')' if HAS_NVIM_WIN_GET_CONFIG else '{}',
      ]) + ']')
    is_explorer = 'coc-explorer' in self.buf_name or 'NERD' in self.buf_name
    is_minimap = 'vim-minimap' in self.buf_name or '-MINIMAP-' in self.buf_name

    if winhl.find('vimade_') == -1:
      # TODO free highlights, new matches, and synID (current behavior)
      self.modified |= _update_state({
        'original_winhl': winhl
      }, self, CHANGED |  INVALIDATE)

    self.winhl = winhl

    height = window.height
    width = window.width
    cursor = window.cursor

    syntax = win_syntax if win_syntax else buf_syntax

    normalhl = COLORS.convertHi(normalhl)
    if normalhl[0] == None:
      normalhl[0] = 255 if GLOBALS.is_dark else 0
    if normalhl[1] == None:
      normalhl[0] = 0 if GLOBALS.is_dark else 255
    if normalhl[2] == None:
      normalhl[2] = 0xFFFFFF if GLOBALS.is_dark else 0x0
    if normalhl[3] == None:
      normalhl[3] = 0x0 if GLOBALS.is_dark else 0xFFFFFF
    if normalhl[4] == None:
      normalhl[4] = normalhl[2]

    wincolorhl = COLORS.convertHi(wincolorhl, normalhl)

    wincolorhl_changed = len(wincolorhl) != len(self.wincolorhl)
    if not wincolorhl_changed:
      for i, hl in enumerate(wincolorhl):
        if self.wincolorhl[i] != hl:
          wincolorhl_changed = True
          break

    # requires additional potentially more fading
    # so these trigger an update
    self.modified |= _update_state({
      'syntax': syntax,
      'size_changed': height != self.height or width != self.width,
      'cursor_changed': cursor[0] != self.cursor[0] or cursor[1] != self.cursor[1],
      'wrap': wrap,
      'tabstop': int(tabstop),
      'is_explorer': is_explorer,
      'is_minimap': is_minimap,
      'topline': int(wininfo['topline']),
      'botline': int(wininfo['botline']),
      'textoff': int(wininfo['textoff']),
    }, self, CHANGED)

    # changes that don't necessarily trigger an update
    self.height = window.height
    self.width = window.width
    self.cursor = window.cursor
    self.wincolorhl = wincolorhl

    can_fade = not win_disabled and not buf_disabled
    blocked = False
    for value in _get_values(GLOBALS.blocklist):
      if type(value) == dict:
        blocked = BLOCKLIST.DEFAULT(self, current, value)
      elif callable(value):
        blocked = value(self, current)
      if blocked == True:
        can_fade = False
        break

    should_fade = False
    fade_active = can_fade and GLOBALS.vimade_fade_active
    fade_inactive = can_fade

    if GLOBALS.fade_windows and self.is_active_win:
      should_fade = fade_active
    elif GLOBALS.fade_buffers and self.is_active_buf:
      should_fade = fade_active
    else:
      should_fade = fade_inactive

    linked = False
    if current and not skip_link:
      for value in _get_values(GLOBALS.link):
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
    self.modified |= _update_state({
      'faded': should_fade == True,
    }, self, CHANGED)

    if should_fade == True:
      tint = None
      fadelevel = None
      if callable(GLOBALS.tint):
        tint = GLOBALS.tint(self, current)
      else:
        tint = GLOBALS.tint
      if callable(GLOBALS.fadelevel):
        fadelevel = GLOBALS.fadelevel(self, current)
      else:
        fadelevel = GLOBALS.fadelevel

      # requires additional potentially more fading
      # so these trigger an update
      # TODO these are free highlights and add new matches
      # SynID not required
      self.modified |= _update_state({
        'fadelevel': float(fadelevel),
        'tint': tint,
      }, self, INVALIDATE | CHANGED)

    # force the window to refresh if fademode='windows' -- caching
    # will handle the rest
    if GLOBALS.fade_windows and not self.is_active_win and self.is_active_buf and self.faded:
      self.modified |= CHANGED


    # buffers manage the collected synID()'s so that we don't need to reprocess
    # these should only change if the syntax has changed (this can happen)
    # per window, using :help ownsyntax
    coords_key = syntax 

    # hi_key is used by the highlighter for replacement highlights.  These are
    # calculated based on a number of window criteria such as fadelevel, tint
    # wincolor.

    wincolor_key = '-'.join([str(x if x != None else 'N') for x in wincolorhl])
    hi_key = wincolor_key + ':' + str(self.fadelevel) + ':' + COLORS.get_tint_key(self.tint)

    # INVALIDATE matches to be readded, free highlights, and get new synID
    # TODO separate free highlights, synID, and matching into separate parts
    # (would reduce the work to do)
    self.modified |= _update_state({
      'hi_key': hi_key,
      'coords_key': coords_key,
      'syntax': syntax,
      'fadepriority': 9 if is_minimap else GLOBALS.fadepriority,
      'wincolorhl_changed': wincolorhl_changed,
    }, self, INVALIDATE | CHANGED)



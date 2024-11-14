import sys
import time
M = sys.modules[__name__]

import vim

from vimade import highlighter as HIGHLIGHTER
from vimade.state import globals as GLOBALS
from vimade.state import namespace as NAMESPACE
from vimade.config_helpers import link as LINK
from vimade.config_helpers import blocklist as BLOCKLIST
from vimade.util import color as COLOR_UTIL
from vimade.util import ipc as IPC
from vimade.util.promise import Promise,all

IS_NVIM = GLOBALS.is_nvim
FADER = None
M.cache = {}
M.current = None
M.diffs = 0
M.links = 0

def __init(args):
  global FADER
  FADER = args['FADER']
  def before():
    M.current = None
    M.links = 0
    M.diffs = 0
  FADER.on('tick:before', before)
M.__init = __init

class WinDeps(Promise):
  def __init__(self, win, is_active):
    Promise.__init__(self)
    self.win = win
    self.wincolor = None
    self.winhl = ''
    self.is_active = is_active
    self.get()

  def _apply_win_color(self):
    win = self.win
    if IS_NVIM:
      def set_winhl(value):
        self.winhl = value
        if len(value):
          for group in value.split(','):
            (source, target) = group.split(':')
            if source == 'Normal' and win.is_active_win:
              self.wincolor = target
              break
            elif source == 'NormalNC' and not win.is_active_win:
              self.wincolor = target
              break
        if self.wincolor == None:
          self.wincolor = 'Normal' if win.is_active_win else 'NormalNC'
      return IPC.batch_eval_and_return('gettabwinvar(%d,%d,"&winhl")'%(win.tabnr, win.winid)).then(set_winhl)
    else:
      def set_wincolor(value):
        self.wincolor = value
      return IPC.batch_eval_and_return('gettabwinvar(%d,%d,"&wincolor")'%(win.tabnr, win.winnr)).then(set_wincolor)
  def _apply_remaining_config(self):
    def next(config):
      config.append(self.wincolor)
      self.resolve(config)

    win = self.win
    winid = win.winid
    tabnr = win.tabnr
    winnr = win.winnr
    bufnr = win.bufnr

    all([
        IPC.batch_eval_and_return('['+
        ','.join([
          'gettabwinvar(%d,%d,"&wrap")' % (tabnr, winnr),
          'gettabwinvar(%d,%d,"&buftype")' % (tabnr, winnr),
          'gettabwinvar(%d,%d,"vimade_disabled")' % (tabnr, winnr),
          'getbufvar(%d, "vimade_disabled")' % bufnr,
          'getbufvar(%d, "&diff")' % bufnr,
          'gettabwinvar(%d,%d,"current_syntax")' % (tabnr, winnr),
          'gettabwinvar(%d,%d,"&syntax")' % (tabnr, winnr),
          'gettabwinvar(%d,%d,"&tabstop")' % (tabnr, winnr),
          'gettabwinvar(%d,%d,"&conceallevel")' % (tabnr, winnr),
          'nvim_win_get_config('+str(winid)+')' if HAS_NVIM_WIN_GET_CONFIG else '{}',
          'win_gettype('+str(winid)+')' if HAS_WIN_GETTYPE else '""',
        ]) + ']'),
       Promise().resolve(self.winhl),
       HIGHLIGHTER.get_hl_for_ids(self.win, [self.wincolor or GLOBALS.normalid, GLOBALS.normalid])\
     ]).then(next)
  def get(self):
    def next(val):
      self._apply_remaining_config()
    result = self._apply_win_color()
    if type(result) == Promise:
      result.then(next)
    else:
      next(None)
    return self


# TODO move these into features
HAS_NVIM_WIN_GET_CONFIG = True if int(IPC.eval_and_return('exists("*nvim_win_get_config")')) else False
HAS_NVIM_GET_HL_NS = True if int(IPC.eval_and_return('exists("*nvim_get_hl_ns")')) else False
HAS_WIN_GETTYPE = True if int(vim.eval('exists("*win_gettype")')) else False

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
  return state if modified else GLOBALS.READY

def get(wininfo):
  return M.cache.get(int(wininfo['winid']))

def cleanup(wininfos):
  map = {}
  for wininfo in wininfos:
    map[int(wininfo['winid'])] = True
  cache_keys = [key for key in cache.keys()]
  for winid in cache_keys:
    if not winid in map:
      cache[winid].cleanup()

def unhighlight(winid):
  win = M.cache.get(winid)
  if win:
    # set to a value that forces the window to have changed state (non-bool)
    win.nc = None
    if win.ns:
      win.ns.unhighlight()

def refresh_active(wininfo):
  return refresh(wininfo, True)

def refresh(wininfo, is_active = False):
  winid = int(wininfo['winid'])
  win = M.cache.get(winid)
  if not win:
    win = M.cache[winid] = WinState(wininfo)
  if is_active:
    M.current = win
  return win.refresh(wininfo, is_active)

class WinState(object):
  def __init__(self, wininfo):
    self.__internal = {
      # common
      'winid': int(wininfo['winid']),
      'winnr': None,
      'bufnr': None,
      'tabnr': None,
      'buf_name': None,
      'win_config': None,
      'win_type': None,
      'buf_vars': None,
      'buf_opts': None,
      'win_vars': None,
      'win_opts': None,
      'win_config': None,
      'basebg': None,
      'linked': False,
      'blocked': False,
      'nc': False,
      'should_nc': False,
      'fadelevel': None,
      'matchpriority': -1,
      'tint': None,
      'is_active_win': None,
      'is_active_buf': None,
      'state': GLOBALS.READY,
      'style': [],
      'style_active': 0,
      'style_state': {
        'animations': {},
        'custom': {},
      },
      'timestamps': {
        'active_win': 0,
        'active_buf': 0,
        'nc': 0,
      },
      '_global_style': [],
      # python-only (needed to due to difference in renderes)
      'diff': None,
      'window': None,
      'buffer': None,
      'coords_key': None,
      'hi_key': None,
      'ns': None,
      'height': -1,
      'width': -1,
      'matches': [],
      'cursor': (-1, -1),
      'wrap': False,
      'conceallevel': 0,
      'tabstop': None,
      'buftype': None,
      'syntax': None,
      'size_changed': False,
      'cursor_changed': False,
      'is_explorer': False,
      'is_minimap': False,
      'topline': -1,
      'botline': -1,
      'textoff': -1,
      'wincolor': None,
      'wincolorhl': {'id':-1, 'name': '', 'ctermfg': None, 'ctermbg': None, 'fg': None, 'bg': None, 'sp': None},
      'winhl': '',
      'original_wincolor': '',
      'original_winhl': '',
      'vimade_winhl': None,
    }
  def __getattribute__(self, key):
    if key == '_WinState__internal':
      return object.__getattribute__(self, key)
    elif not key in self.__internal:
      return object.__getattribute__(self, key)
    else:
      return object.__getattribute__(self, '_WinState__internal')[key]
  def __setattr__(self, key, value):
    if key == '_WinState__internal':
      object.__setattr__(self, key, value)
    else:
      object.__getattribute__(self, '_WinState__internal')[key] = value
    return value
  def __getitem__(self, key):
    if key == '__internal':
      return self.__internal
    else:
      return self.__internal[key]
  def __setitem__(self, key, value):
    self.__internal[key] = value
  def cleanup(self):
    del M.cache[self.winid]
    if self.ns:
      self.ns.cleanup()
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
                return self.window
    except:
      return None
    return None

  def refresh(self, wininfo, is_active):
    self.state = GLOBALS.READY
    self.winid = winid = int(wininfo['winid'])
    self.winnr = winnr = int(wininfo['winnr'])
    self.tabnr = tabnr = int(wininfo['tabnr'])
    self.bufnr = bufnr = int(wininfo['bufnr'])

    is_active_win = GLOBALS.current['winid'] == self.winid
    is_active_buf = GLOBALS.current['bufnr'] == self.bufnr

    if is_active_win != self.is_active_win:
      self.is_active_win = is_active_win
      self.timestamps['active_win'] = GLOBALS.now
    if is_active_buf != self.is_active_buf:
      self.is_active_buf = is_active_buf
      self.timestamps['active_buf'] = GLOBALS.now

    window = self.get_window()
    if window == None:
      return

    self.buffer = window.buffer
    self.buf_name = self.buffer.name

    if not self.ns:
      self.ns = NAMESPACE.Namespace(self)
    self.ns.refresh()

    def next(config):
      self.apply_async_config(config, wininfo, is_active)
      promise.resolve(self)

    promise = Promise()
    WinDeps(self, is_active).then(next)
    return promise
     

  def apply_async_config(self, config, wininfo, is_active):
    ((wrap,
         buftype,
         win_disabled,
         buf_disabled,
         diff,
         win_syntax,
         buf_syntax,
         tabstop,
         conceallevel,
         win_config,
         win_type,
     ),
     winhl,
     (wincolorhl, normalhl),
     wincolor
     ) = config

    window = self.window
    height = window.height
    width = window.width
    cursor = window.cursor
    syntax = win_syntax if win_syntax else buf_syntax

    self.win_config = win_config
    self.win_type = win_type
    self.buf_vars = self.buffer.vars
    self.buf_opts = self.buffer.options
    self.win_vars = self.window.vars
    self.win_opts = self.window.options
    self.diff = bool(int(diff))
    self.wincolor = wincolor

    if self.diff:
      M.diffs += 1

    was_vimade_wincolor = False
    if wincolor.startswith('vimade_'):
      wincolor = self.original_wincolor or ('NormalNC' if (IS_NVIM and self.is_active_win) else 'Normal')
      # this can happen because vim passes the wincolor over to new splits, not sure why it does this
      # but requires special handling otherwise target bg color is unknown
      if not self.original_wincolor:
        self.original_wincolor = wincolor # (based on the condition above this would be a Normal type)
        wincolorhl = normalhl
      else:
        was_vimade_wincolor = True
    else:
      self.original_wincolor = wincolor or ('NormalNC' if (IS_NVIM and self.is_active_win) else 'Normal')

    if not 'vimade_' in winhl:
      if self.original_winhl != winhl:
        self.state |= _update_state({
          'original_winhl': winhl
        }, self, GLOBALS.CHANGED |  GLOBALS.INVALIDATE_HIGHLIGHTS)
        self.vimade_winhl = None
    else:
      self.vimade_winhl = winhl
    self.winhl = winhl

    is_explorer = 'coc-explorer' in self.buf_name or 'NERD' in self.buf_name
    is_minimap = 'vim-minimap' in self.buf_name or '-MINIMAP-' in self.buf_name

    wincolorhl = HIGHLIGHTER.defaultWincolorHi(wincolorhl, normalhl)

    if not was_vimade_wincolor:
      self.wincolorhl = wincolorhl
    else:
      wincolorhl = self.wincolorhl


    # requires additional potentially more fading
    self.state |= _update_state({
      'syntax': syntax,
      'size_changed': height != self.height or width != self.width,
      'cursor_changed': cursor[0] != self.cursor[0] or cursor[1] != self.cursor[1],
      'wrap': int(wrap),
      'tabstop': int(tabstop),
      'is_explorer': is_explorer,
      'is_minimap': is_minimap,
      'conceallevel': int(conceallevel),
      'topline': int(wininfo['topline']),
      'botline': int(wininfo['botline']),
      'textoff': int(wininfo['textoff']),
    }, self, GLOBALS.CHANGED)


    # changes that don't necessarily trigger an update
    self.height = window.height
    self.width = window.width
    self.cursor = window.cursor

    can_nc = not win_disabled and not buf_disabled
    blocked = False
    for value in _get_values(GLOBALS.blocklist):
      if type(value) == dict:
        blocked = BLOCKLIST.DEFAULT(self, current, value)
      elif callable(value):
        blocked = value(self, current)
      if blocked == True:
        can_nc = False
        break

    should_nc = False
    hi_active = can_nc and GLOBALS.vimade_fade_active
    hi_inactive = can_nc

    if GLOBALS.nc_windows and self.is_active_win:
      should_nc = hi_active
    elif GLOBALS.nc_buffers and self.is_active_buf:
      should_nc = hi_active
    else:
      should_nc = hi_inactive

    linked = False
    if current and not is_active:
      for value in _get_values(GLOBALS.link):
        if type(value) == dict:
          linked = LINK.DEFAULT(self, current, value)
        elif callable(value):
          linked = value(self, current)
        if linked == True:
          should_nc = hi_active
          M.links += 1
          break

    self.blocked = blocked
    self.linked = linked

    if (should_nc and not self.nc) or (not should_nc and self.nc):
      self.timestamps['nc'] = GLOBALS.now

    self.should_nc = should_nc

    # buffers manage the collected synID()'s so that we don't need to reprocess
    # these should only change if the syntax has changed (this can happen)
    # per window, using :help ownsyntax
    coords_key = syntax 

    self.state |= _update_state({
      'coords_key': coords_key,
      'syntax': syntax,
    }, self, GLOBALS.INVALIDATE_BUFFER_CACHE | GLOBALS.INVALIDATE_HIGHLIGHTS | GLOBALS.CHANGED)

  def finish(self):
    should_nc = self.should_nc

    if M.current == self and M.links > 0:
      self.linked = True

    if self.blocked or (M.links > 0 and M.diffs > 1 and self.linked):
      self.should_nc = should_nc = False
      self.blocked = True

    self.state |= _update_state({
      'nc': self.should_nc == True,
    }, self, GLOBALS.CHANGED)

    basebg = GLOBALS.basebg
    basebg_key = ''
    if callable(basebg):
      basebg = basebg(win, M.current)
    if basebg:
      basebg = COLOR_UTIL.to24b(basebg)
      basebg_key = 'bg(' + str(basebg) + ')'
    self.basebg = basebg if type(basebg) == int else None

    rerun_style = False
    style = self.style
    global_style = GLOBALS.style
    _global_style = self._global_style
    if len(_global_style) != len(global_style):
      rerun_style = True
    else:
      for i, s in enumerate(global_style):
        if _global_style[i] != s:
          rerun_style = True
          break
    if rerun_style == True:
      self.style = style = []
      self._global_style = _global_style =  []
      for s in global_style:
        _global_style.append(s)
        style.append(s.attach(self, self.style_state))

    hi_key = ''
    style_active = 0

    if self.blocked == False:
      for i, s in enumerate(style):
        s.before(self, self.style_state)
        style_key = s.key(self, self.style_state)
        if len(style_key) > 0:
          if style_active > 0:
            hi_key = hi_key + '#'
          hi_key = hi_key + style_key
          style_active += 1

    # TODO ensure this stays as is, signsretentionperiod is essentially based off win/buf change
    if self.nc == True:
      if GLOBALS.enablesigns and (GLOBALS.signsretentionperiod or 0) > 0 and (GLOBALS.now - self.timestamps['nc']) * 1000 < GLOBALS.signsretentionperiod:
        self.state |= GLOBALS.SIGNS

    # hi_key is used by the highlighter for replacement highlights.  These are
    # calculated based on a number of window criteria such as fadelevel, tint
    # wincolor.

    hi_key = '-'.join([str(x if x != None else 'N') for x in self.wincolorhl.values()]) + ':' + hi_key + ':' + basebg_key

    # INVALIDATE matches to be readded, free highlights, and get new synID
    self.state |= _update_state({
      'hi_key': hi_key,
      'matchpriority': 9 if self.is_minimap else int(GLOBALS.matchpriority),
    }, self, GLOBALS.INVALIDATE_HIGHLIGHTS | GLOBALS.CHANGED)

    # force the window to refresh if ncmode='windows' -- caching mostly handles performance here
    # We also hi linked status when nc_windows is activated.  This handles scenarios where the user
    # is on the diff side, against a buffer shared amongst multiple windows.
    self.style_active = style_active

    if (self.is_active_buf or (self.linked and GLOBALS.nc_windows)):
      self.state |= GLOBALS.CHANGED

    state = (self.state | GLOBALS.tick_state)
    if self.ns:
      if (GLOBALS.INVALIDATE_HIGHLIGHTS & state) > 0:
        self.ns.invalidate_highlights((GLOBALS.CHANGED & state) > 0)
      if (GLOBALS.INVALIDATE_BUFFER_CACHE & state) > 0:
        self.ns.invalidate_buffer_cache()
      if (GLOBALS.CHANGED & state) > 0:
        if self.style_active > 0:
          self.ns.highlight()
        else:
          self.ns.unhighlight()
      # elif here because we don't need to trigger SIGNS if CHANGED already occurred
      elif (GLOBALS.SIGNS & state) > 0:
        if self.style_active > 0:
          self.ns.add_signs()
        else:
          self.ns.remove_signs()

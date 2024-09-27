import sys

import vim
from vimade.v2.config_helpers import tint as TINT
from vimade.v2.util import ipc as IPC
from vimade.v2.util import matchers as MATCHERS

MAX_TICK_ID = 1000000

_OTHER = {
  'vimade_fade_active': False,
  'is_dark': False
}
_CURRENT = {
  'winid': -1,
  'winnr': -1,
  'bufnr': -1,
  'tabnr': -1,
}
_DEFAULTS = {
  'basebg': None,
  'fademode': 'buffers',
  'tint': TINT.DEFAULT,
  'fadelevel': 0.4,
  'fademinimap': None,
  'groupdiff': True,
  'groupscrollbind': False,
  'fadeconditions': None,
  # link can be an array of objects or functions
  # objects are passed to the default handler
  # values can be Matchers
  # functions are passed (Win, ActiveWin, value)
  'link': {
    'default': {
      'buf_names': None,
      'buf_opts': None,
      'buf_vars': None,
      'win_opts': None,
      'win_vars': None,
      'win_config': None,
    }
  },
  # link can be an array of objects or functions
  # objects are passed to the default handler
  # values can be Matchers
  # functions are passed (Win, ActiveWin, value)
  'blocklist': {
    'default': {
      'buf_names': None,
      'buf_opts': None,
      'buf_vars': None,
      'win_opts': None,
      'win_vars': None,
      'win_config': {
        'relative': True #block all floating windows # TODO we can make this more customized soon
       },
    }
  },
  # python only config
  'enabletreesitter': False,
  'enablebasegroups': False,
  'basegroups': [],
  'rowbufsize': 0,
  'colbufsize': 0,
  'enablescroll': True,
  'enablesigns': True,
  'signsid': 13100,
  'signspriority': 31,
  'signsretentionperiod': 4000,
}

class Globals(object):
  def __init__(self):
    # python specific
    (is_nvim,
     is_gui_running,
     original_background,
     features) = IPC.eval_and_return('['+','.join([
       'has("nvim")',
       'has("gui_running")',
       '&background',
       'g:vimade_features',
     ])+']')

    self.__internal = {
      'READY': 0,
      'ERROR': 1,
      'CHANGED': 2,
      'INVALIDATE_HIGHLIGHTS': 4,
      'INVALIDATE_BUFFER_CACHE': 8,
      'RECALCULATE': 16,
      'SIGNS': 32,

      'tick_id': 1000,
      'tick_state': 0,
      'vimade_fade_active': False,
      'basebg': None,
      'normalid': 0,
      'normalncid': 0,
      'fademode': 'buffers',
      'fadepriority': 0,
      'fade_windows': False,
      'fade_buffers': False,
      'tint': None,
      'fadelevel': 0,
      'fademinimap': False,
      'groupdiff': True,
      'groupscrollbind': False,
      'colorscheme': None,
      'is_dark': False,
      'current': {
          'winid': -1,
          'winnr': -1,
          'bufnr': -1,
          'tabnr': -1,
      },
      'fadeconditions': None,
      'link': {},
      'blocklist': {},
      'is_nvim': bool(int(is_nvim)),
      'is_term': bool(int(is_gui_running)) == False,
      'rowbufsize': None,
      'colbufsize': None,
      'enablescroll': False,
      'enablesigns': False,
      'enabletreesitter': False,
      'enablebasegroups': False,
      'basegroups': [],
      'signsretentionperiod': 0,
      'signsid': None,
      'signspriority': None,
      'winwidth': 20,
      'require_treesitter': False,
      'termguicolors': None,
    }
    self.vim = vim
    self.TINT = TINT
    self.IPC = IPC
    self.MATCHERS = MATCHERS
    self.MAX_TICK_ID = MAX_TICK_ID
    self._OTHER = _OTHER
    self._CURRENT = _CURRENT
    self._DEFAULTS = _DEFAULTS
    sys.modules[__name__] = self

  def __getattribute__(self, key):
    if key == '_Globals__internal':
      return object.__getattribute__(self, key)
    elif not key in self.__internal:
      return object.__getattribute__(self, key)
    else:
      return object.__getattribute__(self, '_Globals__internal')[key]
  def __setattr__(self, key, value):
    if key == '_Globals__internal':
      object.__setattr__(self, key, value)
    else:
      object.__getattribute__(self, '_Globals__internal')[key] = value
    return value

  def __getitem__(self, name):
    return self.__internal[name]

  def __setitem__(self, name, value):
    self.__internal[name] = value

  def _check_fields(self, fields, next, current, defaults, return_state):
    modified = False
    for field in fields:
      value = next.get(field, defaults.get(field))
      if current[field] != value:
        current[field] = value
        modified = True
    return return_state if modified else self.READY

  def _next_tick_id(self):
    tick_id = self.tick_id + 1
    if tick_id > self.MAX_TICK_ID:
      tick_id = 1000
    return tick_id

  def refresh(self, tick_state = 0):
    self.tick_id = self._next_tick_id()
    self.tick_state = tick_state
    (background,
      colorscheme,
      termguicolors,
      winwidth,
      vimade_fade_active,
      winid,
      winnr,
      bufnr,
      tabnr) = self.IPC.mem_safe_eval('['+','.join([
      '&background',
      'exists("g:colors_name") ? g:colors_name : ""',
      '&termguicolors',
      '&winwidth',
      'exists("g:vimade_fade_active") ? g:vimade_fade_active : ""',
      'win_getid()',
      'winnr()',
      'bufnr()',
      'tabpagenr()',
    ])+']')
    # we need the actual converted object here
    # for config
    vimade = self.vim.vars['vimade']
    

    current = {
      'winid': int(winid),
      'winnr': int(winnr),
      'bufnr': int(bufnr),
      'tabnr': int(tabnr)
    }

    self.tick_state |= self._check_fields([
      'is_dark',
      'colorscheme',
      'termguicolors'
    ], {
      'is_dark': background == 'dark',
      'colorscheme': colorscheme,
      'termguicolors': bool(int(termguicolors))
    }, self, self._OTHER, self.INVALIDATE_HIGHLIGHTS | self.RECALCULATE | self.CHANGED)

    # neovim only - no tricky
    if self.is_nvim:
      if int(vimade.get('enabletreesitter')) and not self.require_treesitter:
        vim.api.exec_lua("_vimade_legacy_treesitter = require('vimade_legacy_treesitter')", [])
        self.require_treesitter = 1
    else:
      vimade['enabletreesitter'] = 0
      vimade['enablebasegroups'] = 0

    self.tick_state |= self._check_fields([
      'normalid',
      'normalncid',
      'enablebasegroups',
      'fadepriority',
    ], vimade, self, self._DEFAULTS, self.INVALIDATE_HIGHLIGHTS | self.CHANGED)
    self.tick_state |= self._check_fields([
      'enabletreesitter'
    ], vimade, self, self._DEFAULTS, self.INVALIDATE_BUFFER_CACHE | self.INVALIDATE_HIGHLIGHTS | self.CHANGED)
    self.tick_state |= self._check_fields([
      'vimade_fade_active'
    ], {
      'vimade_fade_active': bool(int(vimade_fade_active))
    }, self, self._OTHER, self.CHANGED)
    self.tick_state |= self._check_fields([
      'fademode',
      'enablescroll',
      'colbufsize',
      'rowbufsize'
    ], vimade, self, self._DEFAULTS, self.CHANGED)
    self.tick_state |= self._check_fields([
      'winid',
      'winnr',
      'bufnr',
      'tabnr',
    ], current, self.current, self._CURRENT, self.READY) #TODO just set
    self.tick_state |= self._check_fields([
      'enablesigns'
    ], vimade, self, self._DEFAULTS, self.SIGNS)

    ## handled in win state
    self.basegroups = vimade.get('basegroups', self._DEFAULTS['basegroups'])
    self.signsid = int(vimade.get('signsid', self._DEFAULTS['signsid']))
    self.signspriority = int(vimade.get('signspriority', self._DEFAULTS['signspriority']))
    self.signsretentionperiod = int(vimade.get('signsretentionperiod', self._DEFAULTS['signsretentionperiod']))
    self.link = vimade.get('link', self._DEFAULTS['link']) # TODO this should be singlekey merge (allow users to override the default or add additional config)
    self.blocklist = vimade.get('blocklist', self._DEFAULTS['blocklist']) # TODO this should be singlekey merge (allow users to override the default or add additional config)
    self.basebg = vimade.get('basebg', self._DEFAULTS['basebg']) # TODO empty string needed? 
    self.groupdiff = bool(int(vimade.get('groupdiff', self._DEFAULTS['groupdiff'])))
    self.groupscrollbind = bool(int(vimade.get('groupscrollbind', self._DEFAULTS['groupscrollbind'])))
    self.fademinimap = bool(int(vimade.get('fademinimap', self._DEFAULTS['fademinimap'])))
    self.tint = vimade.get('tint', self._DEFAULTS['tint'])
    self.fadelevel = float(vimade.get('fadelevel', self._DEFAULTS['fadelevel']))
    if 'fadeconditions' in vimade:
      if type(vimade.fadeconditions) == dict or type(vimade.fadeconditions) == list:
        self.fadeconditions = vimade.fadeconditions
      elif callable(vimade.fadeconditions):
        self.fadeconditions = [vimade.fadeconditions]
      else:
        self.fadeconditions = vimade.fadeconditions

    ## already checked
    self.fade_windows = self.fademode == 'windows'
    self.fade_buffers = not self.fade_windows

M = Globals()
M.TINT.__init(M)

import sys
#  M = sys.modules[__name__]

import vim
from vimade import util
from vimade.v2.config_helpers import tint as TINT
from vimade.v2.util import matchers as MATCHERS

MAX_TICK_ID = 1000000


_OTHER = {
  'vimade_fade_active': False,
  'is_dark': False
}
_CURRENT = {
  'winid': -1,
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
      'win_config': None,
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

class Globals:
  def __init__(self):
    sys.modules[__name__] = self
    # python specific
    (is_nvim,
     is_gui_running,
     original_background,
     features) = util.eval_and_return('['+','.join([
       'has("nvim")',
       'has("gui_running")',
       '&background',
       'g:vimade_features',
     ])+']')

    self.__internal = {
      'READY': 0,
      'ERROR': 1,
      'RECALCULATE': 2,
      'CHANGED': 4,
      'INVALIDATE': 8,
      'SIGNS': 16,

      'tick_id': 0,
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

  def __getattr__(self, name):
    if name == '__internal':
      return self.__internal
    else:
      return self.__internal[name]

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
    if tick_id > MAX_TICK_ID:
      tick_id = 1
    return tick_id

  def refresh(self):
    self.tick_id = self._next_tick_id()
    self.tick_state = self.READY
    (vimade,
      background,
      colorscheme,
      termguicolors,
      winwidth,
      vimade_fade_active,
      winid,
      bufnr,
      tabnr) = util.mem_safe_eval('['+','.join([
      'g:vimade',
      '&background',
      'exists("g:colors_name") ? g:colors_name : ""',
      '&termguicolors',
      '&winwidth',
      'exists("g:vimade_fade_active") ? g:vimade_fade_active : ""',
      'win_getid()',
      'bufnr()',
      'tabpagenr()',
    ])+']')

    current = {
      'winid': int(winid),
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
      'termguicolors': termguicolors
    }, self, _OTHER, self.INVALIDATE | self.CHANGED)

    # neovim only - no tricky
    if self.is_nvim:
      if vimade.get('enabletreesitter') and not self.require_treesitter:
        vim.api.exec_lua("_vimade_legacy_treesitter = require('vimade_legacy_treesitter')", [])
        self.require_treesitter = 1
    else:
      vimade['enabletreesitter'] = 0
      vimade['enablebasegroups'] = 0

    self.tick_state |= self._check_fields([
      'normalid',
      'normalncid',
      'enablebasegroups',
    ], vimade, self, _DEFAULTS, self.RECALCULATE)
    self.tick_state |= self._check_fields([
      'fadepriority',
      'enabletreesitter'
    ], vimade, self, _DEFAULTS, self.INVALIDATE | self.CHANGED)
    self.tick_state |= self._check_fields([
      'vimade_fade_active'
    ], {
      'vimade_fade_active': vimade_fade_active
    }, self, _OTHER, self.CHANGED)
    self.tick_state |= self._check_fields([
      'fademode',
      'enablescroll',
      'colbufsize',
      'rowbufsize'
    ], vimade, self, _DEFAULTS, self.CHANGED)
    self.tick_state |= self._check_fields([
      'winid',
      'bufnr',
      'tabnr',
    ], current, self.current, _CURRENT, self.CHANGED)
    self.tick_state |= self._check_fields([
      'enablesigns'
    ], vimade, self, _DEFAULTS, self.SIGNS)

    ## handled in win state
    self.basegroups = vimade.get('basegroups', _DEFAULTS['basegroups'])
    self.signsid = vimade.get('signsid', _DEFAULTS['signsid'])
    self.signspriority = vimade.get('signspriority', _DEFAULTS['signspriority'])
    self.signsretentionperiod = vimade.get('signsretentionperiod', _DEFAULTS['signsretentionperiod'])
    self.link = vimade.get('link', _DEFAULTS['link'])
    self.blocklist = vimade.get('blocklist', _DEFAULTS['blocklist'])
    self.basebg = vimade.get('basebg', _DEFAULTS['basebg']) # TODO empty string needed? 
    self.groupdiff = bool(vimade.get('groupdiff', _DEFAULTS['groupdiff']))
    self.groupscrollbind = bool(vimade.get('groupscrollbind', _DEFAULTS['groupscrollbind']))
    self.fademinimap = bool(vimade.get('fademinimap', _DEFAULTS['fademinimap']))
    self.tint = vimade.get('tint', _DEFAULTS['tint'])
    self.fadelevel = vimade.get('fadelevel', _DEFAULTS['fadelevel'])
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

TINT.__init(Globals())

import sys
import time
import vim
from vimade.v2.recipe import default as DEFAULT_RECIPE
from vimade.v2.style.value import animate as ANIMATE
from vimade.v2.style.value import condition as CONDITION
from vimade.v2.style.value import direction as DIRECTION
from vimade.v2.style.value import ease as EASE
from vimade.v2.style import fade as FADE
from vimade.v2.style import tint as TINT
from vimade.v2.util import ipc as IPC
from vimade.v2.util import matchers as MATCHERS
from vimade.v2.util import type as TYPE

MAX_TICK_ID = 1000000000

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
_DEFAULTS = TYPE.extend(DEFAULT_RECIPE.Default(), {
  'basebg': None,
  'ncmode': 'buffers',
  'tint': None,
  'fadelevel': 0.4,
  'fademinimap': None,
  'groupdiff': True,
  'groupscrollbind': False,
  # link can be an array of objects or functions
  # objects are passed to the default handler
  # values can be Matchers
  # functions are passed (Win, ActiveWin, value)
  'link': {
    'default': {
      'buf_name': None,
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
      'buf_name': None,
      'buf_opts': {
        'buftype': ['popup', 'prompt']
      },
      'buf_vars': None,
      'win_opts': None,
      'win_vars': None,
      'win_type': True,
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
  'disablebatch': False,
})

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
      'features': features,
      'vimade_py': {},
      'tick_id': 1000,
      'tick_state': 0,
      'vimade_fade_active': False,
      'basebg': None,
      'normalid': 0,
      'normalncid': 0,
      'ncmode': 'buffers',
      'matchpriority': 0,
      'nc_windows': False,
      'nc_buffers': False,
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
      'disablebatch': False,
      'style': [],
      'now': None,
    }
    self.vim = vim
    self.time = time
    self.FADE = FADE
    self.TINT = TINT
    self.IPC = IPC
    self.MATCHERS = MATCHERS
    self.MAX_TICK_ID = MAX_TICK_ID
    self.TYPE = TYPE
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

  def setup(self, config):
    self.vimade_py = self.TYPE.deep_copy(config)

  def getInfo(self):
    info = self.__internal
    result = {'renderer': 'python-v2'}
    exclude = ['vim', 'time', 'TINT', 'IPC', '_OTHER', '_CURRENT', '_DEFAULTS']
    for name in info.keys():
      if name[:2] != '__' and not name in exclude:
        item = info[name]
        if item == None or isinstance(item, bool) or isinstance(item, int) or isinstance(item, float) or isinstance(item, str) or isinstance(item, dict) or isinstance(item, list):
          result[name] = item
    return result

  def refresh(self, tick_state = 0):
    self.tick_id = self._next_tick_id()
    self.tick_state = tick_state
    self.now = self.time.time()
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
    # we need the actual converted object here for config. This coercion is
    # required for consistency between nvim and vim.
    # some versions of vim return bytes instead of str
    # output of coerceTypes is essentially already a deep copy
    vimade = self.TYPE.shallow_extend(self.IPC.coerceTypes(self.vim.vars['vimade']), self.vimade_py)
    if 'fadepriority' in vimade and not 'matchpriority' in vimade:
      vimade['matchpriority'] = vimade['fadepriority']
    

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
      'is_dark': background == 'dark', # these settings trigger an initial RECALCULATE on load (this sets things like vimade_0)
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

    # coerce int here due to vim+python long issue
    vimade['normalid'] = int(vimade['normalid'])
    vimade['normalncid'] =  int(vimade['normalncid']) if vimade['normalncid'] != '' else None
    self.tick_state |= self._check_fields([
      'normalid',
      'normalncid',
      'enablebasegroups',
      'matchpriority',
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
      'ncmode',
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
    self.style = vimade.get('style', self._DEFAULTS['style'])
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
    self.disablebatch = bool(int(vimade.get('disablebatch', self._DEFAULTS['disablebatch'])))

    ## already checked
    self.nc_windows = self.ncmode == 'windows'
    self.nc_buffers = self.ncmode == 'buffers'
    # if you don't choose one of the above, everything is highlighted

M = Globals()

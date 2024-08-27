import sys
M = sys.modules[__name__]

from vimade import util
from vimade.config_helpers import tint as TINT
from vimade.util import matchers as MATCHERS

TINT.__init(M)

M.READY = 0
M.ERROR = 1
M.RECALCULATE = 2
M.UPDATE = 4
M.FULL_INVALIDATE = 8
M.SIGNS = 16
# M.UPDATE_BASEGROUPS = 32
# M.FULL_INVALIDATE = 8 TODO do we need this

MAX_TICK_ID = 1000000
def _next_tick_id():
  tick_id = M.tick_id + 1
  if tick_id > MAX_TICK_ID:
    tick_id = 1
  return tick_id

M.tick_id = 0
M.tick_state = READY
M.vimade_fade_active = False
M.basebg = None
M.normalid = 0
M.normalncid = 0
M.fademode = 'buffers'
M.fade_windows = False
M.fade_buffers = False
M.tint = None
M.fadelevel = 0
M.fademinimap = False
M.groupdiff = True
M.groupscrollbind = False
M.colorscheme = None
M.is_dark = False
M.current = {
  'winid': -1,
  'bufnr': -1,
  'tabnr': -1,
}
M.fadeconditions = None
M.link = {}
M.blocklist = {}

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
M.is_nvim = bool(is_nvim)
M.is_term = bool(is_gui_running) == False
M.rowbufsize = None
M.colbufsize = None
M.enablescroll = False
M.enablesigns = False
M.enabletreesitter = False
M.basegroups = []
M.signsretentionperiod = 0
M.signsid = None
M.signspriority = None
# bad code why is this here?
# M.signs_group_text = ' group=vimade ' if int(features['has_sign_group']) else ' '
# M.signs_priority_text = ' '
M.win_width = 20
# not state updating
M.require_treesitter = False
# TODO below prolly doesnt work in in win world
M.basegroups_faded = []
# end pythong specific


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
  'basegroups': [],
  'rowbufsize': 0,
  'colbufsize': 0,
  'enablescroll': True,
  'enablesigns': True,
  'signsid': 13100,
  'signspriority': 31,
  'signsretentionperiod': 4000,
}

def _check_fields(fields, next, current, defaults, return_state):
  modified = false
  for field in fields:
    value = next[field] 
    if value == None:
      value = defaults[field]
    if current[field] != value:
      current[field] = value
      modified = true
  return modified and return_state or M.READY

def refresh():
  M.tick_id = _next_tick_id()
  M.tick_state = M.READY
  current = {
  }

  (
    vimade,
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
    'winid': winid,
    'bufnr': bufnr,
    'tabnr': tabnr
  }

  M.tick_state |= check_fields([
    'normalid',
    'normalncid'
  ], vimade, M, _DEFAULTS, M.RECALCULATE)

  M.tick_state |= check_fields([
    'dark',
    'colorscheme'
    'termguicolors'
  ], {
    'is_dark': background == 'dark',
    'colorscheme': colorscheme,
    'termguicolors': termguicolors
  }, M, _OTHER, M.RECALCULATE)

  # neovim only - no tricky
  if is_nvim and vimade.enabletreesitter and not M.require_treesitter:
    vim.api.exec_lua("_vimade_legacy_treesitter = require('vimade_legacy_treesitter')", [])
    GLOBALS.require_treesitter = 1
  else:
    vimade.enabletreesitter = 0
  vimade.enabletreesitter = enabletreesitter and M.is_nvim
  M.tick_state |= check_fields([
    'fadepriority',
    'enabletreesitter'
  ], vimade, M, _DEFAULTS, M.FULL_INVALIDATE)

  M.tick_state |= check_fields([
    'vimade_fade_active'
  ], {
    'vimade_fade_active': vimade_fade_active
  }, M, _OTHER, M.UPDATE)

  M.tick_state |= check_fields([
    'fademode',
    'enablescroll',
    'colbufsize',
    'rowbufsize'
  ], vimade, M, _DEFAULTS, M.UPDATE)

  M.tick_state |= check_fields([
    'winid',
    'bufnr',
    'tabnr',
  ], current, M.current, _CURRENT, M.UPDATE)

  M.tick_state |= check_fields([
    'enablesigns'
  ], vimade, M, _DEFAULTS, M.SIGNS)

  ## handled in win state
  M.basegroups = vimade.basegroups or DEFAULTS.basegroups
  M.signsid = vimade.signsid
  M.signspriority = vimade.signspriority
  M.signsretentionperiod = vimade.signsretentionperiod
  M.link = vimade.link or DEFAULTS.link
  M.blocklist = vimade.blocklist or DEFAULTS.blocklist
  M.basebg = vimade.basebg if vimade.basebg != '' else DEFAULTS.basebg
  M.groupdiff = bool(vimade.groupdiff) if vimade.groupdiff != None else DEFAULTS.groupdiff
  M.groupscrollbind = bool(vimade.groupscrollbind) if vimade.groupscrollbind != None else DEFAULTS.groupscrollbind
  M.fademinimap = bool(vimade.fademinimap) if vimade.fademinimap != None else DEFAULTS.fademinimap
  M.tint = vimade.tint or DEFAULTS.tint
  M.fadelevel = vimade.fadelevel if vimade.fadelevel != None else DEFAULTS.fadelevel
  if type(vimade.fadeconditions) == dict or type(vimade.fadeconditions) == list:
    M.fadeconditions = vimade.fadeconditions
  elif callable(vimade.fadeconditions):
    M.fadeconditions = [vimade.fadeconditions]
  else:
    M.fadeconditions = vimade.fadeconditions

  ## already checked
  M.fade_windows = M.fademode == 'windows'
  M.fade_buffers = M.fademode == 'buffers'



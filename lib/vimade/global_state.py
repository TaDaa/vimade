import vim
import sys
from vimade import colors
from vimade.term_256 import RGB_256
from vimade import util

GLOBALS = sys.modules[__name__]

(is_nvim, is_term, original_background) = util.eval_and_return('[has("nvim"), has("gui_running"), &background]')
(term_fg, term_bg) = ('#FFFFFF','#000000') if 'dark' in original_background else ('#000000', '#FFFFFF')
features = util.eval_and_return('g:vimade_features')
is_nvim = int(is_nvim) == 1
is_term = int(is_term) == 0
fade_level = None
termguicolors = None
base_hi = [None, None, None, None, None]
base_fade256 = None
base_fade24b = None
background = None
colorscheme = None
row_buf_size = None
col_buf_size = None
fade_priority = None
fade_minimap = None
normal_id = None
normalnc_id = None
normal_bg256 = ''
normal_bg24b = ''
normal_fg256 = ''
normal_fg24b = ''
base_bg256 = ''
base_bg24b = ''
base_fg256 = ''
base_fg24b = ''
base_bg_exp256 = ''
base_bg_exp24b = ''
base_bg256_last = ''
base_bg24b_last = ''
base_fg256_last = '';
base_fg24b_last = '';
term_response = False
enable_scroll = False
enable_signs = False
enable_treesitter = False
basegroups = []
basegroups_faded = []
enable_basegroups = False
signs_retention_period = 0
signs_id = None
signs_priority = None
group_diff = None
group_scrollbind = None
signs_group_text = ' group=vimade ' if int(features['has_sign_group']) else ' '
signs_priority_text = ' '
require_treesitter = 0
win_width = 20


READY = 0
ERROR = 1
FULL_INVALIDATE = 2
RECALCULATE = 4
ENABLE_SIGNS = 8
DISABLE_SIGNS = 16
BASEGROUPS = 32

def getInfo():
  global_vars = vars(GLOBALS)
  result = {}
  exclude = ['READY', 'FULL_INVALIDATE', 'RECALCULATE', 'ERROR', 'RGB_256']
  for name in global_vars.keys():
    if name[:2] != '__' and not name in exclude:
      item = global_vars[name]
      if item == None or isinstance(item, bool) or isinstance(item, int) or isinstance(item, float) or isinstance(item, str) or isinstance(item, dict) or isinstance(item, list):
        result[name] = item
  return result

def update():
  returnState = READY
  allGlobals = util.mem_safe_eval('[g:vimade, &background, execute(":colorscheme"), &termguicolors, &winwidth]')
  nextGlobals = allGlobals[0]
  background = allGlobals[1]
  colorscheme = allGlobals[2]
  termguicolors = int(allGlobals[3]) == 1
  winwidth = allGlobals[4]
  basegroups = nextGlobals['basegroups']
  enablebasegroups = int(nextGlobals['enablebasegroups'])
  fadelevel = float(nextGlobals['fadelevel'])
  rowbufsize = int(nextGlobals['rowbufsize'])
  colbufsize = int(nextGlobals['colbufsize'])
  fadepriority = str(nextGlobals['fadepriority'])
  fademinimap = int(nextGlobals['fademinimap'])
  signsid = int(nextGlobals['signsid'])
  signspriority = nextGlobals['signspriority']
  signsretentionperiod = int(nextGlobals['signsretentionperiod'])
  basefg24b = basefg256 = nextGlobals['basefg']
  basebg24b = basebg256 = nextGlobals['basebg']
  normalid = nextGlobals['normalid']
  normalncid = nextGlobals['normalncid']
  enablesigns = int(nextGlobals['enablesigns'])
  enablescroll = int(nextGlobals['enablescroll'])
  enabletreesitter = int(nextGlobals['enabletreesitter']) if is_nvim else 0
  groupscrollbind = int(nextGlobals['groupscrollbind'])
  groupdiff = int(nextGlobals['groupdiff'])

  GLOBALS.fade_minimap = fademinimap
  GLOBALS.row_buf_size = rowbufsize
  GLOBALS.col_buf_size = colbufsize
  GLOBALS.signs_retention_period = signsretentionperiod
  GLOBALS.enable_scroll = enablescroll
  GLOBALS.group_scrollbind = groupscrollbind
  GLOBALS.group_diff = groupdiff
  GLOBALS.win_width = winwidth

  if GLOBALS.signs_id == None:
    GLOBALS.signs_id = signsid
  if GLOBALS.signs_priority != signspriority:
    GLOBALS.signs_priority = int(signspriority)
    if int(GLOBALS.features['has_sign_priority']):
      GLOBALS.signs_priority_text = ' priority=' + signspriority + ' '

  if enablesigns != GLOBALS.enable_signs:
    GLOBALS.enable_signs = enablesigns
    if enablesigns:
      returnState |= ENABLE_SIGNS
    else:
      returnState |= DISABLE_SIGNS

  if enabletreesitter != GLOBALS.enable_treesitter:
    GLOBALS.enable_treesitter = enabletreesitter
    if GLOBALS.enable_treesitter and GLOBALS.require_treesitter == 0:
      try:
        vim.api.exec_lua("_vimade = require('vimade')", [])
      except: 
          pass
      GLOBALS.require_treesitter = 1

    returnState |= FULL_INVALIDATE


  if GLOBALS.colorscheme != colorscheme:
    GLOBALS.colorscheme = colorscheme
    returnState |= RECALCULATE
  if GLOBALS.background != background:
    GLOBALS.background = background
    if not GLOBALS.term_response and GLOBALS.is_term and not termguicolors:
      (GLOBALS.term_fg, GLOBALS.term_bg) = ('#FFFFFF','#000000') if 'dark' in GLOBALS.background else ('#000000', '#FFFFFF')
    returnState |= RECALCULATE
  if GLOBALS.fade_level != fadelevel:
    GLOBALS.fade_level = fadelevel
    returnState |= RECALCULATE
  if GLOBALS.normal_id != normalid:
    GLOBALS.normal_id = normalid
    returnState |= RECALCULATE
  if GLOBALS.normalnc_id != normalncid:
    GLOBALS.normalnc_id = normalncid
    returnState |= RECALCULATE
  if GLOBALS.termguicolors != termguicolors:
    GLOBALS.termguicolors = termguicolors
    returnState |= RECALCULATE

  if is_nvim and GLOBALS.enable_basegroups != enablebasegroups:
    GLOBALS.enable_basegroups = enablebasegroups
    returnState |= BASEGROUPS
  if is_nvim and ','.join(GLOBALS.basegroups) != ','.join(basegroups):
    GLOBALS.basegroups = basegroups
    returnState |= BASEGROUPS

  if normalid or normalncid:
    base_hi = None
    base_fill = colors.getHi(GLOBALS.normal_id)
    if normalncid:
      base_hi = colors.getHi(GLOBALS.normalnc_id)
      base_hi = [base_fill[i] if not x else x for i,x in enumerate(base_hi)]
    else:
      base_hi = base_fill
    GLOBALS.normal_fg256 = base_hi[0]
    GLOBALS.normal_bg256 = base_hi[1]
    GLOBALS.normal_fg24b = base_hi[2]
    GLOBALS.normal_bg24b = base_hi[3]
    if not basefg256:
      basefg256 = base_hi[0]
    if not basefg24b:
      basefg24b = base_hi[2]
    if not basebg256:
      basebg256 = base_hi[1]
    if not basebg24b:
      basebg24b = base_hi[3]

  if GLOBALS.fade_priority != fadepriority:
    GLOBALS.fade_priority = fadepriority
    returnState |= FULL_INVALIDATE

  if not basefg256:
    basefg256 = GLOBALS.term_fg
  if not basebg256:
    basebg256 = GLOBALS.term_bg
  if not basefg24b:
    basefg24b = GLOBALS.term_fg
  if not basebg24b:
    basebg24b = GLOBALS.term_bg
  
  if basefg256 and GLOBALS.base_fg256_last != basefg256:
    GLOBALS.base_fg256_last = basefg256
    basefg256 = colors.fromAnyToRGB(basefg256)
    GLOBALS.base_hi[0] = GLOBALS.base_fg256 = basefg256
    returnState |= RECALCULATE
  if basefg24b and GLOBALS.base_fg24b_last != basefg24b:
    GLOBALS.base_fg24b_last = basefg24b
    basefg24b = colors.fromAnyToRGB(basefg24b)
    GLOBALS.base_hi[1] = GLOBALS.base_fg24b = basefg24b
    returnState |= RECALCULATE

  if basebg256 and GLOBALS.base_bg256_last != basebg256:
    GLOBALS.base_bg256_last = basebg256
    basebg256 = colors.fromAnyToRGB(basebg256)
    GLOBALS.base_hi[2] = GLOBALS.base_bg256 = basebg256
    returnState |= RECALCULATE

  if basebg24b and GLOBALS.base_bg24b_last != basebg24b:
    GLOBALS.base_bg24b_last = basebg24b
    basebg24b = colors.fromAnyToRGB(basebg24b)
    GLOBALS.base_hi[3] = GLOBALS.base_bg24b = basebg24b
    returnState |= RECALCULATE

  if (returnState & FULL_INVALIDATE or returnState & RECALCULATE) and (len(GLOBALS.base_fg256) > 0 or len(GLOBALS.base_fg24b) > 0) and (len(GLOBALS.base_bg256) > 0 or len(GLOBALS.base_bg24b) > 0):
    GLOBALS.base_hi[0] = GLOBALS.base_fg256
    GLOBALS.base_hi[1] = GLOBALS.base_bg256
    GLOBALS.base_hi[2] = GLOBALS.base_fg24b
    GLOBALS.base_hi[3] = GLOBALS.base_bg24b
    GLOBALS.base_fade256 = colors.interpolate256(GLOBALS.base_fg256, GLOBALS.base_bg256, GLOBALS.fade_level)
    GLOBALS.base_fade24b = colors.interpolate24b(GLOBALS.base_fg24b, GLOBALS.base_bg24b, GLOBALS.fade_level)
    try:
      GLOBALS.base_fg_exp256 = colors.interpolate256(GLOBALS.base_fg256, GLOBALS.base_fg256, GLOBALS.fade_level).upper()
      GLOBALS.base_fg_exp24b = colors.interpolate24b(GLOBALS.base_fg24b, GLOBALS.base_fg24b, GLOBALS.fade_level).upper()
    except:
      #consider logging here, nothing bad should happen -- vimade should still work
      pass
    try:
      GLOBALS.base_bg_exp256 = colors.interpolate256(GLOBALS.base_bg256, GLOBALS.base_bg256, GLOBALS.fade_level).upper()
      GLOBALS.base_bg_exp24b = colors.interpolate24b(GLOBALS.base_bg24b, GLOBALS.base_bg24b, GLOBALS.fade_level).upper()
    except:
      #consider logging here, nothing bad should happen -- vimade should still work
      pass

  if (GLOBALS.base_fg256 == None and GLOBALS.base_fg24b == None) or (GLOBALS.base_bg256 == None or GLOBALS.base_bg24b == None) or (GLOBALS.base_fade256 == None and GLOBALS.base_fade24b == None):
    returnState |= ERROR

  return returnState

import vim
import sys
from vimade import colors
from vimade.term_256 import RGB_256

GLOBALS = sys.modules[__name__]

(is_nvim, is_term, is_tmux, original_background) = vim.eval('[has("nvim"), has("gui_running"), $TMUX, &background]')
(term_fg, term_bg) = ('#FFFFFF','#000000') if 'dark' in original_background else ('#000000', '#FFFFFF')
is_nvim = int(is_nvim) == 1
is_term = int(is_term) == 0
is_tmux = is_tmux != ''
fade_level = None
termguicolors = None
base_hi = [None, None]
base_fade = None
background = None
colorscheme = None
row_buf_size = None
col_buf_size = None
normal_id = None
normal_bg = ''
base_bg = ''
base_fg = ''
base_bg_exp = ''
base_fg_exp = ''
base_bg_last = ''
base_fg_last = '';
fade = None
hi_fg = ''
hi_bg = ''
term_fg = term_fg
term_bg = term_bg
is_nvim = is_nvim
is_term = is_term
is_tmux = is_tmux
original_background = original_background
term_response = False
enable_signs = False
signs_retention_period = 0

READY = 0
ERROR = 1
FULL_INVALIDATE = 2
RECALCULATE = 4
ENABLE_SIGNS = 8
DISABLE_SIGNS = 16

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
  allGlobals = vim.eval('[g:vimade, &background, execute(":colorscheme"), &termguicolors]')
  nextGlobals = allGlobals[0]
  background = allGlobals[1]
  colorscheme = allGlobals[2]
  termguicolors = int(allGlobals[3]) == 1
  fadelevel = float(nextGlobals['fadelevel'])
  rowbufsize = int(nextGlobals['rowbufsize'])
  colbufsize = int(nextGlobals['colbufsize'])
  signsretentionperiod = int(nextGlobals['signsretentionperiod'])
  basefg = nextGlobals['basefg']
  basebg = nextGlobals['basebg']
  normalid = nextGlobals['normalid']
  enablesigns = int(nextGlobals['enablesigns'])
  GLOBALS.row_buf_size = rowbufsize
  GLOBALS.col_buf_size = colbufsize
  GLOBALS.signs_retention_period = signsretentionperiod

  if enablesigns != GLOBALS.enable_signs:
    GLOBALS.enable_signs = enablesigns
    if enablesigns:
      returnState |= ENABLE_SIGNS
    else:
      returnState |= DISABLE_SIGNS

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
  if GLOBALS.termguicolors != termguicolors:
    GLOBALS.termguicolors = termguicolors
    returnState |= RECALCULATE

  if normalid:
    base_hi = vim.eval('vimade#GetHi('+GLOBALS.normal_id+')')
    GLOBALS.normal_bg = base_hi[1]
    if not basefg:
      basefg = base_hi[0]
    if not basebg:
      basebg = base_hi[1]

  if GLOBALS.is_term:
    if not basefg:
      basefg = GLOBALS.term_fg
    if not basebg:
      basebg = GLOBALS.term_bg

  if basefg and GLOBALS.base_fg_last != basefg:
    GLOBALS.base_fg_last = basefg
    if isinstance(basefg, list):
      basefg = [int(x) for x in basefg]
    elif len(basefg) == 7:
      basefg = colors.fromHexStringToRGB(basefg)
    elif basefg.isdigit() and int(basefg) < len(RGB_256):
      basefg = colors.from256ToRGB(int(basefg))
    GLOBALS.base_hi[0] = GLOBALS.base_fg = basefg
    returnState |= RECALCULATE

  if basebg and GLOBALS.base_bg_last != basebg:
    GLOBALS.base_bg_last = basebg
    if isinstance(basebg, list):
      basebg = [int(x) for x in basebg]
    elif len(basebg) == 7:
      basebg = colors.fromHexStringToRGB(basebg)
    elif basebg.isdigit() and int(basebg) < len(RGB_256):
      basebg = colors.from256ToRGB(int(basebg))
    GLOBALS.base_hi[1] = GLOBALS.base_bg = basebg
    returnState |= RECALCULATE

  if (returnState & FULL_INVALIDATE or returnState & RECALCULATE) and len(GLOBALS.base_fg) > 0 and len(GLOBALS.base_bg) > 0:
    GLOBALS.base_hi[0] = GLOBALS.base_fg
    GLOBALS.base_hi[1] = GLOBALS.base_bg
    if not GLOBALS.is_term or termguicolors:
      GLOBALS.hi_fg = ' guifg='
      GLOBALS.hi_bg = ' guibg='
      GLOBALS.fade = colors.interpolate24b
    else:
      GLOBALS.hi_fg = ' ctermfg='
      GLOBALS.hi_bg = ' ctermbg='
      GLOBALS.fade = colors.interpolate256
    GLOBALS.base_fade = GLOBALS.fade(GLOBALS.base_fg, GLOBALS.base_bg, GLOBALS.fade_level)
    try:
      GLOBALS.base_fg_exp = GLOBALS.fade(GLOBALS.base_fg, GLOBALS.base_fg, GLOBALS.fade_level).upper()
    except:
      #consider logging here, nothing bad should happen -- vimade should still work
      pass
    try:
      GLOBALS.base_bg_exp = GLOBALS.fade(GLOBALS.base_bg, GLOBALS.base_bg, GLOBALS.fade_level).upper()
    except:
      #consider logging here, nothing bad should happen -- vimade should still work
      pass

  if GLOBALS.base_fg == None or GLOBALS.base_bg == None or GLOBALS.base_fade == None:
    returnState |= ERROR

  return returnState

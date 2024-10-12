import sys
M = sys.modules[__name__]

from vimade.v2.util import color as COLOR_UTIL
GLOBALS = None

def __init(globals):
  global GLOBALS
  GLOBALS = globals
M.__init = __init

def _tint_or_basebg(tint):
  if type(tint) == 'dict':
    return tint
  elif GLOBALS.basebg:
    return {
      'fg': {
        'rgb': COLOR_UTIL.toRgb(GLOBALS.basebg),
        'intensity': 0.5
      }
    }

def _create_to_hl(tint):
  if not tint:
    return None
  fg = tint.get('fg')
  bg = tint.get('bg')
  sp = tint.get('sp')
  if not fg and not bg and not sp:
    return None
  result = {
    'fg': None,
    'bg': None,
    'sp': None,
    'ctermfg': None,
    'ctermbg': None,
    'fg_intensity': None,
    'bg_intensity': None,
    'sp_intensity': None,
  }
  if fg:
    result['fg'] = COLOR_UTIL.to24b(fg['rgb'])
    result['ctermfg'] = fg['rgb']
    result['fg_intensity'] = 1 - fg.get('intensity', 1)
  if bg:
    result['bg'] = COLOR_UTIL.to24b(bg['rgb'])
    result['ctermbg'] = bg['rgb']
    result['bg_intensity'] = 1 - bg.get('intensity', 1)
  if sp:
    result['sp'] = COLOR_UTIL.to24b(sp['rgb'])
    result['sp_intensity'] = 1 - sp.get('intensity', 1)
  return result

# @param initial_tint = {
#  'fg': {'rgb': [255,255,255], 'intensity': 0-1},
#  'bg': {'rgb': [255,255,255], 'intensity': 0-1}, 
#  'sp': {'rgb': [255,255,255], 'intensity': 0-1}, 
# }
# rgb value for each fg, bg, and sp.
# These are optional and you can choose which ones that you want to specify.
# intensity is 0-1 (1 being the most amount of recoloring applied)
class Tint():
  def __init__(parent, initial_tint):
    parent.initial_tint = initial_tint
    class __Tint():
      def __init__(self, win):
        initial_tint = parent.initial_tint
        self.to_hl = _create_to_hl(initial_tint) if (initial_tint and type(initial_tint) == 'dict') else None
        self.win = win
      def before(self):
        if callable(parent.initial_tint):
          self.to_hl = _create_to_hl(parent.initial_tint(self.win))
      def key(self, i):
        to_hl = self.to_hl
        if not to_hl:
          return ''
        return 'T-' \
        + str(to_hl['fg'] != None and (str(to_hl['fg'] or '') + ',' + (str(to_hl['ctermfg'][0])+'-'+str(to_hl['ctermfg'][1])+'-'+str(to_hl['ctermfg'][2])) + ',' + str(to_hl['fg_intensity'])) or '') + '|' \
        + (to_hl['bg'] != None and (str(to_hl['bg'] or '') + ',' + (str(to_hl['ctermbg'][0])+'-'+str(to_hl['ctermbg'][1])+'-'+str(to_hl['ctermbg'][2])) + ',' + str(to_hl['bg_intensity'])) or '') + '|'
        + (to_hl['sp'] != None and (str(to_hl['sp'] or '') + str(to_hl['sp_intensity'])) or '')
      def modify(self, hl, target):
        to_hl = self.to_hl
        if not to_hl:
          return
        if hl['fg'] != None and to_hl['fg'] !=None:
          hl['fg'] = COLOR_UTIL.interpolate24b(hl['fg'], to_hl['fg'], to_hl['fg_intensity'])
        if hl['bg'] != None and to_hl['bg'] != None:
          hl['bg'] = COLOR_UTIL.interpolate24b(hl['bg'], to_hl['bg'], to_hl['bg_intensity'])
        if hl['sp'] != None and to_hl['sp'] != None:
          hl['sp'] = COLOR_UTIL.interpolate24b(hl['sp'], to_hl['sp'], to_hl['sp_intensity'])
        if hl['ctermfg'] != None and to_hl['ctermfg'] != None:
          hl['ctermfg'] = COLOR_UTIL.interpolate256(hl['ctermfg'], to_hl['ctermfg'], to_hl['fg_intensity'])
        if hl['ctermbg'] != None and to_hl['ctermbg'] != None:
          hl['ctermbg'] = COLOR_UTIL.interpolate256(hl['ctermbg'], to_hl['ctermbg'], to_hl['bg_intensity'])
        return
    parent.attach = __Tint
  def value(parent, replacement = None):
    if replacement != None:
      parent.initial_tint = replacement
      return result
    return parent.initial_tint
M.DEFAULT = Tint(lambda win: GLOBALS.tint(win) if callable(GLOBALS.tint) else _tint_or_basebg(GLOBALS.tint))

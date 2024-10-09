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

def Tint(initial_tint):
  def TintWin(win):
    state = {'to_hl': _create_to_hl(initial_tint) if (initial_tint and type(initial_tint) == 'dict') else None}
    def before():
      if callable(initial_tint):
        state['to_hl'] = _create_to_hl(initial_tint(win))
    def key(i):
      to_hl = state['to_hl']
      if not to_hl:
        return ''
      return 'T-' \
      + str(to_hl['fg'] != None and (str(to_hl['fg'] or '') + ',' + (str(to_hl['ctermfg'][0])+'-'+str(to_hl['ctermfg'][1])+'-'+str(to_hl['ctermfg'][2])) + ',' + str(to_hl['fg_intensity'])) or '') + '|' \
      + (to_hl['bg'] != None and (str(to_hl['bg'] or '') + ',' + (str(to_hl['ctermbg'][0])+'-'+str(to_hl['ctermbg'][1])+'-'+str(to_hl['ctermbg'][2])) + ',' + str(to_hl['bg_intensity'])) or '') + '|'
      + (to_hl['sp'] != None and (str(to_hl['sp'] or '') + str(to_hl['sp_intensity'])) or '')
    def modify(hl, target):
      to_hl = state['to_hl']
      if not to_hl:
        return
      if hl['fg'] != None and to_hl['fg'] !=None:
        hl['fg'] = COLOR_UTIL.interpolate24b(hl['fg'], to_hl['fg'], to_hl['fg_intensity'])
      if to_hl['bg'] != None:
        if hl['bg'] != None:
          hl['bg'] = COLOR_UTIL.interpolate24b(hl['bg'], to_hl['bg'], to_hl['bg_intensity'])
        if target['bg'] != None:
          target['bg'] = COLOR_UTIL.interpolate24b(target['bg'], to_hl['bg'], to_hl['bg_intensity'])
      if hl['sp'] != None and to_hl['sp'] != None:
        hl['sp'] = COLOR_UTIL.interpolate24b(hl['sp'], to_hl['sp'], to_hl['sp_intensity'])
      if hl['ctermfg'] != None and to_hl['ctermfg'] != None:
        hl['ctermfg'] = COLOR_UTIL.interpolate256(hl['ctermfg'], to_hl['ctermfg'], to_hl['fg_intensity'])
      if to_hl['ctermbg'] != None:
        if hl['ctermbg'] != None:
          hl['ctermbg'] = COLOR_UTIL.interpolate256(hl['ctermbg'], to_hl['ctermbg'], to_hl['bg_intensity'])
        if target['ctermbg'] != None:
          target['ctermbg'] = COLOR_UTIL.interpolate256(target['ctermbg'], to_hl['ctermbg'], to_hl['bg_intensity'])
      return
    return {'before': before, 'key': key, 'modify': modify}
  return TintWin

M.DEFAULT = Tint(lambda win: GLOBALS.tint(win) if callable(GLOBALS.tint) else _tint_or_basebg(GLOBALS.tint))

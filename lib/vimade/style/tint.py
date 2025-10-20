import sys
M = sys.modules[__name__]

from vimade.util import color as COLOR_UTIL
from vimade.style.value import condition as CONDITION
from vimade.util import type as TYPE
from vimade.util import validate as VALIDATE

GLOBALS = None

def __init(args):
  global GLOBALS
  GLOBALS = args['GLOBALS']
M.__init = __init

def _tint_or_global(tint):
  if type(tint) == dict:
    return TYPE.deep_copy(tint)
  return GLOBALS.tint

def _create_tint(tint):
  if type(tint) != dict:
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
    rgb = fg.get('rgb')
    result['fg'] = COLOR_UTIL.to24b(rgb)
    result['ctermfg'] = COLOR_UTIL.toRgb(rgb)
    result['fg_intensity'] = 1 - fg.get('intensity')
  if bg:
    rgb = bg.get('rgb')
    result['bg'] = COLOR_UTIL.to24b(rgb)
    result['ctermbg'] = COLOR_UTIL.toRgb(rgb)
    result['bg_intensity'] = 1 - bg.get('intensity')
  if sp:
    result['sp'] = COLOR_UTIL.to24b(sp.get('rgb'))
    result['sp_intensity'] = 1 - sp.get('intensity')
  return result

# @param **kwargs {
# condition, 
# value = {
#  'fg': {'rgb': [255,255,255], 'intensity': 0-1},
#  'bg': {'rgb': [255,255,255], 'intensity': 0-1}, 
#  'sp': {'rgb': [255,255,255], 'intensity': 0-1}, 
# }
#}
# rgb value for each fg, bg, and sp.
# These are optional and you can choose which ones that you want to specify.
# intensity is 0-1 (1 being the most amount of recoloring applied)
class Tint():
  def __init__(parent, **kwargs):
    _condition = kwargs.get('condition')
    _condition = _condition if _condition != None else CONDITION.INACTIVE
    parent._value = kwargs.get('value')
    parent.tick = kwargs.get('tick')
    class __Tint():
      def __init__(self, win, state):
        value = parent._value
        self.win = win
        self._condition = _condition
        self.condition = None
        self.to_hl = None
        self._animating = False
      def resolve(self, value, state):
        return VALIDATE.tint(TYPE.resolve_all_fn(value, self, state))
      def before(self, win, state):
        # don't use self.resolve here for performance reasons
        tint = TYPE.resolve_all_fn(parent._value, self, state)
        self.condition = _condition(self, state) if callable(_condition) else _condition
        if self.condition == False:
          return
        self.to_hl = _create_tint(VALIDATE.tint(tint))
      def key(self, win, state):
        if self.condition == False or not self.to_hl:
          return ''
        to_hl = self.to_hl
        return 'T-' \
        + str(to_hl['fg'] != None and (str(to_hl['fg'] or '') + ',' + (str(to_hl['ctermfg'][0])+'-'+str(to_hl['ctermfg'][1])+'-'+str(to_hl['ctermfg'][2])) + ',' + str(to_hl['fg_intensity'])) or '') + '|' \
        + (to_hl['bg'] != None and (str(to_hl['bg'] or '') + ',' + (str(to_hl['ctermbg'][0])+'-'+str(to_hl['ctermbg'][1])+'-'+str(to_hl['ctermbg'][2])) + ',' + str(to_hl['bg_intensity'])) or '') + '|'
        + (to_hl['sp'] != None and (str(to_hl['sp'] or '') + str(to_hl['sp_intensity'])) or '')
      def modify(self, highlights, target):
        if self.condition == False:
          return
        to_hl = self.to_hl
        if not to_hl:
          return
        if target['bg'] != None and to_hl['bg'] != None:
          target['bg'] = COLOR_UTIL.interpolate24b(target['bg'], to_hl['bg'], to_hl['bg_intensity'])
        if target['ctermbg'] != None and to_hl['ctermbg'] != None:
          target['ctermbg'] = COLOR_UTIL.interpolate256(target['ctermbg'], to_hl['ctermbg'], to_hl['bg_intensity'])
        for hl in highlights.values():
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
      parent._value = replacement
      return parent
    return parent._value

def Default(**kwargs):
  return Tint(**TYPE.extend({
    'condition': CONDITION.INACTIVE,
    'value': lambda style, state: GLOBALS.tint(style, state) if callable(GLOBALS.tint) else _tint_or_global(GLOBALS.tint),
  }, kwargs))

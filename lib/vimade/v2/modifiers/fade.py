import sys
M = sys.modules[__name__]

from vimade.v2.util import color as COLOR_UTIL
GLOBALS = None

def __init(globals):
  global GLOBALS
  GLOBALS = globals
M.__init = __init

def Fade(initial_fade):
  def FadeWin(win):
    state = {'fade': initial_fade}
    def before():
      if callable(initial_fade):
        state['fade'] = initial_fade(win)
    def key(i):
      return 'F-' + str(state['fade'])
    def modify(hl, to_hl):
      fade = state['fade']
      fg = hl['fg']
      bg = hl['bg']
      sp = hl['sp']
      ctermfg = hl['ctermfg']
      ctermbg = hl['ctermbg']
      if fg != None:
        hl['fg'] = COLOR_UTIL.interpolate24b(fg, to_hl['bg'], fade)
      if bg != None:
        hl['bg'] = COLOR_UTIL.interpolate24b(bg, to_hl['bg'], fade)
      if sp != None:
        hl['sp'] = COLOR_UTIL.interpolate24b(sp, to_hl['bg'], fade)
      if ctermfg != None:
        hl['ctermfg'] = COLOR_UTIL.interpolate256(ctermfg, to_hl['ctermbg'], fade)
      if ctermbg != None:
        hl['ctermbg'] = COLOR_UTIL.interpolate256(ctermbg, to_hl['ctermbg'], fade)
      return
    return {'before': before, 'key': key, 'modify': modify}
  return FadeWin

M.DEFAULT = Fade(lambda win: GLOBALS.fadelevel(win) if callable(GLOBALS.fadelevel) else GLOBALS.fadelevel)

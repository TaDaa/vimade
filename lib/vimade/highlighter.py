import vim
from vimade import global_state as GLOBALS

HI_CACHE = {}

def recalculate():
  fade_ids(list(HI_CACHE.keys()), True)

def reset():
  HI_CACHE = {}

#external - use cache / highlight ids
def fade_ids(ids, force = False):
  result = ids[:]
  exprs = []
  i = 0
  for id in ids:
      if not id in HI_CACHE or force:
          result[i] = HI_CACHE[id] = hi = __fade_id(id)
          group = hi[0]
          expr = 'hi ' + group + GLOBALS.hi_fg + hi[1]
          if hi[2] != None:
            expr += GLOBALS.hi_bg + hi[2]
          exprs.append(expr)
      else:
          result[i] = HI_CACHE[id]
      i += 1
  if len(exprs):
      vim.command('|'.join(exprs))
  return result

#internal
def __fade_id(id):
  hi = vim.eval('vimade#GetHi('+id+')')
  guifg = hi[0]
  guibg = hi[1]

  if guibg:
    if guibg == GLOBALS.base_bg_exp or guibg == GLOBALS.normal_bg:
      guibg = None
    else:
      guibg = GLOBALS.fade(guibg, GLOBALS.base_bg, GLOBALS.fade_level)
  else:
    guibg = None

  if not guifg:
    guifg = GLOBALS.base_fade
  else:
    guifg = GLOBALS.fade(guifg, GLOBALS.base_bg, GLOBALS.fade_level)


  return ('vimade_' + id, guifg, guibg)

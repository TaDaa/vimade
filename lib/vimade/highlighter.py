import vim
from vimade import util
from vimade import global_state as GLOBALS
from vimade import colors

HI_CACHE = {}
NAME_CACHE = {}

def pre_check():
  values = list(HI_CACHE.values())
  if len(values):
    sample = values[0]

    result = int(util.eval_and_return('hlexists("'+sample[0]+'")'))
    if not result:
      recalculate()

def recalculate():
  keys = list(HI_CACHE.keys())
  clearable = []
  normal = []
  for key in keys:
    if key:
      if key[0] == 'c':
        clearable.append(key)
      else:
        normal.append(key)

  fade_ids(normal, True)
  fade_ids(clearable, True, True)

def reset():
  HI_CACHE = {}

#external - use cache / highlight ids
def fade_names(names, force = False, clearable = False):
  ipc = []
  checks = {}
  i = 0
  ids = []
  for name in names:
    if not name in NAME_CACHE:
      if not name in checks:
        checks[name] = i
        ipc.append('hlID("'+name+'")')
        i += 1

  if len(ipc):
    ipc = util.eval_and_return('[' + ','.join(ipc) + ']')

  i = 0
  for name in names:
    if not name in NAME_CACHE:
      id = ipc[checks[name]]
      NAME_CACHE[name] = id
      ids.append(id)
    else:
      ids.append(NAME_CACHE[name])
  return fade_ids(ids, force, clearable)



def fade_ids(ids, force = False, clearable = False):
  result = ids[:]
  exprs = []
  i = 0
  for id in ids:
      id = str(id)
      if not id:
        continue
      if id[0] == 'c':
        id = id.replace('c', '')
      key_id = id if not clearable else ('c'+str(id))
      if not key_id in HI_CACHE or force:
          hi = colors.getHi(id)
          hi = __fade_id(key_id, hi[0], hi[1], hi[2], hi[3], hi[4], clearable)
          result[i] = HI_CACHE[key_id] = hi
          
          group = hi[0]
          expr = 'hi ' + group
          expr += hi[1] if hi[1] else ' ctermfg=NONE'
          expr += hi[2] if hi[2] else ' ctermbg=NONE'
          expr += hi[3] if hi[3] else ' guifg=NONE'
          expr += hi[4] if hi[4] else ' guibg=NONE'
          expr += hi[5] if hi[5] else ' guisp=NONE'
          exprs.append(expr)
      else:
          result[i] = HI_CACHE[key_id]
      i += 1
  if len(exprs):
      vim.command('|'.join(exprs))
  return result

#internal
def __fade_id(id, ctermfg, ctermbg, guifg, guibg, guisp, clearable = False):

  if ctermbg:
    if ctermbg == GLOBALS.base_bg_exp256 or ctermbg == GLOBALS.normal_bg256:
      ctermbg = ''
    else:
      ctermbg = ' ctermbg='+colors.interpolate256(ctermbg, GLOBALS.base_bg256, GLOBALS.fade_level)
  else:
    ctermbg = ''

  if not ctermfg:
    if clearable:
      ctermfg = ''
    else:
      ctermfg = ' ctermfg='+GLOBALS.base_fade256
  else:
    ctermfg = ' ctermfg='+colors.interpolate256(ctermfg, GLOBALS.base_bg256, GLOBALS.fade_level)

  if guibg:
    if guibg == GLOBALS.base_bg_exp24b or guibg == GLOBALS.normal_bg24b:
      guibg = ''
    else:
      guibg = ' guibg='+colors.interpolate24b(guibg, GLOBALS.base_bg24b, GLOBALS.fade_level)
  else:
    guibg = ''

  if not guifg:
    if clearable:
      guifg = ''
    else:
      guifg = ' guifg='+GLOBALS.base_fade24b
  else:
    guifg = ' guifg='+colors.interpolate24b(guifg, GLOBALS.base_bg24b, GLOBALS.fade_level)

  if guisp:
    guisp = ' guisp='+colors.interpolate24b(guisp, GLOBALS.base_bg24b, GLOBALS.fade_level)
  else:
    guisp = ''

  return ('vimade_' + id, ctermfg, ctermbg, guifg, guibg, guisp)

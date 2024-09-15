import sys
import vim
M = sys.modules[__name__]

from vimade.v2.state import globals as GLOBALS
from vimade.v2 import colors as COLORS
from vimade.v2.util import ipc as IPC

M.next_id = 0
M.free_ids = []

M.hl_name_cache = {}
M.base_id_cache = {}
M.vimade_id_cache = {}
M.win_lookup = {}

hi_string = "vimade#GetNvimHi(%d)" if GLOBALS.is_nvim else "vimade#GetHi(%d)"

# vim/nvim are limited by 20000 highlights, so we need to be efficient and
# reuse our created highlights everytime possible.
def _get_next_id():
  if len(M.free_ids) > 0:
    return M.free_ids.pop()
  M.next_id += 1
  next_id = M.next_id
  return next_id

# we monitor which windows are using which highlights. Once is a window is
# gone, invalidated, or cleared, we might be able to free those highlights.
def clear_win(win):
  winid = win.winid
  lookup = win_lookup.get(winid)
  if lookup != None:
    highlights = lookup['hi']
    for hi in highlights.values():
      del hi['windows'][winid]
      if len(hi['windows'].keys()) == 0:
        M.free_ids.append(hi['id'])
        del M.vimade_id_cache[hi['cache_key']]
    del win_lookup[winid]

# clears a base highlight so that it can be re-evaluated.
def clear_color(win, id):
  id = _get_hl_ids_for_names(win, [id])[0]
  if M.base_id_cache.get(id):
    del M.base_id_cache[id]

# create the vimade replacement highlight
def create_highlight(cache_key, attrs, target, fade):
  hi_attrs = attrs['hi']
  ctermfg = hi_attrs[0]
  ctermbg = hi_attrs[1]
  guifg = hi_attrs[2]
  guibg = hi_attrs[3]
  guisp = hi_attrs[4]
  result = {
    'id': _get_next_id(),
    'cache_key': cache_key,
    'attrs': [None, None, None, None, None],
    'windows': {},
  }
  result_attrs = result['attrs']
  result_attrs[0] = COLORS.interpolate256(ctermfg, target['ctermfg'], fade) if (ctermfg != None and target['ctermfg'] != None) else 'NONE'
  result_attrs[1] = COLORS.interpolate256(ctermbg, target['ctermbg'], fade) if (ctermbg != None and target['ctermbg'] != None) else 'NONE'
  result_attrs[2] = COLORS.interpolate24b(guifg, target['fg'], fade) if (guifg != None and target['fg'] != None) else 'NONE'
  result_attrs[3] = COLORS.interpolate24b(guibg, target['bg'], fade) if (guibg != None and target['bg'] != None) else 'NONE'
  result_attrs[4] = COLORS.interpolate24b(guisp, target['sp'], fade) if (guisp != None and target['sp'] != None) else 'NONE'
  return result

# ensure we have valid ids for the highlighting process, otherwise
# get them.
def _get_hl_ids_for_names(win, to_process):
  to_process = to_process + []
  name_index_map = {}
  id_eval = []
  cnt = 0
  for i,name in enumerate(to_process):
    if name == 0 or name == '':
      name = win.original_wincolor or 'Normal'
    if type(name) == str:
      id = M.hl_name_cache.get(name)
      if id == None:
        name_index_map[cnt] = i
        id_eval.append('hlID("%s")' % name)
        cnt += 1
      else:
        to_process[i] = id

  if cnt:
    ids = IPC.eval_and_return('[' + ','.join(id_eval) + ']')
    for i,id in enumerate(ids):
      id = int(id)
      index = name_index_map[i]
      name =  to_process[index]
      to_process[index] = id
      if id != 0:
        M.hl_name_cache[name] = id

  return to_process

def create_highlights(win, to_process):
  to_process = _get_hl_ids_for_names(win, to_process)
  fade = win.fadelevel
  tint = win.tint
  default_bg = 0x000000 if GLOBALS.is_dark else 0xFFFFFF
  default_ctermbg = 0 if GLOBALS.is_dark else 255

  ids = []
  attrs_eval = []

  normal_bg = win.wincolorhl[3]
  normal_ctermbg = win.wincolorhl[1]
  target = {
    'bg': normal_bg,
    'fg': normal_bg,
    'sp': normal_bg,
    'ctermfg': normal_ctermbg,
    'ctermbg': normal_ctermbg,
  }

  if tint != None and (tint.get('bg') != None or tint.get('fg') != None or tint.get('sp') != None):
    tint_out = COLORS.tint(tint, normal_bg, normal_ctermbg)
    target['fg'] = tint_out.get('fg', target['fg'])
    target['ctermfg'] = tint_out.get('ctermfg', target['ctermfg'])
    target['sp'] = tint_out.get('sp', target['sp'])
    target['bg'] = tint_out.get('bg', target['bg'])
    target['ctermbg'] = tint_out.get('ctermbg', target['ctermbg'])

  result = []
  for i, id in enumerate(to_process):
    if id and M.base_id_cache.get(id) == None:
      M.base_id_cache[id] = {}
      ids.append(id)
      attrs_eval.append(hi_string % id)

  attrs = IPC.eval_and_return('[' + ','.join(attrs_eval) + ']')

  for i, id in enumerate(ids):
    base = M.base_id_cache[id]
    base_hi = COLORS.convertHi(attrs[i], win.wincolorhl)
    base['hi'] = base_hi
    base['base_key'] = ','.join([str(x) for x in base_hi])

  to_create = []
  for id in to_process:
    base = M.base_id_cache[id]
    cache_key = '%s:%s' % (base['base_key'], win.hi_key)
    if not M.vimade_id_cache.get(cache_key):
      vimade_hi = M.create_highlight(cache_key, base, target, fade)
      M.vimade_id_cache[cache_key] = vimade_hi
      
      expr = 'noautocmd hi vimade_%s' % vimade_hi['id']
      expr += ' ctermfg=%s' % vimade_hi['attrs'][0]
      expr += ' ctermbg=%s' % vimade_hi['attrs'][1]
      expr += ' guifg=%s' % vimade_hi['attrs'][2]
      expr += ' guibg=%s' % vimade_hi['attrs'][3]
      expr += ' guisp=%s' % vimade_hi['attrs'][4]
      to_create.append(expr)
    vimade_hi = M.vimade_id_cache[cache_key]
    vimade_hi['windows'][win.winid] = True
    result.append(vimade_hi['id'])
    if not M.win_lookup.get(win.winid):
      M.win_lookup[win.winid] = {
          'hi': {}
      }
    M.win_lookup[win.winid]['hi'][vimade_hi['id']] = vimade_hi

  if len(to_create):
    vim.command('|'.join(to_create))

  return result

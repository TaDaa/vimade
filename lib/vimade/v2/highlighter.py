import sys
import vim
M = sys.modules[__name__]

from vimade.v2.state import globals as GLOBALS
from vimade.v2 import colors as COLORS
from vimade.v2.util import ipc as IPC
from vimade.v2.util.promise import Promise

is_nvim = GLOBALS.is_nvim

M.next_id = 0
M.free_ids = []

M.hl_name_cache = {}
M.base_id_cache = {}
M.vimade_id_cache = {}
M.win_lookup = {}

HAS_NVIM_GET_HL = int(IPC.eval_and_return('exists("*nvim_get_hl")'))
def _process_nvim_get_hl(results):
  return [(int(r.get('ctermfg',-1)),int(r.get('ctermbg', -1)),int(r.get('fg',-1)),int(r.get('bg',-1)), int(r.get('sp',-1))) for r in results]
_process_hl_results = None

if GLOBALS.is_nvim:
  if HAS_NVIM_GET_HL:
    hi_string = "nvim_get_hl(0,{'id':%s,'link':0})"
    _process_hl_results = _process_nvim_get_hl
  else:
    hi_string = "vimade#GetNvimHi(%s)" 
else:
    hi_string = "vimade#GetHi(%s)" 

# vim/nvim are limited by 20000 highlights, so we need to be efficient and
# reuse our created highlights everytime possible.
def _get_next_id():
  if len(M.free_ids) > 0:
    return M.free_ids.pop()
  M.next_id += 1
  next_id = M.next_id
  return next_id

def get_hl_for_ids(win, ids):
  ids = _get_hl_ids_for_names(win, ids)
  promise = IPC.batch_eval_and_return('['+','.join([hi_string % id for id in ids])+']')
  result = Promise()
  def next(value):
    if _process_hl_results:
      value = _process_hl_results(value)
    result.resolve(value)
  promise.then(next)
  return result

# we monitor which windows are using which highlights. Once is a window is
# gone, invalidated, or cleared, we might be able to free those highlights.
def clear_win(win):
  winid = win.winid
  highlights = win_lookup.get(winid)
  if highlights != None:
    for hi in highlights.values():
      del hi['windows'][winid]
      if len(hi['windows'].keys()) == 0:
        M.free_ids.append(hi['id'])
        del M.vimade_id_cache[hi['cache_key']]
    del win_lookup[winid]

# clears a base highlight so that it can be re-evaluated.
def clear_colors(win, ids):
  ids = _get_hl_ids_for_names(win, ids)
  for id in ids:
    cache_key = str(id)
    if cache_key in M.base_id_cache:
      del M.base_id_cache[cache_key]

def clear_base_cache():
  M.base_id_cache = {}

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
    'attrs': (
      COLORS.interpolate256(hi_attrs[0], target[0], fade) if (hi_attrs[0] != None and target[0] != None) else 'NONE',
      # skip fading background color if its the same as the wincholhl
      COLORS.interpolate256(hi_attrs[1], target[1], fade) if (hi_attrs[1] != None and target[1] != None and hi_attrs[1] != target[1]) else 'NONE',
      COLORS.interpolate24b(hi_attrs[2], target[2], fade) if (hi_attrs[2] != None and target[2] != None) else 'NONE',
      # skip fading background color if its the same as the wincholhl
      COLORS.interpolate24b(hi_attrs[3], target[3], fade) if (hi_attrs[3] != None and target[3] != None and hi_attrs[3] != target[3]) else 'NONE',
      COLORS.interpolate24b(hi_attrs[4], target[4], fade) if (hi_attrs[4] != None and target[4] != None) else 'NONE'),
    'windows': {},
  }
  return result

# ensure we have valid ids for the highlighting process, otherwise
# get them.
def _get_hl_ids_for_names(win, to_process):
  to_process = to_process[0:]
  name_index_map = {}
  id_eval = []
  names = []
  cnt = 0
  win_original = win.original_wincolor or 'Normal'
  for i,name in enumerate(to_process):
    name = name or win_original
    if type(name) == str:
      id = M.hl_name_cache.get(name)
      if id == None:
        if not name in name_index_map:
          name_index_map[name] = True
          names.append(name)
          id_eval.append('hlID("%s")' % name)
      else:
        to_process[i] = id

  if len(id_eval):
    ids = IPC.eval_and_return('[' + ','.join(id_eval) + ']')
    for i,id in enumerate(ids):
      id = int(id)
      name = names[i]
      M.hl_name_cache[name] = id
      for j, o_id in enumerate(to_process):
        if o_id == name:
          to_process[j] = id

  return to_process

def create_highlights(win, to_process):
  to_process = _get_hl_ids_for_names(win, to_process)
  fade = win.fadelevel
  tint = win.tint


  wincolorhl = win.wincolorhl
  normal_bg = wincolorhl[3]
  normal_ctermbg = wincolorhl[1]
  fg_wincolorhl = [wincolorhl[0], None, wincolorhl[2], None, None]

  if tint != None and (tint.get('bg') != None or tint.get('fg') != None or tint.get('sp') != None):
    tint_out = COLORS.tint(tint, normal_bg, normal_ctermbg)
    target = (
       tint_out.get('ctermfg', normal_ctermbg),
       tint_out.get('ctermbg', normal_ctermbg),
       tint_out.get('fg', normal_bg),
       tint_out.get('bg', normal_bg),
       tint_out.get('sp', normal_bg))
  else:
    target = (
        normal_ctermbg,
        normal_ctermbg,
        normal_bg,
        normal_bg,
        normal_bg)

  result = []
  attrs_eval = []

  base_keys = []
  for id in to_process:
    cache_key = str(id)
    M.base_id_cache[cache_key] = {}
    base_keys.append(cache_key)
    attrs_eval.append(hi_string % id)

  if len(attrs_eval):
    # TODO worth batching?
    attrs = IPC.eval_and_return('[' + ','.join(attrs_eval) + ']')
    if _process_hl_results:
      attrs = _process_hl_results(attrs)

    for i, id in enumerate(base_keys):
      base = M.base_id_cache[id]
      base_hi = COLORS.convertHi(attrs[i], fg_wincolorhl)
      base['hi'] = base_hi
      base['base_key'] = ','.join(map(str, base_hi))

  to_create = []

  for id in to_process:
    base = M.base_id_cache[str(id)]
    cache_key = base['base_key'] + ':' + win.hi_key
    vimade_hi = M.vimade_id_cache.get(cache_key)
    if not vimade_hi:
      vimade_hi = M.vimade_id_cache[cache_key] = M.create_highlight(cache_key, base, target, fade)
      vimade_attrs = vimade_hi['attrs']
      
      to_create.append('noautocmd hi vimade_' + str(vimade_hi['id']) \
        + ' ctermfg=' + str(vimade_attrs[0]) \
        + ' ctermbg=' + str(vimade_attrs[1]) \
        + ' guifg=' + vimade_attrs[2] \
        + ' guibg=' + vimade_attrs[3] \
        + ' guisp=' + vimade_attrs[4])

    vimade_hi['windows'][win.winid] = True
    result.append(vimade_hi['id'])

    lookup = M.win_lookup.get(win.winid)
    if not lookup:
      lookup = M.win_lookup[win.winid] = {}
    lookup[vimade_hi['id']] = vimade_hi

  if len(to_create):
    # non-blocking, but must execute before matchaddpos is called for Vim.  This happens naturally
    # due to the ordering of logic in IPC (command is explicitly called before eval)
    IPC.batch_command('|'.join(to_create))

  return result

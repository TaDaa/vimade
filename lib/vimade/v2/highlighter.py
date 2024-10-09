import sys
import vim
M = sys.modules[__name__]

from vimade.v2.state import globals as GLOBALS
from vimade.v2.util import color as COLOR_UTIL
from vimade.v2.modifiers import fade as FADE
from vimade.v2.util import ipc as IPC
from vimade.v2.util import type as TYPE
from vimade.v2.util.promise import Promise

IS_NVIM = GLOBALS.is_nvim

M.next_id = 0
M.free_ids = []
M.hl_name_cache = {}
M.base_id_cache = {}
M.vimade_id_cache = {}
M.win_lookup = {}

HAS_NVIM_GET_HL = bool(int(GLOBALS.features['has_nvim_get_hl']))
_process_hl_results = None
def _process_nvim_get_hl(results):
  for i, value in enumerate(results):
    ctermfg = value.get('ctermfg')
    ctermbg = value.get('ctermbg')
    fg = value.get('fg')
    bg = value.get('bg')
    sp = value.get('sp')
    results[i] = {
        'ctermfg': int(ctermfg) if ctermfg != None else None,
        'ctermbg': int(ctermbg) if ctermbg != None else None,
        'fg': int(fg) if fg != None else None,
        'bg': int(bg) if bg != None else None,
        'sp': int(sp) if sp != None else None}
  return results

def _process_nvim_get_hi(results):
  return [{
    'ctermfg': int(r[0]) if int(r[0]) > -1 else None,
    'ctermbg': int(r[1]) if int(r[1]) > -1 else None,
    'fg': int(r[2]) if int(r[2]) > -1 else None,
    'bg': int(r[3]) if int(r[3]) > -1 else None,
    'sp': int(r[4]) if int(r[4]) > -1 else None} for r in results]
def _process_vim_get_hi(input):
  results = []
  for i, hi in enumerate(input):
    if hi[0] and hi[0][0] == '#' or hi[1] and hi[1][0] == '#' or hi[2] and hi[2][0] == '#':
      results.append({
        'ctermfg': None,
        'ctermbg': None,
        'fg': int(hi[0][1:], 16) if hi[0] != '' else None,
        'bg': int(hi[1][1:], 16) if hi[1] != '' else None,
        'sp': int(hi[2][1:], 16) if hi[2] != '' else None,
      })
    else:
      results.append({
        'ctermfg': int(hi[0]) if hi[0] else None,
        'ctermbg': int(hi[1]) if hi[1] else None,
        'fg': None,
        'bg': None,
        'sp': None,
      })
  return results

if IS_NVIM:
  if HAS_NVIM_GET_HL:
    hi_string = "nvim_get_hl(0,{'id':%s,'link':0})"
    _process_hl_results = _process_nvim_get_hl
  else:
    hi_string = "vimade#GetNvimHi(%s)" 
    _process_hl_results = _process_nvim_get_hi
else:
    hi_string = "vimade#GetHi(%s)" 
    _process_hl_results = _process_vim_get_hi

# vim/nvim are limited by 20000 highlights, so we need to be efficient and
# reuse our created highlights everytime possible.
def _get_next_id():
  if len(M.free_ids) > 0:
    return M.free_ids.pop()
  M.next_id += 1
  next_id = M.next_id
  return next_id

def get_hl_for_ids(win, ids):
  result = Promise()
  def next(ids):
    def next(value):
      if _process_hl_results:
        value = _process_hl_results(value)
      result.resolve(value)
    IPC.batch_eval_and_return('['+','.join([hi_string % id for id in ids])+']').then(next)

  _get_hl_ids_for_names(win, ids).then(next)
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
  def next(ids):
    for id in ids:
      cache_key = str(id)
      if cache_key in M.base_id_cache:
        del M.base_id_cache[cache_key]
  _get_hl_ids_for_names(win, ids).then(next)

def clear_base_cache():
  M.base_id_cache = {}

# ensure we have valid ids for the highlighting process, otherwise
# get them.
def _get_hl_ids_for_names(win, to_process):
  to_process = to_process[0:]
  name_index_map = {}
  id_eval = []
  names = []
  cnt = 0
  promise = Promise()
  win_original = win['original_wincolor'] or 'Normal'
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

  def next(ids):
    for i,id in enumerate(ids):
      id = int(id)
      name = names[i]
      M.hl_name_cache[name] = id
      for j, o_id in enumerate(to_process):
        if o_id == name:
          to_process[j] = id
    promise.resolve(to_process)

  if len(id_eval):
    IPC.batch_eval_and_return('[' + ','.join(id_eval) + ']').then(next)
  else:
    promise.resolve(to_process)

  return promise

def create_vimade_0():
  # TODO cleanup naming, provider the minimum data needed from win to create vimade_0
  win_config = {
       'tint': None, # TODO remove
       'wincolorhl': None,
       'winid': -1,
       'winhl': -1,
       'original_wincolor': None,
       'hi_key': 'global',
   }
  win_config['modifiers']=[FADE.Fade(0.4)(win_config)]
  def next(value):
    (wincolor, normal) = value
    win_config['wincolorhl'] = defaultWincolorHi(wincolor, normal)
    def next(replacement):
      IPC.batch_command('hi! default link vimade_0 vimade_' + str(replacement[0]))
    create_highlights(win_config, [GLOBALS.normalncid if IS_NVIM else GLOBALS.normalid]).then(next)
  get_hl_for_ids(win_config, [GLOBALS.normalncid if IS_NVIM else GLOBALS.normalid, GLOBALS.normalid]) \
    .then(next)
 
def defaultHi(hi, default):
  if hi['ctermfg'] == None and default['ctermfg'] != None:
    hi['ctermfg'] = default['ctermfg']
  if hi['ctermbg'] == None and default['ctermbg'] != None:
    hi['ctermbg'] = default['ctermbg']
  if hi['fg'] == None and default['fg'] != None:
    hi['fg'] = default['fg']
  if hi['bg'] == None and default['bg'] != None:
    hi['bg'] = default['bg']
  if hi['sp'] == None and default['sp'] != None:
    hi['sp'] = default['sp']
  return hi

def defaultWincolorHi(wincolorhl, normalhl):
  if normalhl['ctermfg'] == None:
    normalhl['ctermfg'] = 255 if GLOBALS.is_dark else 0
  if normalhl['ctermbg'] == None:
    normalhl['ctermbg'] = 0 if GLOBALS.is_dark else 255
  if normalhl['fg'] == None:
    normalhl['fg'] = 0xFFFFFF if GLOBALS.is_dark else 0x0
  if normalhl['bg'] == None:
    normalhl['bg'] = 0x0 if GLOBALS.is_dark else 0xFFFFFF
  if normalhl['sp'] == None:
    normalhl['sp'] = normalhl['fg']
  return defaultHi(wincolorhl, normalhl)

def create_highlights(win, to_process, skip_transpose = False):
  promise = Promise()
  def next(to_process):
    tint = win['tint']
    wincolorhl = win['wincolorhl']
    normal_fg = wincolorhl['fg']
    normal_bg = wincolorhl['bg']
    normal_sp = wincolorhl['sp']
    normal_ctermfg = wincolorhl['ctermfg']
    normal_ctermbg = wincolorhl['ctermbg']
    fg_wincolorhl = {
      'ctermfg': wincolorhl['ctermfg'],
      'ctermbg': None,
      'fg': wincolorhl['fg'],
      'bg': None,
      'sp': None,
    } if not skip_transpose else {
      'ctermfg': None,
      'ctermbg': None,
      'fg': None,
      'bg': None,
      'sp': None,
    }
    base_key_suffix = 'c' if skip_transpose else ''

    target = {
      'ctermfg': normal_ctermfg,
      'ctermbg': normal_ctermbg,
      'fg': normal_fg,
      'bg': normal_bg,
      'sp': normal_sp }

    result = []
    attrs_eval = []

    base_keys = []
    for id in to_process:
      cache_key = str(id) + base_key_suffix
      M.base_id_cache[cache_key] = {}
      base_keys.append(cache_key)
      attrs_eval.append(hi_string % id)

    if len(attrs_eval):
      # TODO worth batching?
      attrs = IPC.eval_and_return('[' + ','.join(attrs_eval) + ']')
      if _process_hl_results:
        attrs = _process_hl_results(attrs)

      for i, cache_key in enumerate(base_keys):
        base = M.base_id_cache[cache_key]
        base_hi = defaultHi(attrs[i], fg_wincolorhl)
        base['hi'] = base_hi
        base['base_key'] = str(base_hi['ctermfg']) + ',' + str(base_hi['ctermbg']) + ',' + str(base_hi['fg']) + ',' + str(base_hi['bg']) + ',' + str(base_hi['sp'])

    to_create = []
    modifiers = win['modifiers']

    for id in to_process:
      base = M.base_id_cache[str(id) + base_key_suffix]
      base_hi = base['hi']
      cache_key = base['base_key'] + ':' + win['hi_key']
      vimade_hi = M.vimade_id_cache.get(cache_key)
      if not vimade_hi:
        # selective copy (we cache other keys that should not be exposed)
        hi_attrs = {
            'ctermfg': base_hi['ctermfg'],
            'ctermbg': base_hi['ctermbg'],
            'fg': base_hi['fg'],
            'bg': base_hi['bg'],
            'sp': base_hi['sp'] }
        # copy the target for the modifier run
        hi_target = TYPE.shallow_copy(target)
        for mod in modifiers:
          mod['modify'](hi_attrs, hi_target)
        vimade_hi = {
          'id': _get_next_id(),
          'cache_key': cache_key,
          'windows': {},
          'attrs': hi_attrs,
        }
        M.vimade_id_cache[cache_key] = vimade_hi
        vimade_attrs = vimade_hi['attrs']
        
        fg = vimade_attrs['fg']
        bg = vimade_attrs['bg']
        sp = vimade_attrs['sp']
        ctermfg = vimade_attrs['ctermfg']
        ctermbg = vimade_attrs['ctermbg']
        to_create.append('noautocmd hi vimade_' + str(vimade_hi['id']) \
          + ' ctermfg=' + (str(ctermfg) if type(ctermfg) == int else 'NONE') \
          + ' ctermbg=' + (str(ctermbg) if type(ctermbg) == int else 'NONE') \
          + ' guifg=' + ('#' + hex(fg)[2:].zfill(6) if type(fg) == int else 'NONE') \
          + ' guibg=' + ('#' + hex(bg)[2:].zfill(6) if type(bg) == int else 'NONE') \
          + ' guisp=' + ('#' + hex(sp)[2:].zfill(6) if type(sp) == int else 'NONE'))

      result.append(vimade_hi['id'])
      if win:
        winid = win['winid']
        vimade_hi['windows'][winid] = True
        lookup = M.win_lookup.get(winid)
        if not lookup:
          lookup = M.win_lookup[winid] = {}
        lookup[vimade_hi['id']] = vimade_hi

    if len(to_create):
      # non-blocking, but must execute before matchaddpos is called for Vim.  This happens naturally
      # due to the ordering of logic in IPC (command is explicitly called before eval)
      IPC.batch_command('|'.join(to_create))
    promise.resolve(result)

  _get_hl_ids_for_names(win, to_process).then(next)

  return promise

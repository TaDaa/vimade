import sys
import vim
M = sys.modules[__name__]

from vimade.v2.state import globals as GLOBALS
from vimade.v2.util import color as COLOR_UTIL
from vimade.v2.style import fade as FADE
from vimade.v2.util import ipc as IPC
from vimade.v2.util import type as TYPE
from vimade.v2.util.promise import Promise

IS_NVIM = GLOBALS.is_nvim

def __initWinState(WinState):
  M.global_win = WinState({'winid': -1})
  M.global_win.wincolorhl = None
  M.global_win.winhl = -1
  M.global_win.original_wincolor = None
  M.global_win.hi_key = 'global'
M.__initWinState = __initWinState

M.next_id = 0
M.free_ids = []
M.name_id_lookup = {}
M.id_name_lookup = {}
M.base_id_cache = {}
M.vimade_id_cache = {}
M.win_lookup = {}

def _process_hl_results(input, ids):
  results = []
  for i, hi in enumerate(input):
    id = int(ids[i])
    if hi[0] and hi[0][0] == '#' or hi[1] and hi[1][0] == '#' or hi[2] and hi[2][0] == '#':
      results.append({
        'name': M.id_name_lookup[id],
        'ctermfg': None,
        'ctermbg': None,
        'fg': int(hi[0][1:], 16) if hi[0] != '' else None,
        'bg': int(hi[1][1:], 16) if hi[1] != '' else None,
        'sp': int(hi[2][1:], 16) if hi[2] != '' else None,
      })
    else:
      results.append({
        'name': M.id_name_lookup[id],
        'ctermfg': int(hi[0]) if hi[0] else None,
        'ctermbg': int(hi[1]) if hi[1] else None,
        'fg': None,
        'bg': None,
        'sp': None,
      })
  return results

# Neovim highlight inspection doesn't propertly understand what the global hl is supposed
# to be if winhl also exists. (see https://github.com/TaDaa/vimade/issues/81)
# there isn't any performance difference doing this the vim way, but should look into optimizing
# this more later.
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
  result = Promise()
  def next(ids):
    def next(value):
      value = _process_hl_results(value, ids)
      result.resolve(value)
    IPC.batch_eval_and_return('['+','.join([hi_string % id for id in ids])+']').then(next)

  _get_hl_name_and_ids_for(win, ids).then(next)
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
  _get_hl_name_and_ids_for(win, ids).then(next)

def clear_base_cache():
  M.base_id_cache = {}

# ensure we have valid ids for the highlighting process, otherwise
# get them.
def _get_hl_name_and_ids_for(win, to_process):
# def _get_hl_ids_for_names(win, to_process):
  to_process = to_process[0:]
  name_index_map = {}
  id_index_map = {}
  id_eval = []
  names = []
  ids = []
  name_eval = []
  promise = Promise()
  win_original = win['original_wincolor'] or 'Normal'

  for i, id_or_name in enumerate(to_process):
    id_or_name = id_or_name or win_original
    if type(id_or_name) == int:
      id = id_or_name
      name = M.id_name_lookup.get(id)
      if name == None:
        if not id in id_index_map:
          id_index_map[id] = True
          ids.append(id)
          id_eval.append('synIDattr(%d, "name")' % id)
    elif type(id_or_name) == str:
      name = id_or_name
      id = M.name_id_lookup.get(name)
      if id == None:
        if not name in name_index_map:
          name_index_map[name] = True
          names.append(name)
          name_eval.append('hlID("%s")' % name)
      else:
        to_process[i] = id

  def next(value):
    (ids_for_names, names_for_ids) = value
    for i,id in enumerate(ids_for_names):
      id = int(id)
      name = names[i]
      M.name_id_lookup[name] = id
      M.id_name_lookup[id] = name
      for j, o_id in enumerate(to_process):
        if o_id == name:
          to_process[j] = id
    for i, name in enumerate(names_for_ids):
      id = int(ids[i])
      M.id_name_lookup[id] = name
      M.name_id_lookup[name] = id
    promise.resolve(to_process)

  if len(name_eval) or len(id_eval):
    IPC.batch_eval_and_return('[[' + ','.join(name_eval) + '], ['+ ','.join(id_eval) +']]').then(next)
  else:
    promise.resolve(to_process)

  return promise

def create_vimade_0():
  # TODO cleanup naming, provider the minimum data needed from win to create vimade_0
  s = FADE.DEFAULT.attach(global_win)
  s.before()
  global_win.style = [s]
  # win_config['style']=[s]
  def next(value):
    (wincolor, normal) = value
    global_win.wincolorhl = defaultWincolorHi(wincolor, normal)
    def next(replacement):
      IPC.batch_command('hi! default link vimade_0 vimade_' + str(replacement[0]))
    create_highlights(global_win, [GLOBALS.normalncid if IS_NVIM else GLOBALS.normalid]).then(next)
  get_hl_for_ids(global_win, [GLOBALS.normalncid if IS_NVIM else GLOBALS.normalid, GLOBALS.normalid]) \
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
    wincolorhl = win['wincolorhl']
    normal_fg = wincolorhl['fg']
    normal_bg = wincolorhl['bg']
    normal_sp = wincolorhl['sp']
    normal_ctermfg = wincolorhl['ctermfg']
    normal_ctermbg = wincolorhl['ctermbg']
    fg_wincolorhl = {
      'name': '',
      'ctermfg': wincolorhl['ctermfg'],
      'ctermbg': None,
      'fg': wincolorhl['fg'],
      'bg': None,
      'sp': None,
    } if not skip_transpose else {
      'name': '',
      'ctermfg': None,
      'ctermbg': None,
      'fg': None,
      'bg': None,
      'sp': None,
    }
    base_key_suffix = 'c' if skip_transpose else ''

    target = {
      'name': '',
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
      if not cache_key in M.base_id_cache:
        M.base_id_cache[cache_key] = {}
        base_keys.append(cache_key)
        attrs_eval.append(hi_string % id)

    if len(attrs_eval):
      # This is unsafe to batch mostly due to basegroups.  The issue is that basegroups are already linked
      # then async op here to redo the highlights can cause a visual skip showing the wrong color
      # this occurs b/c another window might redo the highlight due to clear_color on the current window.
      # There is a performance gain but it's not worth maintaining the logic.
      attrs = IPC.eval_and_return('[' + ','.join(attrs_eval) + ']')
      attrs = _process_hl_results(attrs, to_process)
      for i, cache_key in enumerate(base_keys):
        base = M.base_id_cache.get(cache_key)
        base_hi = defaultHi(attrs[i], fg_wincolorhl)
        base['hi'] = base_hi
        base['base_key'] = str(base_hi['ctermfg']) + ',' + str(base_hi['ctermbg']) + ',' + str(base_hi['fg']) + ',' + str(base_hi['bg']) + ',' + str(base_hi['sp'])
    to_create = []
    style = win['style']
    for id in to_process:
      base = M.base_id_cache[str(id) + base_key_suffix]
      base_hi = base['hi']
      # selective copy (we cache other keys that should not be exposed)
      # copy the target for the style run
      hi_attrs = {
          'name': base_hi['name'], # base name
          'ctermfg': base_hi['ctermfg'],
          'ctermbg': base_hi['ctermbg'],
          'fg': base_hi['fg'],
          'bg': base_hi['bg'],
          'sp': base_hi['sp'] }
      hi_target = TYPE.shallow_copy(target)
      for s in style:
        s.modify(hi_attrs, hi_target)
      cache_key = win['hi_key'] + ':' + base['base_key'] + ':' + str(hi_attrs['ctermfg']) + ',' + str(hi_attrs['ctermbg']) + ',' + str(hi_attrs['fg']) + ',' + str(hi_attrs['bg']) + ',' + str(hi_attrs['sp'])
      vimade_hi = M.vimade_id_cache.get(cache_key)

      if not vimade_hi:
        vimade_hi = {
          'id': _get_next_id(),
          'cache_key': cache_key,
          'windows': {},
          'attrs': hi_attrs,
        }
        M.vimade_id_cache[cache_key] = vimade_hi
        
        fg = hi_attrs['fg']
        bg = hi_attrs['bg']
        sp = hi_attrs['sp']
        ctermfg = hi_attrs['ctermfg']
        ctermbg = hi_attrs['ctermbg']
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

  _get_hl_name_and_ids_for(win, to_process).then(next)

  return promise

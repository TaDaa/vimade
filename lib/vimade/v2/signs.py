import re
import sys

M = sys.modules[__name__]

from vimade.v2.util import ipc as IPC
from vimade.v2.util.promise import Promise, all
from vimade.v2.state import globals as GLOBALS
from vimade.v2 import highlighter as HIGHLIGHTER

HAS_SIGN_GROUP = bool(int(GLOBALS.features['has_sign_group']))
HAS_SIGN_PRIORITY = bool(int(GLOBALS.features['has_sign_priority']))
HAS_SIGN_GET_PLACED = bool(int(GLOBALS.features['has_sign_getplaced']))
HAS_SIGN_GET_PLACED_AND_GROUPS = HAS_SIGN_GROUP and HAS_SIGN_GET_PLACED
IS_NVIM = GLOBALS.is_nvim


VIMADE_GROUP_TEXT = ' group=vimade' if HAS_SIGN_GROUP else ''

M._sign_cache = {}
M._buffer_cache = {}
M._free_ids = []
M._id = -1
M._win_lookup = {}

def _get_next_id():
  if len(M._free_ids):
    return M._free_ids.pop()
  else:
    M._id += 1
    return GLOBALS.signsid + M._id
  return 

def _parse_get_signs_parts(line):
  parts = re.split(r'[\s\t]+', line)
  item = {}
  for part in parts:
    split = part.split('=')
    if len(split) < 2:
      continue
    (key, value) = split
    item[key] = value
  return item


READY = 0
HAS_FADED_WINDOWS = 1
HAS_UNFADED_WINDOWS = 2

def _setup():
  M._buffer_cache = {}

def clear_win(win):
  winid = win.winid
  lookup = M._win_lookup.get(winid)
  bufnr = win.bufnr
  buf = M._buffer_cache.get(bufnr)
  # TODO need to cleanup this async logic.  Seems to be working, but it needs a clear control flow
  if buf and buf['owner_win'] == win:
    buf['owner_win'] = None

  def next(signs):
    undefine_eval = []
    if lookup:
      _do_unfade(bufnr, signs, win)
      for name in list(lookup.keys()):
        del lookup[name]
        cached = M._sign_cache[name]
        del cached['windows'][winid]
        if len(cached['windows'].keys()) == 0:
          del M._sign_cache[name]
        undefine_eval.append('silent! noautocmd sign undefine vimade_' + name)
      # If counts are right, the signs are removed.  This is guarenteed to occur before
      # they could be added again.
      IPC.batch_command('function! VimadeSignTemp()\n' + ('\n'.join(undefine_eval)) + '\nendfunction \n call VimadeSignTemp()')

  # This logic can be batched, its just difficult to understand and not really maintainable.
  # Safer to get the signs and remove them immediately.
  IPC.batch_eval_and_return(
    'bufexists('+str(bufnr)+') ? get(sign_getplaced('+str(bufnr)+',{"group": "*"})[0], "signs", []) : []' if HAS_SIGN_GET_PLACED_AND_GROUPS else \
            'bufexists('+str(bufnr)+') ? get(getbufinfo('+str(bufnr)+')[0], "signs", []) : []').then(next)

# For now we just say the last window wins. This ensures our signs are associated with
# highlights that are used on a window for that buffer. There isn't really a solution
# here that 100% works, this is just best effort.  Neovim users can use lua renderer
# for a real solution.
def _get_buffer_from_cache(bufnr):
  buf = M._buffer_cache.get(bufnr)
  if not buf:
    M._buffer_cache[bufnr] = buf = {
      'bufnr': bufnr,
      'visible_rows': {},
      'state': READY,
      'owner_win': None,
    }
  return buf


def unfade_signs(win):
  buf = M._get_buffer_from_cache(win.bufnr)
  buf['state'] |= HAS_UNFADED_WINDOWS

# collect the visible rows so that we know what should be faded. The actual fading is initiated
# later (see fader.py)
def fade_signs(win, visible_rows):
  bufnr = win.bufnr
  buf = M._get_buffer_from_cache(bufnr)
  buf['state'] |= HAS_FADED_WINDOWS
  if not buf['owner_win']:
    buf['owner_win'] = win
  buf_visible_rows = buf['visible_rows']
  for row in visible_rows:
    buf_visible_rows[row[0]] = True

def _do_unfade(bufnr, signs, win):
  unfade_eval = []
  for sign in signs:
    if sign['name'][0:7] == 'vimade_':
      id = sign['id']
      unfade_eval.append('silent! noautocmd sign unplace ' + id + VIMADE_GROUP_TEXT + ' buffer='+str(bufnr))
      M._free_ids.append(id)
  if len(unfade_eval):
    return IPC.batch_command('function! VimadeSignTemp()\n' + ('\n'.join(unfade_eval)) + '\nendfunction \n call VimadeSignTemp()')

def _do_create(bufnr, win, names):
  promise = Promise()
  names = list(set(names))
  def create_highlights(results):
    highlights = []
    skip_transpose_highlights = []
    for i, result in enumerate(results):
      item = _parse_get_signs_parts(result)
      results[i] = item
      texthl = item.get('texthl')
      linehl = item.get('linehl')
      numhl = item.get('numhl')
      if texthl and texthl != 'NONE':
        highlights.append(texthl)
      if linehl and linehl !='NONE':
        skip_transpose_highlights.append(linehl)
      if numhl and numhl != 'NONE':
        skip_transpose_highlights.append(numhl)
    if len(highlights) == 0:
      promise.resolve(None)
      return
    def create_definitions(input):
      (replacements, skip_transpose_replacements) = input
      j = 0
      k = 0
      definitions = []
      normalid = GLOBALS.normalid
      normalncid = GLOBALS.normalncid
      for i, item in enumerate(results):
        # create another sign that links to either Normal (for vim)
        # and NormalNC for Neovim (to be used if basegroups enabled)
        name = 'vimade_' + names[i][0]
        text = item.get('text', '')
        icon = item.get('icon', '')
        texthl = item.get('texthl', '')
        linehl = item.get('linehl', '')
        numhl = item.get('numhl', '')
        definition = 'sign define ' + name + \
            (' text=' + text) if text else '' + \
            (' icon=' + icon) if icon else ''
        if texthl and texthl != 'NONE':
          texthl_id = replacements[j]
          j += 1
        else:
          texthl_id = normalncid if IS_NVIM else normalid
        if linehl and linehl !='NONE':
          definition += ' linehl=vimade_' + str(skip_transpose_replacements[k])
          k += 1
        if numhl and numhl != 'NONE':
          definition += ' numhl=vimade_' + str(skip_transpose_replacements[k])
          k += 1
        definition += ' texthl=vimade_' + str(texthl_id)
        definitions.append(definition)
      if len(definitions) == 0:
        promise.resolve(None)
      else:
        IPC.batch_command('function! VimadeSignTemp()\n' + ('\n'.join(definitions)) + '\nendfunction \n call VimadeSignTemp()').then(promise)
    # Associated with a single win. This means when a win is cleared, signs owned by that win also need to be cleared.
    # TODO we should event drive the window logic and let HIGHLIGHTER and SIGNS clear off event. For now this only
    # happens in namespace.py so should be fine in the short term.
    all([
        HIGHLIGHTER.create_highlights(win, highlights),
        HIGHLIGHTER.create_highlights(win, skip_transpose_highlights, True)
    ]).then(create_definitions)
  if len(names):
    IPC.batch_eval_and_return('[' + ','.join(['execute("sign list ' + name[1] +'")' for name in names]) + ']')\
        .then(create_highlights)
    return promise
  return promise.resolve(None)

def _do_fade(bufnr, visible_rows, signs, win):
  lines = {}
  vimade_signs = {}
  other_signs = {}
  winid = win.winid
  # categorize the signs into vimade and non-vimade groups so we can clearly see what needs to be replaced.
  for sign in signs:
    lnum = sign.get('lnum')
    if lnum == None or (not lnum in visible_rows):
      continue
    name = sign['name']
    # Can result due to undefine process, these needs to removed / skipped
    if name == '[Deleted]':
      continue
    sign['priority'] = priority = int(sign.get('priority', 0))
    is_vimade = name[0:7] == 'vimade_'
    if is_vimade:
      sign['hi_name'] = name[7:]
      vimade_line = vimade_signs.get(lnum)
      if not vimade_line:
        vimade_signs[lnum] = vimade_line = []
      vimade_line.append(sign)
    else:
      existing_sign = other_signs.get(lnum)
      if not existing_sign:
        other_signs[lnum] = sign
        sign['hi_name'] = win.hi_key + ':' + sign['name']
      elif existing_sign['priority'] < sign['priority']:
        other_signs[lnum] = sign
        sign['hi_name'] = win.hi_key + ':' + sign['name']
  # Vimade replacement signs that aren't needed anymore need to be removed.
  remove_eval = []
  for line, v_signs in vimade_signs.items():
    for vimade_sign in v_signs:
      other_sign = other_signs.get(line)
      # Sign doesn't match the highest priority one, then remove the vimade version as its not visible.
      if not other_sign or vimade_sign['hi_name'] != other_sign['hi_name']:
        id = vimade_sign['id']
        M._free_ids.append(id)
        remove_eval.append('silent! noautocmd sign unplace ' + id + VIMADE_GROUP_TEXT + ' buffer=' + str(bufnr))

  # anything not found in vimade_signs needs to be added
  add_eval = []
  to_create = []
  for line, other_sign in other_signs.items():
    vimade_line = vimade_signs.get(line)
    if not vimade_line or len(vimade_line) == 0:
      name = other_sign['hi_name']
      cached_sign = M._sign_cache.get(name)
      # window lookups are still needed because a sign can have a shared key across many owner_wins
      if not cached_sign:
        M._sign_cache[name] = cached_sign = {'windows': {}}
      if not winid in cached_sign['windows']:
        cached_sign['windows'][winid] = True
        lookup = M._win_lookup.get(winid)
        if not lookup:
          M._win_lookup[winid] = lookup ={}
        lookup[name] = True
        to_create.append((name, other_sign['name']))
      add_eval.append('silent! noautocmd sign place ' \
          + str(_get_next_id()) \
          + VIMADE_GROUP_TEXT \
          + ' line='+str(other_sign['lnum']) \
          + ' name=vimade_' + str(name) \
          + ((' priority=' + str(GLOBALS.signspriority)) if HAS_SIGN_PRIORITY else '') \
          + ' buffer=' + str(bufnr))

  def add_signs(value):
    if len(add_eval):
      IPC.batch_command('function! VimadeSignTemp() \n' + ('\n'.join(add_eval)) + '\nendfunction \n call VimadeSignTemp()')

  IPC.batch_command('|'.join(remove_eval)),
  _do_create(bufnr, win, to_create).then(add_signs)

def flush():
  bufs = list(M._buffer_cache.values())
  M._buffer_cache = {}
  promise = Promise()

  def next(infos):
    changes = []
    names = []
    sign_lookup_eval = []
    for i, signs in enumerate(infos):
      buf = bufs[i]
      state = buf['state']
      # A sign can be on a faded and unfaded window simultaneously because they are only supported on buffers.
      # In this case, we prioritize fading.
      if (state & HAS_FADED_WINDOWS) > 0:
        _do_fade(buf['bufnr'], buf['visible_rows'], signs, buf['owner_win'])
      elif (state & HAS_UNFADED_WINDOWS) > 0:
        _do_unfade(buf['bufnr'], signs, buf['owner_win'])

  IPC.batch_eval_and_return('[' + \
      ','.join( \
        ['bufexists(' + str(x['bufnr']) + ') ? get(sign_getplaced(' + str(x['bufnr']) + ',{"group": "*"})[0], "signs", []) : []' for x in bufs] if HAS_SIGN_GET_PLACED_AND_GROUPS else \
        ['bufexists(' + str(x['bufnr']) + ') ? get(getbufinfo(' + str(x['bufnr']) + ')[0], "signs", []) : []' for x in bufs ]) + ']').then(next)

  return IPC.flush_batch()

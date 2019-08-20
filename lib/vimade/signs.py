import re
import time
import vim
from vimade import global_state as GLOBALS
from vimade import highlighter

SIGN_CACHE = {}
PLACES = []
SIGN_IDS_UNUSED = []
SIGN_ID_NEXT = 131000
def parseParts(line):
  parts = re.split('[\s\t]+', line)
  item = {}
  for part in parts:
    split = part.split('=')
    if len(split) < 2:
      continue
    (key, value) = split
    item[key] = value
  return item

def get_signs(bufnr):
  lines = vim.eval('execute("silent sign place buffer='+str(bufnr)+'")').split('\n')[2:]
  result = []
  for line in lines:
    item = parseParts(line)
    if 'name' in item:
      result.append(item)
  return result

def unfade_bufs(bufs):
  global PLACES
  global SIGN_IDS_UNUSED

  start = time.time()
  infos = vim.eval('[' + ','.join(['get(getbufinfo('+x+')[0],"signs",[])' for x in bufs ]) + ']' )

  changes = []
  i = 0
  for signs in infos:
    bufnr = bufs[i]
    i += 1
    for sign in signs:
      name = sign['name']
      sign['bufnr'] = bufnr
      if name.startswith('vimade_'):
        changes.append(sign)

  if len(changes):
    place = []
    for sign in changes:
      SIGN_IDS_UNUSED.append(sign['id'])
      PLACES.append('sign unplace ' + sign['id'] + ' buffer='+sign['bufnr'])

  if len(PLACES):
    cmdheight = int(vim.eval('&cmdheight'))
    vim.command('function! VimadeSignTemp() \n' + '\n'.join(PLACES) + '\nendfunction')
    try:
      vim.command('call VimadeSignTemp()')
    except:
      pass
    PLACES = []
  # print('unfade',(time.time() - start) * 1000)

def fade_bufs(bufs):
  global SIGN_ID_NEXT
  global SIGN_IDS_UNUSED
  start = time.time()
  infos = vim.eval('[' + ','.join(['get(getbufinfo('+x+')[0],"signs",[])' for x in bufs ]) + ']' )
  changes = []
  requests = []
  request_names = []
  i = 0
  for signs in infos:
    bufnr = bufs[i]
    i += 1
    for sign in signs:
      name = sign['name']
      sign['bufnr'] = bufnr
      if not name.startswith('vimade_'):
        changes.append(sign)
        if not name in SIGN_CACHE:
          SIGN_CACHE[name] = True
          request_names.append(name)
          requests.append('execute("sign list ' + name + '")')

  ids = []
  if len(requests):
    results = vim.eval('[' + ','.join(requests) + ']')
    i = 0
    for result in results:
      item = parseParts(result)
      name = request_names[i]
      i += 1
      name = 'vimade_' + name
      sign[name] = name
      definition = 'sign define ' + name
      linehl_id = texthl_id = icon = text = None
      if 'text' in item:
        definition += ' text=' + item['text']
      if 'icon' in item:
        definition += ' icon=' + item['icon']
      if 'texthl' in item:
        texthl_id = vim.eval('hlID("'+item['texthl']+'")')
      else:
        texthl_id = GLOBALS.normal_id
      ids.append(texthl_id)
      definition += ' texthl=vimade_' + texthl_id

      # linehl adds high performance hit -- maybe add toggle for this
      # if 'linehl' in item:
        # linehl_id = vim.eval('hlID("'+item['linehl']+'")')
        # if linehl_id:
          # ids.append(linehl_id)
        # definition += ' linehl=vimade_' + linehl_id
      vim.command(definition)

  if len(ids):
    highlighter.fade_ids(ids)

  if len(changes):
    place = []
    for sign in changes:
      if len(SIGN_IDS_UNUSED):
        next_id = SIGN_IDS_UNUSED.pop(0)
      else:
        next_id = SIGN_ID_NEXT
        SIGN_ID_NEXT = SIGN_ID_NEXT + 1
      PLACES.append('sign place ' +  str(next_id) + ' line='+sign['lnum'] + ' name=vimade_' + sign['name'] + ' buffer=' + sign['bufnr'])
  # print('fade',(time.time() - start) * 1000)




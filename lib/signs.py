import re
import time
import global_state as GLOBALS
import vim
import vimade
import highlighter
import fader as FADE

SIGN_CACHE = {}
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
  start = time.time()
  FADE.prevent = True
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
      place.append('sign place ' + sign['id'] + ' name=' + sign['name'][7:] + ' buffer='+sign['bufnr'])
    vim.command('function! VimadeSignTemp() \n' + '\n'.join(place) + '\nendfunction')
    vim.command('redraw | call VimadeSignTemp()')

  FADE.prevent = False
  # print('unfade',(time.time() - start) * 1000)

def fade_bufs(bufs):
  start = time.time()
  FADE.prevent = True
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

      if 'linehl' in item:
        linehl_id = vim.eval('hlID("'+item['linehl']+'")')
        if linehl_id:
          ids.append(linehl_id)
        definition += ' linehl=vimade_' + linehl_id
      vim.command(definition)

  if len(ids):
    highlighter.fade_ids(ids)

  if len(changes):
    place = []
    for sign in changes:
      place.append('sign place ' + sign['id'] + ' name=vimade_' + sign['name'] + ' buffer=' + sign['bufnr'] )

    #batch commands within a function (higher nvim perf)
    vim.command('function! VimadeSignTemp() \n'+ '\n'.join(place) + '\nendfunction')
    vim.command('redraw | call VimadeSignTemp()')
  FADE.prevent = False
  # print('fade',(time.time() - start) * 1000)




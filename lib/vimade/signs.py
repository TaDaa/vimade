import re
import time
import vim
from vimade import global_state as GLOBALS
from vimade import highlighter

SIGN_CACHE = {}
PLACES = []
SIGN_IDS_UNUSED = []
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
      PLACES.append('sign unplace ' + sign['id'] + GLOBALS.signs_group_text + 'buffer='+sign['bufnr'])

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
    lines = {}
    priorities = {}
    for sign in signs:
      sign['is_vimade'] = sign['name'].find('vimade_') != -1
      if sign['is_vimade']:
        if not 'priority' in sign:
          sign['priority'] = ''
        if not sign['lnum'] in lines:
          lines[sign['lnum']] = {}
        lines[sign['lnum']][sign['name'].split('vimade_')[1]] = sign['priority']
    for sign in signs:
      if not sign['is_vimade']:
        sign['bufnr'] = bufnr
        if GLOBALS.features['has_sign_priority']:
          if not 'priority' in sign:
            priority = GLOBALS.signs_priority
          else:
            priority = int(sign['priority']) + GLOBALS.signs_priority

          if not sign['lnum'] in priorities:
            priorities[sign['lnum']] = {}

          if priority in priorities[sign['lnum']]:
            priority -= 1

          priorities[sign['lnum']][priority] = True
          sign['priority'] = str(priority)
          sign['priority_text'] = ' priority='+sign['priority']
        else:
          sign['priority'] = ''
        if sign['lnum'] in lines and sign['name'] in lines[sign['lnum']] and lines[sign['lnum']][sign['name']] == sign['priority']:
          lines[sign['lnum']][sign['name']] = False
        else:
          changes.append(sign)
          if not sign['lnum'] in lines:
            lines[sign['lnum']] = {}
          lines[sign['lnum']][sign['name']] = False
          if not sign['name'] in SIGN_CACHE:
            SIGN_CACHE[sign['name']] = True
            request_names.append(sign['name'])
            requests.append('execute("sign list ' + sign['name'] + '")')
      for sign in signs:
        if sign['is_vimade']:
          if lines[sign['lnum']][sign['name'].split('vimade_')[1]]:
            SIGN_IDS_UNUSED.append(sign['id'])
            PLACES.append('sign unplace ' + sign['id'] + ' buffer=' + bufnr)

  ids = {}
  if len(requests):
    results = vim.eval('[' + ','.join(requests) + ']')
    i = 0
    j = 0
    k = 0
    cl_highlight_map = {}
    highlight_map = {}
    highlights = []
    cl_highlights = []
    for result in results:
      item = parseParts(result)
      results[i] = item
      if 'texthl' in item and not item['texthl'] in highlight_map:
        highlight_map[item['texthl']] = j
        highlights.append('hlID("'+item['texthl']+'")')
        j += 1
      if 'linehl' in item and not item['linehl'] in highlight_map:
        cl_highlight_map[item['linehl']] = k
        cl_highlights.append('hlID("'+item['linehl']+'")')
        k += 1
      if 'numhl' in item and not item['numhl'] in highlight_map:
        cl_highlight_map[item['numhl']] = k
        cl_highlights.append('hlID("'+item['numhl']+'")')
        k += 1
      i += 1
    
    if len(highlights):
      highlights = vim.eval('[' + ','.join(highlights) + ']')
      highlights = highlighter.fade_ids(highlights)
      cl_highlights = vim.eval('[' + ','.join(cl_highlights) + ']')
      cl_highlights = highlighter.fade_ids(cl_highlights, False, True)

    i = 0
    for item in results:
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
        texthl_id = highlights[highlight_map[item['texthl']]][0]
      else:
        texthl_id = GLOBALS.normal_id
      if 'linehl' in item:
        linehl_id = cl_highlights[cl_highlight_map[item['linehl']]][0]
        definition += ' linehl=' + linehl_id
      if 'numhl' in item:
        numhl_id = cl_highlights[cl_highlight_map[item['numhl']]][0]
        definition += ' numhl=' + numhl_id

      definition += ' texthl=' + texthl_id
      vim.command(definition)

  if len(changes):
    place = []
    for sign in changes:
      if len(SIGN_IDS_UNUSED):
        next_id = SIGN_IDS_UNUSED.pop(0)
      else:
        next_id = GLOBALS.signs_id
        GLOBALS.signs_id = GLOBALS.signs_id + 1
      PLACES.append('sign place ' +  str(next_id) + GLOBALS.signs_group_text + 'line='+sign['lnum'] + ' name=vimade_' + sign['name'] + sign['priority_text'] + ' buffer=' + sign['bufnr'])
  # print('fade',(time.time() - start) * 1000)




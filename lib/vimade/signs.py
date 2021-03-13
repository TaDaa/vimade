import re
import time
import vim
from vimade import util
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
  lines = util.eval_and_return('execute("silent sign place buffer='+str(bufnr)+'")').split('\n')[2:]
  result = []
  for line in lines:
    item = parseParts(line)
    if 'name' in item:
      result.append(item)
  return result

def unfade_bufs(bufs):
  global PLACES
  global SIGN_IDS_UNUSED

  buf_signs = util.eval_and_return('[' + ','.join(['get(getbufinfo('+x.bufnr+')[0], \'signs\', [])' for x in bufs ]) + ']')
  # start = time.time()
  i = 0
  for signs in buf_signs:
    bufnr = bufs[i].bufnr
    i = i + 1
    for sign in signs:
      name = sign['name']
      is_vimade = sign['is_vimade'] = name.find('vimade_') != -1
      if is_vimade == True:
        sign['name'] = name.replace('vimade_', '')
        sign['bufnr'] = bufnr
        if int(GLOBALS.features['has_sign_priority']) and 'priority' in sign:
          sign['priority_text'] = ' priority='+str(sign['priority'])
        if int(GLOBALS.features['has_sign_group']) and 'group' in sign:
          sign['group_text'] = ' group=' + str(sign['group'])
        PLACES.append('silent! sign place ' +  str(sign['id']) + sign['group_text'] + ' line='+str(sign['lnum']) + ' name=' + sign['name'] + sign['priority_text'] + ' buffer=' + str(sign['bufnr']))

  if len(PLACES):
    vim.command('function! VimadeSignTemp() \n' + '\n'.join(PLACES) + '\nendfunction')
    try:
      vim.command('call VimadeSignTemp()')
    except:
      pass
    PLACES = []

def fade_wins(wins, fade_bufs):
  global SIGN_IDS_UNUSED
  start = time.time()

  buf_map = {}
  for win in wins:
    if not win.buffer in buf_map:
      buf_map[win.buffer] = (win.buffer, {})
    vis = buf_map[win.buffer][1]
    for row in win.visible_rows:
      vis[row] = 1
  bufs = list(buf_map.values())

  if len(bufs) == 0:
    return
  infos = util.eval_and_return('[' + ','.join(['vimade#GetSigns('+x[0]+','+ str(x[1]) + ')' for x in bufs ]) + ']' )
  changes = []
  requests = []
  request_names = []
  i = 0

  lines_by_bufs = {}

  for signs in infos:
    bufnr = bufs[i][0]
    i += 1

    if not bufnr in lines_by_bufs:
      lines_by_bufs[bufnr] = ({}, {})

    [lines, priorities] = lines_by_bufs[bufnr]

    for sign in signs:
      name = sign['name']
      is_vimade = sign['is_vimade'] = name.find('vimade_') != -1
      if is_vimade == True:
        real_name = sign['real_name'] = name.split('vimade_')[1]
        lnum = sign['lnum']
        if not 'priority' in sign:
          sign['priority'] = ''
        if not lnum in lines:
          lines[sign['lnum']] = {}
        lines[lnum][real_name] = sign['priority']
    for sign in signs:
      if sign['is_vimade'] == False:
        sign['bufnr'] = bufnr
        lnum = sign['lnum']
        name = sign['name']
        if int(GLOBALS.features['has_sign_group']):
          if not 'group' in sign:
            sign['group_text'] = ''
          else:
            sign['group_text'] = ' group='+str(sign['group'])
        if int(GLOBALS.features['has_sign_priority']):
          if not 'priority' in sign:
            priority = GLOBALS.signs_priority
          else:
            priority = int(sign['priority']) + GLOBALS.signs_priority

          if not lnum in priorities:
            priorities[lnum] = {}

          if priority in priorities[lnum]:
            priority -= 1

          priorities[lnum][priority] = True
          sign['priority'] = str(priority)
          sign['priority_text'] = ' priority='+str(sign['priority'])
        else:
          sign['priority'] = ''
          sign['priority_text'] = ''
        if lnum in lines and name in lines[lnum] and (lines[lnum][name] == sign['priority'] or lines[lnum][name] == False):
          lines[lnum][name] = False
        else:
          changes.append(sign)
          if not lnum in lines:
            lines[lnum] = {}
          lines[lnum][name] = False
          if not name in SIGN_CACHE:
            SIGN_CACHE[name] = True
            request_names.append(name)
            requests.append('execute("sign list ' + name + '")')

  ids = {}
  if len(requests):
    results = util.eval_and_return('[' + ','.join(requests) + ']')
    i = 0
    highlights = []
    cl_highlights = []
    for result in results:
      item = parseParts(result)
      results[i] = item
      if 'texthl' in item:
        highlights.append(item['texthl'])
      if 'linehl' in item:
        cl_highlights.append(item['linehl'])
      if 'numhl' in item:
        cl_highlights.append(item['numhl'])
      i += 1
    
    if len(highlights):
      highlights = highlighter.fade_names(highlights)
      cl_highlights = highlighter.fade_names(cl_highlights, False, True)


    i = 0
    j = 0
    k = 0
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
        texthl_id = highlights[j][0]
        j += 1
      else:
        texthl_id = GLOBALS.normal_id
      if 'linehl' in item:
        linehl_id = cl_highlights[k][0]
        k += 1
        definition += ' linehl=' + linehl_id
      if 'numhl' in item:
        numhl_id = cl_highlights[k][0]
        k += 1
        definition += ' numhl=' + numhl_id

      definition += ' texthl=' + texthl_id
      vim.command(definition)


  if len(changes):
    place = []
    for sign in changes:
      PLACES.append('silent! sign place ' +  str(sign['id']) + sign['group_text'] + ' line='+str(sign['lnum']) + ' name=vimade_' + sign['name'] + sign['priority_text'] + ' buffer=' + str(sign['bufnr']))




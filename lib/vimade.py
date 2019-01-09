import sys
import vim
import math
import time
IS_V3 = False
if (sys.version_info > (3, 0)):
    IS_V3 = True

FADE_LEVEL = None
BASE_HI = [None, None]
BASE_FADE = None
ROW_BUF_SIZE = None
COL_BUF_SIZE = None
NORMAL_ID = None
BASE_BG = ''
BASE_FG = ''
FADE_STATE = {
  'windows' : {},
  'background': '',
  'prevent': False,
  'buffers': {},
  'activeWindow': str(vim.current.window.number),
  'activeBuffer': str(vim.current.buffer.number)
}
HI_CACHE = {}
IS_NVIM = vim.eval('has("nvim")')

def fadeRGBToHex(source, to):
  rgb = [int(math.floor(to[0]+(source[0]-to[0])*FADE_LEVEL)), int(math.floor(to[1]+(source[1]-to[1])*FADE_LEVEL)), int(math.floor(to[2]+(source[2]-to[2])*FADE_LEVEL))]
  return '#' + hex(rgb[0])[2:] + hex(rgb[1])[2:] + hex(rgb[2])[2:]


ERROR = -1
READY = 0
FULL_INVALIDATE = 1
def updateGlobals():
  global ROW_BUF_SIZE
  global COL_BUF_SIZE
  global BASE_HI
  global NORMAL_ID
  global BASE_BG
  global BASE_FG
  global BASE_FADE
  global FADE_LEVEL

  returnState = READY 
  nextGlobals = vim.eval('g:vimade')
  fadelevel = float(nextGlobals['fadelevel'])
  rowbufsize = int(nextGlobals['rowbufsize'])
  colbufsize = int(nextGlobals['colbufsize'])
  basefg = nextGlobals['basefg']
  basebg = nextGlobals['basebg']
  normalid = nextGlobals['normalid']

  ROW_BUF_SIZE = rowbufsize
  COL_BUF_SIZE = colbufsize

  if FADE_LEVEL != fadelevel:
    FADE_LEVEL = fadelevel 
    returnState = FULL_INVALIDATE
  if NORMAL_ID != normalid:
    NORMAL_ID = normalid
    returnState = FULL_INVALIDATE

  if normalid:
    base_hi = vim.eval('vimade#GetHi('+NORMAL_ID+')')
    if not basefg:
      basefg = base_hi[0]
    if not basebg:
      basebg = base_hi[1]

  if basefg and BASE_FG != basefg:
    BASE_HI[0] = BASE_FG = basefg
    returnState = FULL_INVALIDATE
  if basebg and BASE_BG != basebg:
    BASE_HI[1] = BASE_BG = basebg
    returnState = FULL_INVALIDATE

  if returnState == FULL_INVALIDATE and len(BASE_FG) == 7 and len(BASE_BG) == 7:
    BASE_HI[0] = [int(BASE_FG[1:3], 16), int(BASE_FG[3:5], 16), int(BASE_FG[5:7], 16)]
    BASE_HI[1] = [int(BASE_BG[1:3], 16), int(BASE_BG[3:5], 16), int(BASE_BG[5:7], 16)]
    BASE_FADE = fadeRGBToHex(BASE_HI[0], BASE_HI[1])

  if BASE_FG == None or BASE_BG == None or BASE_FADE == None:
    returnState = ERROR

  return returnState



def updateState(nextState = None):
  global HI_CACHE
  if FADE_STATE['prevent']:
    return

  currentWindows = FADE_STATE['windows']
  currentBuffers = FADE_STATE['buffers']

  #Check our globals/settings for changes
  status = updateGlobals()
  #Error condition - just return
  if status == ERROR:
    return

  if FADE_STATE['background'] != nextState['background']:
    FADE_STATE['background'] = nextState['background']
    status = FULL_INVALIDATE

  #Full invalidate - clean cache and unfade all windows + reset buffesr
  if status == FULL_INVALIDATE:
    HI_CACHE = {}
    for winState in currentWindows.values():
      if winState['faded']:
        unfadeWin(winState)
        winState['faded'] = False
    for bufferState in currentBuffers.values():
      bufferState['coords'] = None 

    #TODO remove this code when possible
    #Ideally this return would not be necessary, but oni current requires a hard refresh here
    return


  fade = {}
  unfade = {}

  activeBuffer = nextState["activeBuffer"]
  activeWindow = nextState['activeWindow']
  activeTab = nextState['activeTab']
  updateDiff = nextState['diff'] if nextState and 'diff' in nextState else {'winid': -1, 'value': False}
  activeDiff = int(vim.eval('&diff'))
  nextWindows = {}
  nextBuffers = {}
  diff = []

  FADE_STATE['activeBuffer'] = activeBuffer

  for window in vim.windows:
    winnr = str(window.number)
    winid = str(vim.eval('win_getid('+winnr+')'))
    bufnr = str(window.buffer.number)
    tabnr = str(window.tabpage.number)
    hasActiveBuffer = bufnr == activeBuffer
    hasActiveWindow = winid == activeWindow
    if activeTab != tabnr:
      continue

    nextWindows[winid] = True
    nextBuffers[bufnr] = True
    # window was unhandled -- add to FADE_STATE
    if not bufnr in FADE_STATE['buffers']:
      FADE_STATE['buffers'][bufnr] = {
        'coords': None,
        'last': ''
      }
    if not winid in FADE_STATE['windows']:
      FADE_STATE['windows'][winid] = {
        'win': window,
        'id': winid,
        'diff': False,
        'number': winnr,
	'height': window.height,
	'width': window.width,
	'hasActiveBuffer': hasActiveBuffer,
	'hasActiveWindow': hasActiveWindow,
        'matches': [],
        'invalid': False,
	'cursor': (window.cursor[0], window.cursor[1]),
	'buffer': bufnr,
        'faded': False
      }

    state = FADE_STATE['windows'][winid]
    state['win'] = window
    state['number'] = winnr
    state['buffer'] = bufnr

    if str(updateDiff['winid']) == winid:
      state['diff'] = updateDiff['value']
    elif hasActiveWindow:
      state['diff'] = activeDiff

    if state['diff']:
      diff.append(state)

    # window state changed
    if (window.height != state['height'] or window.width != state['width'] or window.cursor[0] != state['cursor'][0] or window.cursor[1] != state['cursor'][1]):
      state['height'] = window.height
      state['width'] = window.width
      state['cursor'] = (window.cursor[0], window.cursor[1])
      #TODO
      if not hasActiveBuffer:
        fade[winid] = state
    if state['buffer'] != bufnr:
      state['buffer'] = bufnr
    if state['hasActiveBuffer'] != hasActiveBuffer:
      state['hasActiveBuffer'] = hasActiveBuffer
      if hasActiveBuffer:
        unfade[winid] = state
      else:
        fade[winid] = state
    if state['hasActiveWindow'] != hasActiveWindow:
      state['hasActiveWindow'] = hasActiveWindow

    if state['faded'] and hasActiveBuffer:
      unfade[winid] = state
    elif not state['faded'] and not hasActiveBuffer:
      fade[winid] = state


  if activeDiff and len(diff) > 1:
    for state in diff:
      if state['id'] in fade:
        del fade[state['id']]
      if updateDiff['winid'] == -1:
        unfade[state['id']] = state

  for win in list(FADE_STATE['windows'].keys()):
    if not win in nextWindows:
      tabwin = vim.eval('win_id2tabwin('+win+')')
      if tabwin[0] == '0' and tabwin[1] == '0':
        del FADE_STATE['windows'][win]

  for key in list(FADE_STATE['buffers'].keys()):
    if not key in nextBuffers:
      if len(vim.eval('win_findbuf('+key+')')) == 0:
        del FADE_STATE['buffers'][key]

  for win in fade.values():
    fadeWin(win)
    win['faded'] = True
  for win in unfade.values():
    if win['faded']:
      unfadeWin(win)
      win['faded'] = False

def unfadeWin(winState):
  FADE_STATE['prevent'] = True
  lastWin = vim.eval('win_getid('+str(vim.current.window.number)+')')
  matches = winState['matches']
  winid = str(winState['id'])
  if lastWin != winid:
    vim.command('noautocmd call win_gotoid('+winid+')')
  coords = FADE_STATE['buffers'][winState['buffer']]['coords']
  errs = 0
  if coords:
    for items in coords:
      if items:
        for item in items:
          if item and winid in item:
            del item[winid]
  if matches:
    for match in matches:
        vim.command('call matchdelete('+match+')')
  winState['matches'] = []
  if lastWin != winid:
    vim.command('noautocmd call win_gotoid('+lastWin+')')
  FADE_STATE['prevent'] = False

  


def fadeWin(winState):
  FADE_STATE['prevent'] = True
  startTime = time.time()
  win = winState['win']
  winid = winState['id']
  winnr = winState['number']
  width = winState['width']
  height = winState['height']
  cursor = winState['cursor']
  lastWin = vim.eval('win_getid('+str(vim.current.window.number)+')')
  setWin = False
  buf = win.buffer
  cursorCol = cursor[1]
  startRow = cursor[0] - height - ROW_BUF_SIZE
  startRow = max(startRow, 1)
  endRow = cursor[0] +  height + ROW_BUF_SIZE
  endRow = min(endRow, len(buf))
  startCol = cursorCol - width + 1 - COL_BUF_SIZE
  startCol = max(startCol, 1)
  maxCol = cursorCol + 1 + width + COL_BUF_SIZE
  matches = {}

  bufState = FADE_STATE['buffers'][winState['buffer']]
  coords = bufState['coords']
  currentBuf = ''.join(buf)
  if bufState['last'] != currentBuf:
    #todo remove all highlights? - negative impact on perf but better sync highlights
    unfadeWin(winState)
    coords = None
  if coords == None:
    coords = bufState['coords'] = [None] * len(buf)
  bufState['last'] = currentBuf
  winMatches = winState['matches']
  
  row = startRow
  while row <= endRow:
    column = startCol
    index = row - 1
    if IS_V3:
      rawText = buf[index]
      text = bytes(rawText, 'utf-8')
      adjustStart = rawText[0:cursorCol]
      adjustStart = len(bytes(adjustStart, 'utf-8')) - len(adjustStart)
      adjustEnd = rawText[cursorCol:maxCol]
      adjustEnd = len(bytes(adjustEnd, 'utf-8')) - len(adjustEnd)
    else:
      text = buf[index]
      rawText = text.decode('utf-8')
      adjustStart = rawText[0:cursorCol]
      adjustStart = len(adjustStart.encode('utf-8')) - len(adjustStart)
      adjustEnd = rawText[cursorCol:maxCol]
      adjustEnd = len(adjustEnd.encode('utf-8')) - len(adjustEnd)
    text_ln = len(text)
    column -= adjustStart
    column = max(column, 1)
    endCol = min(maxCol + adjustEnd, text_ln)
    colors = coords[index]
    if colors == None:
      colors = coords[index] = [None] * text_ln
    str_row = str(row)
    while column <= endCol:
      #get syntax id and cache
      current = colors[column - 1]
      if current == None:
        if setWin == False:
          setWin = True
          if lastWin != winid:
            vim.command('noautocmd call win_gotoid('+winid+')')
        prev_id = id = vim.eval('synID('+str_row+','+str(column)+',0)')
        if not id in HI_CACHE:
          #create & cache highlight
          hi = HI_CACHE[id] = fadeHi(vim.eval('vimade#GetHi('+id+')'))
          vim_expr = 'hi ' + hi['group'] + ' guifg=' + hi['guifg']
          if hi['guibg']:
            vim_expr += ' guibg='+hi['guibg']
          vim.command(vim_expr)
        else:
          hi = HI_CACHE[id]
        current = colors[column - 1] = {'id': id, 'hi': hi}
      if not winid in current:
        hi = current['hi']
        current[winid] = True
        if not hi['group'] in matches:
           matches[hi['group']] = [(row, column , 1)]
        else:
          match = matches[hi['group']]
          if match[-1][0] == row and match[-1][1] + match[-1][2] == column:
            match[-1] = (row, match[-1][1], match[-1][2] + 1)
          else:
            match.append((row, column, 1))

      column = column + 1
    row = row + 1
  items = matches.items()

  if len(items):
    # this is required, the matchaddpos window ID config does not seem to work in nvim
    if IS_NVIM and not setWin:
      setWin = True
      if lastWin != winid:
        vim.command('noautocmd call win_gotoid('+winid+')')
    for (group, coords) in matches.items():
      i = 0
      end = len(coords)
      while i < end:
        winMatches.append(vim.eval('matchaddpos("'+group+'",['+','.join(map(lambda tup:'['+str(tup[0])+','+str(tup[1])+','+str(tup[2])+']' , coords[i:i+8]))+'],10,-1,{"window":'+winid+'})'))
        i += 8


  if setWin:
    if lastWin != winid:
      vim.command('noautocmd call win_gotoid('+lastWin+')')
  FADE_STATE['prevent'] = False
  # print((time.time() - startTime) * 1000)

def fadeHi(hi):
  guifg = hi[0]
  guibg = hi[1]
  result = {}

  if guibg != '':
    if guibg == BASE_BG:
      guibg = None
    else:
      guibg = fadeRGBToHex([int(guibg[1:3], 16), int(guibg[3:5], 16), int(guibg[5:7], 16)], BASE_HI[1])
    result['guibg'] = guibg
  else:
    guibg = result['guibg'] = None

  if guifg == '':
    guifg = BASE_FADE
  else:
    guifg = [int(guifg[1:3], 16), int(guifg[3:5], 16), int(guifg[5:7], 16)]
    guifg = fadeRGBToHex(guifg, BASE_HI[1])

  result['guifg'] = guifg

  result['group'] = 'fade_' + str(guifg)[1:] + '_' + str(guibg)[1:]

  return result


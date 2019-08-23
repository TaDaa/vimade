import sys
IS_V3 = False
if (sys.version_info > (3, 0)):
    IS_V3 = True

import vim
import math
import time
from vimade import highlighter
from vimade import signs
from vimade import colors
from vimade.buf_state import BufState
from vimade.win_state import WinState
from vimade import global_state as GLOBALS

FADE = sys.modules[__name__]
HAS_NVIM_WIN_GET_CONFIG = True if int(vim.eval('exists("*nvim_win_get_config")')) else False

windows = {}
background = ''
prevent = False
buffers = {}
activeWindow = str(vim.current.window.number)
activeBuffer = str(vim.current.buffer.number)





def update(nextState = None):
  start = time.time()
  if FADE.prevent:
    return

  currentWindows = FADE.windows
  currentBuffers = FADE.buffers

  #Check our globals/settings for changes
  status = GLOBALS.update()

  if status & GLOBALS.DISABLE_SIGNS:
    unfadeAllSigns()
  elif status & GLOBALS.ERROR:
    return
  if status & GLOBALS.RECALCULATE:
    highlighter.recalculate()
    return
  elif status & GLOBALS.FULL_INVALIDATE:
    highlighter.reset()
    for winState in currentWindows.values():
      if winState.faded:
        unfadeWin(winState)
        winState.faded = False
    for bufferState in currentBuffers.values():
      bufferState.coords = None

    #TODO remove this code when possible
    #Ideally this return would not be necessary, but oni current requires a hard refresh here
    return
  else:
    #this is a pre check to make sure that highlights have not been wiped (for example by colorscheme changes)
    highlighter.pre_check()


  fade = {}
  unfade = {}

  activeBuffer = nextState["activeBuffer"]
  activeWindow = nextState['activeWindow']
  activeTab = nextState['activeTab']
  activeDiff = False
  nextWindows = {}
  nextBuffers = {}
  fade_signs = []
  unfade_signs = []
  diffs = []

  FADE.activeBuffer = activeBuffer

  for window in vim.windows:
    winnr = str(window.number)
    bufnr = str(window.buffer.number)
    tabnr = str(window.tabpage.number)
    if activeTab != tabnr:
      continue
    (winid, diff, wrap, buftype, win_disabled, buf_disabled, vimade_fade_active) = vim.eval('[win_getid('+winnr+'), gettabwinvar('+tabnr+','+winnr+',"&diff"), gettabwinvar('+tabnr+','+winnr+',"&wrap"), gettabwinvar('+tabnr+','+winnr+',"&buftype"), gettabwinvar('+tabnr+','+winnr+',"vimade_disabled"), getbufvar('+bufnr+', "vimade_disabled"),  g:vimade_fade_active]')
    floating = vim.eval('nvim_win_get_config('+str(winid)+')') if HAS_NVIM_WIN_GET_CONFIG else False
    if floating and 'relative' in floating:
      floating = floating['relative']
    else:
      floating = False


    diff = int(diff)
    wrap = int(wrap)
    vimade_fade_active = int(vimade_fade_active)
    hasActiveBuffer = False if vimade_fade_active else bufnr == activeBuffer
    hasActiveWindow = False if vimade_fade_active else winid == activeWindow

    # window was unhandled -- add to FADE
    if not bufnr in FADE.buffers:
      bufState = FADE.buffers[bufnr] = BufState(bufnr)
    else:
      bufState = FADE.buffers[bufnr]
    if not winid in FADE.windows:
      state = FADE.windows[winid] = WinState(winid, window, hasActiveBuffer, hasActiveWindow)
    else:
      state = FADE.windows[winid]

    state.win = window
    state.number = winnr
    state.tab = tabnr

    state.diff = diff

    if floating or win_disabled or buf_disabled:
      unfade[winid] = state
      continue

    state.buftype = buftype

    if state.wrap != wrap:
      state.wrap = wrap
      if not hasActiveWindow:
        fade[winid] = state

    if diff:
      diffs.append(state)
      if hasActiveBuffer:
        activeDiff = True

    # window state changed
    if (window.height != state.height or window.width != state.width or window.cursor[0] != state.cursor[0] or window.cursor[1] != state.cursor[1]):
      state.height = window.height
      state.width = window.width
      state.cursor = (window.cursor[0], window.cursor[1])
      if not hasActiveBuffer:
        fade[winid] = state
    if state.buffer != bufnr:
      state.buffer = bufnr
    if state.hasActiveBuffer != hasActiveBuffer:
      state.hasActiveBuffer = hasActiveBuffer
      if hasActiveBuffer:
        unfade[winid] = state
      else:
        fade[winid] = state
    if state.hasActiveWindow != hasActiveWindow:
      state.hasActiveWindow = hasActiveWindow

    if state.faded and hasActiveBuffer:
      unfade[winid] = state
    elif not state.faded and not hasActiveBuffer:
      fade[winid] = state

    if 'minimap' in window.buffer.name:
      state.is_minimap = True
      if GLOBALS.fade_minimap:
        fade[winid] = state
        if winid in unfade:
          del unfade[winid]
      else:
        unfade[winid] = state
        if winid in fade:
          del fade[winid]

    nextBuffers[bufnr] = nextWindows[winid] = True

  if activeDiff and len(diffs) > 1:
    for state in diffs:
      if state.id in fade:
        del fade[state.id]
      unfade[state.id] = state


  for win in fade.values():
    fadeWin(win)
    if not FADE.buffers[win.buffer].faded:
      fade_signs.append(win.buffer)
      FADE.buffers[win.buffer].faded = time.time()
    win.faded = True
  for win in unfade.values():
    if win.faded:
      unfadeWin(win)
      win.faded = False
      if not win.buffer in unfade_signs:
        FADE.buffers[win.buffer].faded = 0
        unfade_signs.append(win.buffer)

  expr = []
  ids = []
  for win in list(FADE.windows.keys()):
    if not win in nextWindows:
      expr.append('win_id2tabwin('+win+')')
      ids.append(win)
  expr = vim.eval('['+','.join(expr)+']')
  i = 0
  for item in expr:
    if item[0] == '0' and item[1] == '0':
      del FADE.windows[ids[i]]
    i += 1


  expr = []
  ids = []
  for key in list(FADE.buffers.keys()):
    if not key in nextBuffers:
      expr.append('win_findbuf('+key+')')
      ids.append(key)
  expr = vim.eval('['+','.join(expr)+ ']')
  i = 0
  for item in expr:
    if len(item) == 0:
      del FADE.buffers[ids[i]]
    i += 1


  if GLOBALS.enable_signs:
    now = time.time()
    signs_retention_period = GLOBALS.signs_retention_period
    for bufnr in nextBuffers:
      if bufnr in buffers:
        buf = buffers[bufnr]
        if buf.faded and buf.faded != True and not bufnr in fade_signs:
            fade_signs.append(bufnr)
            if signs_retention_period != -1 and (now - buf.faded) * 1000 >= signs_retention_period:
              buf.faded = True

    if len(fade_signs) or len(unfade_signs):
      if len(fade_signs):
        signs.fade_bufs(fade_signs)
      signs.unfade_bufs(unfade_signs)
  # print('update',(time.time() - start) * 1000)

def unfadeAllSigns():
  currentBuffers = buffers
  bufs = []
  for bufState in currentBuffers.values():
    if bufState.faded:
      bufState.faded = 0
      bufs.append(bufState.bufnr)
  if len(bufs):
    signs.unfade_bufs(bufs)

def unfadeAll():
  currentWindows = windows
  for winState in currentWindows.values():
      if winState.faded:
        winState.faded = False
        unfadeWin(winState)
  unfadeAllSigns()

def softInvalidateSigns():
  for buf in FADE.buffers.values():
    if buf.faded:
      buf.faded = time.time()

def softInvalidateBuffer(bufnr):
  currentWindows = windows
  for winState in currentWindows.values():
    if winState.buffer == bufnr and winState.faded == True:
      winState.faded = False

def unfadeWin(winState):
  FADE.prevent = True
  lastWin = vim.eval('win_getid('+str(vim.current.window.number)+')')
  matches = winState.matches
  winid = str(winState.id)
  if lastWin != winid:
    vim.command('noautocmd call win_gotoid('+winid+')')
  coords = FADE.buffers[winState.buffer].coords
  errs = 0
  if coords:
    for items in coords:
      if items:
        for item in items:
          if item and winid in item:
            del item[winid]
  if matches:
    for match in matches:
        try:
          vim.command('call matchdelete('+match+')')
        except:
          continue
  winState.matches = []
  if lastWin != winid:
    vim.command('noautocmd call win_gotoid('+lastWin+')')
  FADE.prevent = False

def fadeWin(winState):
  FADE.prevent = True
  startTime = time.time()
  win = winState.win
  winid = winState.id
  winnr = winState.number
  width = winState.width
  height = winState.height
  cursor = winState.cursor
  wrap = winState.wrap
  lastWin = vim.eval('win_getid('+str(vim.current.window.number)+')')
  setWin = False
  buf = win.buffer
  cursorCol = cursor[1]
  startRow = cursor[0] - height - GLOBALS.row_buf_size
  endRow = cursor[0] +  height + GLOBALS.row_buf_size
  startCol = cursorCol - width + 1 - GLOBALS.col_buf_size
  startCol = max(startCol, 1)
  maxCol = cursorCol + 1 + width + GLOBALS.col_buf_size
  matches = {}
  if winState.is_minimap:
    fade_priority='9'
  else:
    fade_priority = GLOBALS.fade_priority


  if GLOBALS.enable_scroll == 0 and winid == lastWin and not wrap:
    (startRow, endRow) = vim.eval("[line('w0'),line('w$')]")
    startRow = int(startRow)
    endRow = int(endRow)

  # attempted working backwards through synID as well, but this precomputation nets in
  # the highest performance gains
  if wrap:
    #set startCol to 1
    #maxCol gets set to text_ln a bit lower
    startCol = 1

    #first calculate virtual rows above the cursor
    row = cursor[0] - 1
    sRow = startRow
    real_row = row
    text_ln = 0
    while row >= sRow and real_row > 0:
      text = bytes(buf[real_row - 1], 'utf-8') if IS_V3 else buf[real_row-1]
      text_ln = len(text)
      virtual_rows = math.floor(text_ln / width)
      row -= virtual_rows + 1
      real_row -= 1
    d = sRow - row
    wrap_first_row_colStart = int(max(text_ln - d * width if d > 0 else 1,1))
    startRow = real_row

    #next calculate virtual rows equal to and below the cursor
    row = cursor[0]
    real_row = row
    text_ln = 0
    while row <= endRow and real_row <= len(buf):
      text = bytes(buf[real_row - 1], 'utf-8') if IS_V3 else buf[real_row-1]
      text_ln = len(text)
      virtual_rows = math.floor(text_ln / width)
      row += virtual_rows + 1
      if row <= endRow:
        real_row += 1
    d = row - min(endRow, len(buf))
    wrap_last_row_colEnd =  int(min(d * width if d > 0 else width , text_ln))
    endRow = real_row

  #clamp values
  startRow = max(startRow, 1)
  endRow = min(endRow, len(buf))

  bufState = FADE.buffers[winState.buffer]
  coords = bufState.coords
  currentBuf = '\n'.join(buf)
  if bufState.last != currentBuf:
    #todo remove all highlights? - negative impact on perf but better sync highlights
    unfadeWin(winState)
    coords = None
  bufState.last = currentBuf 
  if coords == None:
    coords = bufState.coords = [None] * len(buf)
  winMatches = winState.matches

  row = startRow
  redo = False
  while row <= endRow:
    column = startCol
    index = row - 1
    if IS_V3:
      rawText = buf[index]
      text = bytes(rawText, 'utf-8', 'surrogateescape')
      text_ln = len(text)
      mCol = text_ln if wrap else maxCol
      adjustStart = rawText[0:cursorCol]
      adjustStart = len(bytes(adjustStart, 'utf-8', 'surrogateescape')) - len(adjustStart)
      adjustEnd = rawText[cursorCol:mCol]
      adjustEnd = len(bytes(adjustEnd, 'utf-8', 'surrogateescape')) - len(adjustEnd)
    else:
      text = buf[index]
      text_ln = len(text)
      mCol = text_ln if wrap else maxCol
      rawText = text.decode('utf-8')
      adjustStart = rawText[0:cursorCol]
      adjustStart = len(adjustStart.encode('utf-8')) - len(adjustStart)
      adjustEnd = rawText[cursorCol:mCol]
      adjustEnd = len(adjustEnd.encode('utf-8')) - len(adjustEnd)

    if wrap:
      if row == startRow:
        column = wrap_first_row_colStart
      else:
        column = 1
      if row == endRow:
        endCol = wrap_last_row_colEnd
      else:
        endCol = text_ln
    else:
      column -= adjustStart
      column = max(column, 1)
      endCol = min(mCol + adjustEnd, text_ln)
    colors = coords[index]
    if colors == None:
      colors = coords[index] = [None] * text_ln
    str_row = str(row)

    ids = []
    gaps = []

    sCol = column
    while column <= endCol:
      #get syntax id and cache
      current = colors[column - 1]
      if current == None:
        if setWin == False:
          setWin = True
          if lastWin != winid:
            vim.command('noautocmd call win_gotoid('+winid+')')
            if GLOBALS.enable_scroll == 0 and not wrap:
              (startRow, endRow) = vim.eval("[line('w0'),line('w$')]")
              redo = True
              startRow = int(startRow)
              endRow = int(endRow)
              break
        ids.append('synID('+str_row+','+str(column)+',0)')
        gaps.append(column - 1)
      column = column + 1

    if redo:
      redo = False
      continue
    if len(ids):
      ids = vim.eval('[' + ','.join(ids) + ']')
      highlights = highlighter.fade_ids(ids)
      i = 0
      for hi in highlights:
        colors[gaps[i]] = {'id': ids[i], 'hi': hi}
        i += 1

    column = sCol
    while column <= endCol:
      current = colors[column - 1]
      if current and not winid in current:
        hi = current['hi']
        current[winid] = True
        if not hi[0] in matches:
           matches[hi[0]] = [(row, column , 1)]
        else:
          match = matches[hi[0]]
          if match[-1][0] == row and match[-1][1] + match[-1][2] == column:
            match[-1] = (row, match[-1][1], match[-1][2] + 1)
          else:
            match.append((row, column, 1))
      column += 1
    row = row + 1

  items = matches.items()
  if len(items):
    # this is required, the matchaddpos window ID config does not seem to work in nvim
    if not setWin:
      setWin = True
      if lastWin != winid:
        vim.command('noautocmd call win_gotoid('+winid+')')
    matchadds = []
    for (group, coords) in matches.items():
      i = 0
      end = len(coords)
      while i < end:
        matchadds.append('matchaddpos("'+group+'",['+','.join(map(lambda tup:'['+str(tup[0])+','+str(tup[1])+','+str(tup[2])+']' , coords[i:i+8]))+'],'+fade_priority+',-1)')
        i += 8
    winMatches += vim.eval('[' + ','.join(matchadds) + ']')

  if setWin:
    if lastWin != winid:
      vim.command('noautocmd call win_gotoid('+lastWin+')')
  FADE.prevent = False
  # print((time.time() - startTime) * 1000)

import sys
IS_V3 = False
if (sys.version_info > (3, 0)):
    IS_V3 = True

import vim
import math
import time
from vimade import util
from vimade import highlighter
from vimade import signs
from vimade import colors
from vimade.buf_state import BufState
from vimade.win_state import WinState
from vimade import global_state as GLOBALS

FADE = sys.modules[__name__]
HAS_NVIM_WIN_GET_CONFIG = True if int(util.eval_and_return('exists("*nvim_win_get_config")')) else False
HAS_NVIM_COMMAND_OUTPUT = True if hasattr(vim, 'funcs') and hasattr(vim.funcs, 'nvim_command_output') else False


windows = {}
background = ''
prevent = False
currentWin = False
startWin = False
changedWin = False
buffers = {}
activeWindow = util.eval_and_return('win_getid('+str(vim.current.window.number)+')')
activeBuffer = str(vim.current.buffer.number)





def update(nextState = None):
  start = time.time()
  if FADE.prevent:
    return
  FADE.changedWin = False

  currentWindows = FADE.windows
  currentBuffers = FADE.buffers

  #Check our globals/settings for changes
  status = GLOBALS.update()

  if status & GLOBALS.BASEGROUPS:
    if GLOBALS.enable_basegroups:
      GLOBALS.basegroups_faded = highlighter.fade_names(GLOBALS.basegroups)

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
      bufferState.coords = {}

    #TODO remove this code when possible
    #Ideally this return would not be necessary, but oni current requires a hard refresh here
    return
  else:
    #this is a pre check to make sure that highlights have not been wiped (for example by colorscheme changes)
    highlighter.pre_check()


  fade = {}
  unfade = {}

  FADE.startWin = FADE.currentWin = util.mem_safe_eval('win_getid('+str(vim.current.window.number)+')')
  activeBuffer = nextState["activeBuffer"]
  activeWindow = nextState['activeWindow']
  activeTab = nextState['activeTab']
  activeDiff = False
  activeScrollbind = False
  nextWindows = {}
  nextBuffers = {}
  fade_signs = []
  unfade_signs = []
  diffs = []
  scrollbinds = []

  FADE.activeBuffer = activeBuffer

  for window in vim.windows:
    winnr = str(window.number)
    bufnr = str(window.buffer.number)
    tabnr = str(window.tabpage.number)
    if activeTab != tabnr:
      continue
    (winid, diff, wrap, buftype, win_disabled, buf_disabled, vimade_fade_active, scrollbind, win_syntax, buf_syntax, tabstop) = util.eval_and_return('[win_getid('+winnr+'), gettabwinvar('+tabnr+','+winnr+',"&diff"), gettabwinvar('+tabnr+','+winnr+',"&wrap"), gettabwinvar('+tabnr+','+winnr+',"&buftype"), gettabwinvar('+tabnr+','+winnr+',"vimade_disabled"), getbufvar('+bufnr+', "vimade_disabled"),  g:vimade_fade_active, gettabwinvar('+tabnr+','+winnr+',"&scrollbind"), gettabwinvar('+tabnr+','+winnr+',"current_syntax"), gettabwinvar('+tabnr+','+winnr+',"&syntax"), gettabwinvar('+tabnr+','+winnr+',"&tabstop")]')
    syntax = win_syntax if win_syntax else buf_syntax
    floating = util.eval_and_return('nvim_win_get_config('+str(winid)+')') if HAS_NVIM_WIN_GET_CONFIG else False
    if floating and 'relative' in floating:
      floating = floating['relative']
    else:
      floating = False


    diff = int(diff)
    wrap = int(wrap)
    scrollbind = int(scrollbind)
    vimade_fade_active = int(vimade_fade_active)
    hasActiveBuffer = False if vimade_fade_active else bufnr == activeBuffer
    hasActiveWindow = False if vimade_fade_active else winid == activeWindow

    # window was unhandled -- add to FADE
    if not bufnr in FADE.buffers:
      FADE.buffers[bufnr] = {}
      bufState = FADE.buffers[bufnr] = BufState(bufnr)
    else:
      bufState = FADE.buffers[bufnr]
      

    if not winid in FADE.windows:
      state = FADE.windows[winid] = WinState(winid, window, hasActiveBuffer, hasActiveWindow)
      state.syntax = syntax
    else:
      state = FADE.windows[winid]

    state.win = window
    state.name = window.buffer.name
    state.number = winnr
    state.tab = tabnr
    state.diff = diff

    if state.tabstop != tabstop:
      state.tabstop = int(tabstop)

    if (floating and not vimade_fade_active) or win_disabled or buf_disabled:
      unfade[winid] = state
      continue

    if syntax != state.syntax:
      state.clear_syntax = state.syntax
      state.syntax = syntax
      if not hasActiveBuffer:
        fade[winid] = state


    state.buftype = buftype

    if state.wrap != wrap:
      state.wrap = wrap
      if not hasActiveWindow:
        fade[winid] = state

    if diff and GLOBALS.group_diff:
      diffs.append(state)
      if hasActiveBuffer:
        activeDiff = True

    if scrollbind and GLOBALS.group_scrollbind:
      scrollbinds.append(state)
      if hasActiveBuffer:
        activeScrollbind = True

    # window state changed
    cursor = window.cursor
    width = window.width
    height = window.height
    if (height > state.height or width > state.width or cursor[0] != state.cursor[0] or cursor[1] != state.cursor[1]):
      state.height = height
      state.width = width
      state.cursor = (cursor[0], cursor[1])
      if not hasActiveBuffer:
        fade[winid] = state
      state.size_changed = True
    else:
      state.size_changed = False
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

    if 'coc-explorer' in state.name or 'NERD' in state.name:
      state.is_explorer = True
    if 'vim-minimap' in state.name or '-MINIMAP-' in state.name:
      state.is_minimap = True
      #TODO can we add additional buf comparisons and move bufState check out of fadeWin?
      if GLOBALS.fade_minimap:
        currentBuf = '\n'.join(state.win.buffer)
        if not bufState.faded or currentBuf != bufState.last:
          bufState.last = currentBuf
          fade[winid] = state
        if winid in unfade:
          del unfade[winid]
      else:
        unfade[winid] = state
        if winid in fade:
          del fade[winid]

    nextWindows[winid] = state
    nextBuffers[bufnr] = True

  if activeDiff and len(diffs) > 1:
    for state in diffs:
      if state.id in fade:
        del fade[state.id]
      unfade[state.id] = state

  if activeScrollbind and len(scrollbinds) > 1:
    for state in scrollbinds:
      if state.id in fade:
        del fade[state.id]
      unfade[state.id] = state

  for win in fade.values():
    fadeWin(win)
    if GLOBALS.enable_basegroups:
      fadeBase(win)
    if not FADE.buffers[win.buffer].faded:
      fade_signs.append(win)
      FADE.buffers[win.buffer].faded = time.time()
    win.faded = True
  for win in unfade.values():
    if win.faded:
      unfadeWin(win)
      win.faded = False
      if GLOBALS.enable_basegroups:
        unfadeBase(win)
      if not win.buffer in unfade_signs:
        FADE.buffers[win.buffer].faded = 0
        unfade_signs.append(FADE.buffers[win.buffer])

  expr = []
  ids = []
  for win in list(FADE.windows.keys()):
    if not win in nextWindows:
      expr.append('win_id2tabwin('+win+')')
      ids.append(win)
  expr = util.eval_and_return('[' + ','.join(expr) + ']')
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
  expr = util.eval_and_return('[' + ','.join(expr) + ']')
  i = 0
  for item in expr:
    if len(item) == 0:
      del FADE.buffers[ids[i]]
    i += 1


  if GLOBALS.enable_signs:
    now = time.time()
    signs_retention_period = GLOBALS.signs_retention_period

    sign_buffers = {}
    for win in nextWindows.values():
      bufnr = win.buffer
      if bufnr in buffers and win.faded:
        buf = buffers[bufnr]
        if ((buf.faded and buf.faded != True) or (bufnr in sign_buffers) or win.size_changed) and win not in fade_signs:
            sign_buffers[bufnr] = True
            fade_signs.append(win)
            if signs_retention_period != -1 and (now - buf.faded) * 1000 >= signs_retention_period:
              buf.faded = True

    if len(fade_signs) or len(unfade_signs):
      if len(fade_signs):
        signs.fade_wins(fade_signs, FADE.buffers)
      signs.unfade_bufs(unfade_signs)
  returnToWin()
  FADE.prevent = False
  # if (time.time() - start) * 1000 > 10:
    # print('update',(time.time() - start) * 1000)

def gotoWin(winid):
  currentWin = FADE.currentWin
  if currentWin != winid:
    FADE.currentWin = winid
    if FADE.changedWin == False:
      FADE.changedWin = True
      vim.command('noautocmd set winwidth=1 | noautocmd call win_gotoid('+winid+')')
    else:
      vim.command('noautocmd call win_gotoid('+winid+')')

def returnToWin():
  cmd = ('| let g:vimade_cmd="noautocmd vert resize ".winwidth(".") |  noautocmd set winwidth=' + GLOBALS.win_width + ' | execute g:vimade_cmd') if FADE.changedWin else ''
  FADE.changedWin = False

  if FADE.currentWin != FADE.startWin:
    vim.command('noautocmd call win_gotoid('+FADE.startWin+')' + cmd)
  elif cmd != '':
    vim.command(cmd[1:])

def unfadeAllSigns():
  currentBuffers = buffers
  if len(currentBuffers):
    signs.unfade_bufs(list(currentBuffers.values()))

def unfadeAll():
  FADE.startWin = FADE.currentWin = util.eval_and_return('win_getid('+str(vim.current.window.number)+')')
  currentWindows = windows
  for winState in currentWindows.values():
      if winState.faded:
        winState.faded = False
        if GLOBALS.enable_basegroups:
          unfadeBase(winState)
        if winState.buffer in FADE.buffers:
          bufState = FADE.buffers[winState.buffer]
          bufState.faded = False
        unfadeWin(winState)
  unfadeAllSigns()
  returnToWin()

def softInvalidateSigns():
  for buf in FADE.buffers.values():
    if buf.faded:
      buf.faded = time.time()

def softInvalidateBuffer(bufnr):
  currentWindows = windows
  for winState in currentWindows.values():
    if winState.buffer == bufnr and winState.faded == True:
      winState.faded = False

def unfadeWin(winState, clear_syntax = False):
  matches = winState.matches
  winid = str(winState.id)
  gotoWin(winid)
  syntax = clear_syntax if clear_syntax else winState.syntax
  if syntax in FADE.buffers[winState.buffer].coords:
    coords = FADE.buffers[winState.buffer].coords[syntax]
    if coords:
      for items in coords:
        if items:
          for item in items:
            if item and winid in item:
              del item[winid]
  if matches:
    to_delete = [] 
    for match in matches:
        to_delete.append('silent! call matchdelete('+str(match)+')')
    try:
      vim.command('|'.join(to_delete))
    except:
      pass
  winState.clear_syntax = False
  winState.matches = []

def fadeWin(winState):
  startTime = time.time()
  win = winState.win
  winid = winState.id
  width = winState.width
  height = winState.height
  is_explorer = winState.is_explorer
  is_minimap = winState.is_minimap
  cursor = winState.cursor
  wrap = winState.wrap
  buf = win.buffer
  cursorCol = cursor[1]
  cursorRow = cursor[0]
  matches = {}
  if is_minimap:
    fade_priority='9'
  else:
    fade_priority = GLOBALS.fade_priority

  to_eval = []
  texts = []

  gotoWin(winid)

  lookup = util.eval_and_return('winsaveview()')
  startRow = topline = int(lookup['topline'])
  endRow = startRow + height
  startCol = int(lookup['leftcol']) + int(lookup['skipcol']) + 1
  maxCol = startCol + width
  if GLOBALS.enable_scroll:
    startRow = min(startRow, cursorRow - height - GLOBALS.row_buf_size)
    endRow = max(endRow, cursorRow + height + GLOBALS.row_buf_size)
    target_height = height * 2 + 2 * GLOBALS.row_buf_size

    if startRow < 1:
      startRow = 1
    startCol -= GLOBALS.col_buf_size
    maxCol += GLOBALS.col_buf_size
    if startCol < 1:
      startCol = 1
  else:
    target_height = height

  row = startRow
  buf_ln = len(buf)
  rows_so_far = 0
  if endRow > buf_ln:
    endRow = buf_ln

  vim.command('let g:vimade_visrows=vimade#GetVisibleRows('+str(startRow)+','+str(endRow)+')')
  visible_rows = vim.vars['vimade_visrows']
  buf = buf[visible_rows[0][0]-1:visible_rows[len(visible_rows)-1][0]]
  texts = []
  winState.visible_rows = {} 

  j = -1
  for (row, fold) in visible_rows:
    j += 1
    if rows_so_far > target_height or j >= len(buf):
      break
    row = int(row)
    fold = int(fold)
    if fold > -1:
      j += fold - row
      rows_so_far += 1
    elif fold == -1:
      winState.visible_rows[row] = 1
      rawText = buf[j]
      text = bytes(rawText, 'utf-8', 'replace') if IS_V3 else rawText
      # text = bytes(rawText, 'utf-8', 'replace').decode('utf-8') if IS_V3 else rawText
      #TODOn2
      # text = buf[j]
      text_ln = len(text)
      if text_ln > 0:
        if is_explorer or is_minimap:
          to_eval.append((row, 1, text_ln))
          #TODOn2
          # to_eval.append([row, 1, text_ln])
          texts.append(text)
          rows_so_far += 1
          continue
        elif wrap:
          if text_ln > width * height and row < cursorRow:
            buf[j] = ''
            continue
          else:
            chars_left = (height - rows_so_far) * width
            if row == cursorRow:
              mCol = startCol + chars_left
              mCol = mCol if mCol < text_ln else text_ln
              sCol = startCol
            else:
              mCol = text_ln if text_ln < chars_left else chars_left 
              sCol = 1
            if row >= topline:
                rows_so_far += math.floor((mCol - startCol) / width)
        else:
          mCol = maxCol if maxCol < text_ln else text_ln
          sCol = startCol
          rows_so_far += 1
        if IS_V3:
          t1 = text[0:sCol]
          t2 = t1.replace(bytes('\t', 'utf-8'),bytes(' ', 'utf-8') * winState.tabstop)
          # TODOn2
          # t2 = t1.replace('\t', ' ' * winState.tabstop)

          adjustStart = len(t2) - len(t1)
          #TODO can adjustEnd be accurately calculated? Tab rules seem to cause breakage -- safer to leave at 0
          adjustEnd = 0
        else:
          t1 = rawText[0:sCol]
          t2 = t1.replace('\t',' ' * winState.tabstop)

          adjustStart = len(t2) - len(t1)
          #TODO can adjustEnd be accurately calculated? Tab rules seem to cause breakage -- safer to leave at 0
          adjustEnd = 0

        sCol -= adjustStart
        sCol = max(sCol, 1)
        mCol = min(mCol + adjustEnd, text_ln)
        to_eval.append((row, sCol, mCol))
        # TODOn2
        # to_eval.append([row, sCol, mCol])
        texts.append(text)

  bufState = FADE.buffers[winState.buffer]
  if not winState.syntax in bufState.coords:
    bufState.coords[winState.syntax] = None
  coords = bufState.coords[winState.syntax]


  #check if the visible contents of the buffer have changed
  contents_changed = False

  j=0
  if coords != None:
    for (row, startCol, endCol) in to_eval:
      text = texts[j]
      j += 1
      column = startCol
      index = row - 1
      if index >= len(coords):
        contents_changed = True
        break
      colors = coords[index]
      if colors:
          while column <= endCol:
            #get syntax id and cache
            if column - 1 >= len(colors):
              contents_changed = True
              break
            current = colors[column - 1]
            if current and current['c'] != text[column-1]:
              contents_changed = True
              break
            column += 1
          if contents_changed:
            break

  if (coords != None and len(coords) != buf_ln) or contents_changed:
    unfadeWin(winState)
    coords = None
  elif winState.clear_syntax:
    unfadeWin(winState, winState.clear_syntax)
    coords = None

  if coords == None:
    coords = bufState.coords[winState.syntax] = [None] * buf_ln

  ids = []
  gaps = []
  ts_empty = {}
  j = 0
  for (row, column, endCol) in to_eval:

    ts_results = None
    if GLOBALS.enable_treesitter:
      try:
        ts_results = vim.lua._vimade.get_highlights(winState.buffer,row-1,row,column-1,endCol)
      except:
        pass
    if ts_results == None:
      ts_results = ts_empty

    text = texts[j]
    j += 1
    text_ln = len(text)

    index = row - 1
    if index >= len(coords) or index < 0:
      continue
    colors = coords[index]
    if colors == None:
      colors = coords[index] = [None] * text_ln

    while column <= endCol:
      #get syntax id and cache
      current = colors[column - 1]
      if current == None:
        if text[column-1] != '' and text[column-1] != ' ' and text[column-1] != '\t':
          if str(column-1) in ts_results:
            ids.append(str(ts_results[str(column-1)]))
          else:
            ids.append('synID(%s,%s,0)' % (row,column))
        else:
          ids.append('0')
        gaps.append((index, column - 1, text[column - 1]))
      column = column + 1

  if len(ids):
    if HAS_NVIM_COMMAND_OUTPUT:
        vim.funcs.nvim_command('function! VimadeSynIDs() \n return ['+','.join(ids)+'] \n endfunction')
        ids = vim.funcs.nvim_command_output('echo VimadeSynIDs()')[1:-1].split(', ')
    else:
        ids = util.eval_and_return('[' + ','.join(ids) + ']')
    highlights = highlighter.fade_ids(ids)

    for i in range(0, len(highlights)):
      (row, column, text) = gaps[i]
      coords[row][column] = {'h': highlights[i], 'c': text}

  for (row, column, endCol) in to_eval:
    colors = coords[row - 1]
    while column <= endCol:
      current = colors[column - 1]
      if current and len(current['h']) > 0 and not winid in current:
        hi_id = current['h'][0]
        current[winid] = True
        if not hi_id in matches:
           matches[hi_id] = [(row, column , 1)]
        else:
          match = matches[hi_id]
          if match[-1][0] == row and match[-1][1] + match[-1][2] == column:
            match[-1] = (row, match[-1][1], match[-1][2] + 1)
          else:
            match.append((row, column, 1))
      column += 1

  items = matches.items()
  if len(items):
    matchadds = []
    for (group, coords) in matches.items():
      i = 0
      end = len(coords)
      while i < end:
        matchadds.append('matchaddpos("'+group+'",['+','.join(map(lambda tup:'['+str(tup[0])+','+str(tup[1])+','+str(tup[2])+']' , coords[i:i+8]))+'],'+fade_priority+')')
        i += 8

    vim.command('let g:vimade_matches=['+','.join(matchadds)+']')
    winState.matches += vim.vars['vimade_matches']

def fadeBase(winState):
  winid = winState.id
  gotoWin(winid)
  i = 0
  hl = ''
  for base in GLOBALS.basegroups:
    if i > 0:
      hl += ','
    hl += base + ':' + GLOBALS.basegroups_faded[i][0]
    i += 1

  last_winhl = util.eval_and_return('gettabwinvar('+winState.tab+','+winState.number+',"&winhl")')
  if last_winhl.find('vimade_') == -1:
    winState.last_winhl = last_winhl
  vim.command('setlocal winhl='+hl)



def unfadeBase(winState):
  winid = winState.id
  gotoWin(winid)
  vim.command('setlocal winhl=' + winState.last_winhl)

  # print(str(len(to_eval))+ ' ' + str((time.time() - startTime) * 1000))

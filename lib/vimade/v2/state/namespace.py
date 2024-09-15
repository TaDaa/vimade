import math
import sys
import vim

M = sys.modules[__name__]
IS_V3 = False
if (sys.version_info > (3, 0)):
    IS_V3 = True

from vimade import util
from vimade.v2.state import globals as GLOBALS
from vimade.v2 import highlighter as HIGHLIGHTER

tab = (bytes('\t', 'utf-8', 'replace') if IS_V3 else '\t')[0]
sp = (bytes(' ', 'utf-8', 'replace') if IS_V3 else ' ')[0]
HAS_NVIM_COMMAND_OUTPUT = True if hasattr(vim, 'funcs') and hasattr(vim.funcs, 'nvim_command_output') else False

M.buf_shared_lookup = {}
M._changed_win = False

def _goto_win(winid):
  current_winid = int(util.eval_and_return('win_getid()'))
  if current_winid != winid:
    if GLOBALS.current['winid'] == current_winid:
      vim.command('noautocmd set winwidth=1 | noautocmd call win_gotoid('+str(winid)+')')
    else:
      vim.command('noautocmd call win_gotoid('+str(winid)+')')


# Namespaces manages both config per window, shared across multiple windows, and partially attached
# to a buffer. This is unfortunately extremely complex.  Consider the following:
# Buffer:
#  - can be shared by multiple windows
#  - some settings are window specific for the buffer (e.g. folds and ownsyntax)
# Signs:
#  - created per buffer (not window:/)
# Basegroups / wincolor
#  - Applied to each window
class Namespace:
  def __init__(self, win):
    self.bufnr = None
    self.win = win
    self.coords_key = None
    self.tick_id = GLOBALS.tick_id
    self.matches = []
    self.fade_grid = {}
    self.basegroups = []
    self.shared_state = None

  # the internal state needs to be checked to ensure no bufswaps
  def refresh(self):
    if self.bufnr != self.win.bufnr:
      win = self.win
      self.cleanup() # buffer gets deactivated
      self.win = win # reattach win
      self.bufnr = win.bufnr
      
      if not win.bufnr in M.buf_shared_lookup:
        M.buf_shared_lookup[win.bufnr] = {
          'coords': {},
          'active': 0,
        }

      self.shared_state = M.buf_shared_lookup[win.bufnr]
      self.shared_state['active'] = self.shared_state['active'] + 1


  def cleanup(self):
    # should be called when the window is destroyed
    HIGHLIGHTER.clear_win(self.win)
    self.unfade(True) # try to unfade

    if self.shared_state:
      self.shared_state['active'] = max(self.shared_state['active'] - 1, 0)

      if self.shared_state['active'] == 0:
        del M.buf_shared_lookup[self.bufnr]

    # circular ref, del
    self.win = None


  def add_basegroups(self):
    basegroups = GLOBALS.basegroups
    replacement_ids = HIGHLIGHTER.create_highlights(self.win, basegroups)
    replacement_winhl = ','.join([ '%s:vimade_%s' % (basegroups[i], replacement)
                                  for i,replacement in enumerate(replacement_ids)])
    if replacement_winhl != self.win.winhl:
      util.mem_safe_eval('settabwinvar(%s,%s,"&winhl","%s")' % (self.win.tabnr, self.win.winnr, replacement_winhl))

  def remove_basegroups(self):
    util.mem_safe_eval('settabwinvar(%s,%s,"&winhl","%s")' % (self.win.tabnr, self.win.winnr, self.win.original_winhl))

  def invalidate(self):
    self.unfade()
    if self.coords_key and self.coords_key in self.shared_state['coords']:
      # TODO we need to distinguish between needing to get synIDs vs invalidate highlight
      del self.shared_state['coords'][self.coords_key]
      HIGHLIGHTER.clear_win(self.win)
      HIGHLIGHTER.clear_color(self.win, self.win.original_wincolor)

  # remove all current matches.
  def unfade(self, cleanup = False):
    self.remove_matches()

    if not cleanup:
      win = self.win
      if not GLOBALS.is_nvim and win.window and 'wincolor' in win.window.options:
        win.window.options['wincolor'] = win.original_wincolor

  def remove_matches(self):
    matches = self.matches

    HIGHLIGHTER.clear_win(self.win)

    if GLOBALS.enablebasegroups:
      self.remove_basegroups()
    if len(matches) > 0:
      to_delete = []
      for match in matches:
        to_delete.append('silent! call matchdelete(%s, %s)' % (match, self.win.winid))
      try:
        vim.command('|'.join(to_delete))
      except:
        pass
      self.matches = []
      self.fade_grid = {}

  def fade(self):
    self.add_matches()

    win = self.win
    replacement_hl = 'vimade_%s' % HIGHLIGHTER.create_highlights(win, [win.original_wincolor])[0]
    if not GLOBALS.is_nvim and replacement_hl and win.wincolor != replacement_hl and win.window and 'wincolor' in win.window.options:
      win.window.options['wincolor'] = replacement_hl
    elif GLOBALS.enablebasegroups:
      self.add_basegroups()

  # the process below is extremely tricky and logic needs to be cached/reduced
  # as much as possible. Matches are added per window. We try to reduce
  # window switching during this process.  Currently it only occurs when synID()
  # is required.
  # SynIDs are cached per-buffer per-ownsyntax.
  # We leverage tick_id to determine if a calculation state is out of sync vs
  # found SynID
  # Each window needs to compute its own fade calculation based on found syntax
  # and window state.
  def add_matches(self):
    # This should be externally managed and never happen, but we need to enforce
    # 1:1 relationship between win and namepsace
    if self.coords_key != self.win.coords_key:
      # TODO this might be incorret now, coords_key is only syntax based
      self.invalidate()

    self.coords_key = self.win.coords_key

    win = self.win
    winid = win.winid
    winnr = win.winnr
    # textoff are columns excluded from buffer_ln. These columns include
    # foldcolumn, signcolumn, etc
    width = win.width - win.textoff
    height = win.height
    is_explorer = win.is_explorer
    is_minimap = win.is_minimap
    cursor = win.cursor
    cursor_row = cursor[0]
    cursor_col = cursor[1]
    wrap = win.wrap
    buf = win.get_buffer()

    to_eval = []
    texts = []
    matches = {}
    on_win = False

    # Begin the hacks. screenpos() is used instead of winsaveview(), which would
    # require us to change to the window and then run winsaveview().
    # We can use screenpos() to find the first visible column that is not 0 and
    # not repeated, then add winwidth
    find_start_col_eval = []
    start_col = -1
    for i in range(max(cursor_col - width, 0), cursor_col + 1):
      find_start_col_eval.append('screenpos(%s,%s,%s)' % (winid, cursor_row, i))

    if len(find_start_col_eval):
      find_start_col_eval = util.eval_and_return('[' + ','.join(find_start_col_eval) + ']')
      last_col = -1
      v_i = 0
      for i in range(max(cursor_col - width, 0), cursor_col + 1):
        value = find_start_col_eval[v_i]
        col = int(value['curscol'])
        if last_col != col and col != 0:
          start_col = i
          break
        v_i += 1

    start_row = topline = self.win.topline
    end_row = self.win.botline
    max_col = start_col + width

    if not GLOBALS.enablescroll:
      target_height = height
    else:
      rowbufsize = int(GLOBALS.rowbufsize)
      colbufsize = int(GLOBALS.colbufsize)
      start_row -= rowbufsize
      end_row += rowbufsize
      target_height = height * 2 + 2 * rowbufsize
      if start_row < 1:
        start_row = 1
      start_col -= colbufsize
      max_col += colbufsize
      if start_col < 1:
        start_col = 1

    row = start_row
    buf_ln = len(buf)
    if end_row > buf_ln:
      end_row = buf_ln

    visible_rows_eval = []
    # visible rows will be the columns displayed on the screen to the user +-
    # colbufsize and rowbufsize
    visible_rows = []

    # Now we need to find the folded columns. Again screenpos lets us hack around
    # where we needed to previously switch to the window and call foldclosedend.
    # Folded rows are duplicated as a single row number.
    for r in range(start_row, end_row+1):
      visible_rows_eval.append('screenpos(%s,%s,%s)'%(winid, r, 1))

    if len(visible_rows_eval):
      visible_rows_eval = util.eval_and_return('['+ ','.join(visible_rows_eval) +']')
      v_i = 0

      last_visible_row = -1
      last_value = None

      for r in range(start_row, end_row+1):
        visible_row = visible_rows_eval[v_i]
        if last_visible_row == visible_row:
          last_value[1] += 1
        else:
          last_value = [r, 0]
          visible_rows.append(last_value)
        last_visible_row = visible_row
        v_i += 1

    texts = []

    # Take the visible rows that we previously found and create our target evals
    # (to_eval and texts), which are limited to the displayed area in the buffer.
    rows_so_far = 0
    for (row, fold) in visible_rows:
      r = row - 1
      if fold:
        rows_so_far += 1
        pass
      else:
        raw_text = buf[r]
        text = bytes(raw_text, 'utf-8', 'replace') if IS_V3 else raw_text
        text_ln = len(text)
        if text_ln > 0:
          if is_explorer or is_minimap:
            to_eval.append((row-1, 0, text_ln-1))
            texts.append(text)
            rows_so_far += 1
            continue
          elif wrap:
            if text_ln > width * height and row < cursor_row:
              buf[r] = ''
              continue
            else:
              chars_left = (height - rows_so_far) * width
              if row == cursor_row:
                m_col = start_col + chars_left
                m_col = m_col if m_col < text_ln else text_ln
                s_col = start_col
              else:
                m_col = text_ln if text_ln < chars_left else chars_left 
                s_col = 1
              if row >= topline:
                  rows_so_far += math.floor((m_col - start_col) / width)
          else:
            m_col = max_col if max_col < text_ln else text_ln
            s_col = start_col
            rows_so_far += 1
          if IS_V3:
            t1 = text[0:s_col]
            t2 = t1.replace(bytes('\t', 'utf-8'),bytes(' ', 'utf-8') * win.tabstop)
            adjust_start = len(t2) - len(t1)
            adjust_end = 0
          else:
            t1 = raw_text[0:s_col]
            t2 = t1.replace('\t',' ' * win.tabstop)

            adjust_start = len(t2) - len(t1)
            adjust_end = 0

          s_col -= adjust_start
          s_col = max(s_col, 1)
          m_col = min(m_col + adjust_end, text_ln)
          to_eval.append((row - 1, s_col - 1, m_col -1))
          texts.append(text)


    # Ensure coords is setup and ready to go
    if not self.coords_key in self.shared_state['coords']:
      self.shared_state['coords'][self.coords_key] = None
    coords = self.shared_state['coords'][self.coords_key]
    contents_changed = None

    # Do a quick scan of the visible grid area. If changes are found, we need to
    # invalidate the rows >= first_changed_row
    j=0
    if coords != None:
      grid = coords['grid']
      grid_ln = len(grid)
      for (row, start_col, end_col) in to_eval:
        text = texts[j]
        j += 1
        column = start_col
        if row >= grid_ln:
          contents_changed = (row, 0)
          break
        else:
          colors = grid[row]
          if not colors:
            contents_changed = (row, 0)
            break
          colors_ln = len(colors)
          while column <= end_col:
            if column >= colors_ln:
              contents_changed = (row, 0)
              break
            else:
              current = colors[column]
              if current and current['c'] != text[column]:
                contents_changed = (row, column)
                break
            column += 1
        if contents_changed:
          break

    # If changes were found or another window found changes, we need to reset
    # the matches on this window
    if contents_changed or (coords and self.tick_id != coords['tick_id']):
      self.remove_matches()

    if contents_changed and coords:
       grid = coords['grid']
       coords['tick_id'] = GLOBALS.tick_id
       first_row = contents_changed[0]
       row = first_row
       # zero out the invalid rows
       while row < len(grid):
         grid[row] = None
         row += 1
       # grid too small? add more
       if len(grid) < buf_ln:
         coords['grid'] = grid + ([None]*(buf_ln-len(grid)))
       #grid too large? shrink
       if len(grid) > buf_ln:
         coords['grid'] = grid[0:buf_ln]



    if coords == None:
      coords = self.shared_state['coords'][self.coords_key] = {
        'grid': [None] * buf_ln,
        'tick_id': GLOBALS.tick_id,
      }

    grid = coords['grid']
    # tick_id is just a quick & dirty way we can ensure that the state is
    # synced between multiple layers of changes
    # its used here to ensure that multiple windows are reflecting their
    # own state across a shared buffer state.
    self.tick_id = coords['tick_id']

    # go through the visible area in to_eval.  Build a list of ids and gaps.
    # ids can contain synID, a int hlID, or default value. Strings are assumed
    # to be synID and will be processed using eval.
    # gaps are the areas that will need fading added.
    ids = []
    gaps = []
    ts_empty = {}
    j = 0
    for (row, column, end_col) in to_eval:
      ts_results = None
      if GLOBALS.enabletreesitter:
        try:
          # neovim users may want to highlight treesitter instead of synID
          # if any of these values are missing, synID is used as a backup.
          ts_results = vim.lua._vimade_legacy_treesitter.get_highlights(win.bufnr,row,row+1,column,end_col+1)
        except:
          pass
      if ts_results == None:
        ts_results = ts_empty

      text = texts[j]
      j += 1
      text_ln = len(text)

      if row >= len(grid) or row < 0:
        continue
      colors = grid[row]

      if colors == None:
        colors = grid[row] = [None] * text_ln
      elif text_ln < len(colors):
        colors = grid[row] = colors[0:text_ln]
      elif text_ln > len(colors):
        colors = grid[row] = colors + [None] * (text_ln - len(colors))

      while column <= end_col:
        current = colors[column]
        if current == None:
          if text[column] != '' and text[column] != sp and text[column] != tab:
            if str(column) in ts_results:
              # treesitter results are just plain int values
              ids.append(int(ts_results[str(column)]))
            else:
              # otherwise add synID to be evaled
              ids.append('synID(%s,%s,0)' % (row+1,column+1))
            gaps.append((row, column, text[column]))
          # if enablebasegroups isn't supported, we need to force spaces and tabs to be fade as Normal.
          # Neovim will typically cover listchars via NonText or another basegroup.
          elif GLOBALS.enablebasegroups == False:
            ids.append(0)
            gaps.append((row, column, text[column]))
        else:
          ids.append(current['s'])
          gaps.append((row, column, text[column]))
        column = column + 1

    fade_grid = self.fade_grid
    needs_match_add = {}

    if len(ids):
      syn_eval = []
      syn_indices = []
      for i, id in enumerate(ids):
        if type(id) == str:
          syn_eval.append(id)
          syn_indices.append(i)

      if len(syn_eval):
        # synID can only be processed on the current win, so we need to change wins.
        if not on_win:
          _goto_win(winid)
          on_win = True
        syn_eval = util.eval_and_return('[' + ','.join(syn_eval) + ']')
        for i, id in enumerate(syn_eval):
            ids[syn_indices[i]] = int(id or 0)

      # all ids goto the HIGHLIGHTER, which contains its own cache and will return
      # the correct interpolation values.
      replacement_ids = HIGHLIGHTER.create_highlights(self.win, ids)

      # ensure that we only apply the gaps and add matches where none are already present
      # each window has its own fade_grid which tracks the row/columns that are
      # faded
      for i in range(0, len(gaps)):
        (row, column, text) = gaps[i]
        if not column in grid[row]:
          grid[row][column] = {'s': ids[i], 'c': text}
        if not row in fade_grid:
          fade_grid[row] = {}
        if not column in fade_grid[row]:
          fade_grid[row][column] = replacement_ids[i]
          needs_match_add['%s:%s' % (row, column)] = True

    # fill all missing matches
    matches = {}
    fade_priority = self.win.fadepriority
    for (row, column, end_col) in to_eval:
      colors = grid[row]
      while column <= end_col:
        current = colors[column]
        r = row + 1
        c = column + 1
        if current and ('%s:%s' % (row, column)) in needs_match_add:
          hi_id = fade_grid[row][column]
          if not hi_id in matches:
            matches[hi_id] = [(r, c, 1)]
          else:
            match = matches[hi_id]
            if match[-1][0] == r and match[-1][1] + match[-1][2] == c:
              match[-1] = (r, match[-1][1], match[-1][2] + 1)
            else:
              match.append((r, c, 1))
        column += 1

    items = matches.items()
    if len(items):
      matchadds = []
      for (hi_id, coords) in items:
        i = 0
        end = len(coords)
        while i < end:
          matchadds.append(('matchaddpos("vimade_%s' % (hi_id)) + '",['+','.join(map(lambda tup:'[%s,%s,%s]' % (tup[0], tup[1], tup[2]) , coords[i:i+8]))+'],%s,-1, g:vimade_shared_var)' % (fade_priority))
          i += 8

      if len(matchadds):
        vim.vars['vimade_shared_var'] = {'window': winid}
        # add to current matches
        self.matches += util.eval_and_return('['+','.join(matchadds)+']')

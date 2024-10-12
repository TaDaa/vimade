import math
import sys
import vim
import time

# TODO VimadeFadeActive not bheaving as expected initially

M = sys.modules[__name__]
IS_V3 = False
if (sys.version_info > (3, 0)):
    IS_V3 = True

from vimade.v2 import signs as SIGNS
from vimade.v2.util import ipc as IPC
from vimade.v2.state import globals as GLOBALS
from vimade.v2 import highlighter as HIGHLIGHTER

tab = bytes('\t', 'utf-8', 'replace')[0] if IS_V3 else '\t'
sp = bytes(' ', 'utf-8', 'replace')[0] if IS_V3 else ' '
tab_v3_nr = bytes('\t', 'utf-8') if IS_V3 else '\t'
sp_v3_nr = bytes(' ', 'utf-8') if IS_V3 else ' '

M.buf_shared_lookup = {}
M._changed_win = False
IS_NVIM = GLOBALS.is_nvim

# patch 620 increased to unlimited
# https://github.com/vim/vim/issues/11248
UNLIMITED_MATCHADDPOS = bool(int(vim.eval('has("patch-9.0.0620") || has("nvim-0.9.5")')))

def _goto_win(winid):
  vim.command('silent! noautocmd call win_gotoid('+str(winid)+')')


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
    self.tick_id = GLOBALS.tick_id
    self.matches = []
    self.fade_grid = {}
    self.basegroups = []
    self.shared_state = None
    self.visible_rows = None

  # the internal state needs to be checked to ensure no bufswaps
  def refresh(self):
    if self.bufnr != self.win.bufnr:
      win = self.win
      self.cleanup() # buffer gets deactivated
      self.win = win # reattach win
      self.bufnr = win.bufnr
      self.tick_id = None
      
      lookup = M.buf_shared_lookup.get(win.bufnr)
      if not lookup:
        lookup = M.buf_shared_lookup[win.bufnr] = {
          'coords': {},
          'active': 0,
        }

      self.shared_state = lookup
      self.shared_state['active'] = self.shared_state['active'] + 1
      return True

  def cleanup(self):
    # should be called when the window is destroyed
    HIGHLIGHTER.clear_win(self.win)
    SIGNS.clear_win(self.win)
    self.unfade(True) # try to unfade

    if self.shared_state:
      self.shared_state['active'] = max(self.shared_state['active'] - 1, 0)

      if self.shared_state['active'] == 0:
        del M.buf_shared_lookup[self.bufnr]

    # circular ref, del
    self.win = None


  def add_basegroups(self):
    if GLOBALS.enablebasegroups and not self.win.vimade_winhl:
      basegroups = GLOBALS.basegroups
      def next(replacement_ids):
        replacement_winhl = ','.join([ basegroups[i]+':vimade_'+str(replacement)
                                      for i,replacement in enumerate(replacement_ids)])
        if replacement_winhl != self.win.winhl:
          IPC.eval_and_return('settabwinvar(%s,%s,"&winhl","%s")' % (self.win.tabnr, self.win.winnr, replacement_winhl))
          # TODO this management aspect needs to be controlled within namespace not manipulating external variables
          self.win.vimade_winhl = True
      HIGHLIGHTER.create_highlights(self.win, basegroups).then(next)

  def remove_basegroups(self):
    if GLOBALS.enablebasegroups and self.win.vimade_winhl:
      IPC.eval_and_return('settabwinvar(%s,%s,"&winhl","%s")' % (self.win.tabnr, self.win.winnr, self.win.original_winhl))
      # TODO this management aspect needs to be controlled within namespace not manipulating external variables
      self.win.vimade_winhl = None
      # TODO move this line below (required due some bizarre async behavior with how ns sets highlights)
      # essentially the wrong color codes are returned from winhl despite being unset.
      # redraw hack fixes the result, but costs performance so we only want to redraw when absolutely
      # necessary.
      # This should be moved into fader.py instead, but needs to live here for temporarily.
      # Disabling this hack, edge case with little value
      # Leaving comments to investigate and ensure VimadeRedraw can handle this scenario
      # if GLOBALS.tick_state & GLOBALS.RECALCULATE:
        # vim.command('redraw')

  def invalidate(self):
    self.invalidate_buffer_cache()
    self.invalidate_highlights()

  # SYNIDS will be forced to recompute during next run
  # we don't necessarily care about removing the matches (indeterminate)
  def invalidate_buffer_cache(self):
    if self.win.coords_key and self.win.coords_key in self.shared_state['coords']:
      del self.shared_state['coords'][self.win.coords_key]

  # remove matches on the win, basegroups, and clear the win from HIGHLIGHTER
  def invalidate_highlights(self):
    # Additionally we need to clear the base win color from the highlighter
    # this needs to happen before unfading
    HIGHLIGHTER.clear_colors(self.win, [self.win.original_wincolor])
    HIGHLIGHTER.clear_win(self.win)
    SIGNS.clear_win(self.win)

    self.unfade()


  def unfade(self, cleanup = False):
    win = self.win
    if not cleanup:
      if not GLOBALS.is_nvim and win.window and 'wincolor' in win.window.options:
        win.window.options['wincolor'] = win.original_wincolor or ''
    self.remove_basegroups()

    # after basegroups due to ns change
    self.remove_matches()
    self.remove_signs()


  def remove_matches(self):
    matches = self.matches

    if len(matches) > 0:
      winid = str(self.win.winid)
      try:
        # no async allowed or can cause flickering
        vim.command('|'.join(['silent! call matchdelete('+str(match)+','+winid+')' for match in matches]))
      except:
        pass
      self.matches = []
      self.fade_grid = {}

  def fade(self):
    win = self.win

    self.add_matches()
    self.add_signs()

    # basegroups should occur after adding matches as nvim can create a separate ns
    # when winhl is changed
    def next(replacement_hl):
      replacement_hl = 'vimade_%s' % replacement_hl[0]
      if not GLOBALS.is_nvim and replacement_hl and win.wincolor != replacement_hl and win.window and 'wincolor' in win.window.options:
        win.window.options['wincolor'] = replacement_hl
      self.add_basegroups()
    HIGHLIGHTER.create_highlights(win, [win.original_wincolor]).then(next)

  def add_signs(self):
    if GLOBALS.enablesigns and self.win.bufnr != None and self.visible_rows:
      SIGNS.fade_signs(self.win, self.visible_rows)

  def remove_signs(self):
    if GLOBALS.enablesigns and self.win.bufnr != None:
      SIGNS.unfade_signs(self.win)

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
    win = self.win
    winid = win.winid
    winnr = win.winnr
    bufnr = win.bufnr
    buf = win.buffer
    buf_ln = len(buf)
    coords_key = win.coords_key
    tabstop = win.tabstop
    # textoff are columns excluded from buffer_ln. These columns include
    # foldcolumn, signcolumn, etc
    width = win.width - win.textoff
    height = win.height
    cursor = win.cursor
    cursor_row = cursor[0]
    cursor_col = cursor[1]
    wrap = win.wrap
    conceallevel = win.conceallevel
    shared_state = self.shared_state['coords']
    enabletreesitter = GLOBALS.enabletreesitter
    enablebasegroups = GLOBALS.enablebasegroups

    to_eval = []
    texts = []
    matches = {}

    _goto_win(winid)

    start_row = topline = win.topline
    # add 1 for wrapped rows to handle bottom heavy edge case
    end_row = (win.botline + 1) if wrap else win.botline
    (lookup, visible_rows) = IPC.eval_and_return('[winsaveview(),vimade#GetVisibleRows('+str(start_row)+','+str(end_row)+')]')
    self.visible_rows = visible_rows
    start_col = int(lookup['leftcol']) + 1 #leftcol is based on index=0
    max_col = start_col + width
    if conceallevel > 0:
      # just assume what is hopefully the worst case here and
      # precompute additional screen chars.  Unfortunately
      # all concealed related functions have issues.
      # synconcealed doesn't return the correct results when
      # conceallevel=2 (example = help python line 31)
      # wincol() doesn't return the correct wincol without a
      # redraw.
      # every other position related function ignores conceal.
      max_col *= 2

    row = start_row
    if end_row > buf_ln:
      end_row = buf_ln
    rows_so_far = 0
    
    buf = buf[int(visible_rows[0][0])-1:int(visible_rows[-1][0])]
    buf = [bytes(b, 'utf-8', 'replace') for b in buf] if IS_V3 else buf

    for (row, fold) in visible_rows:
      row = int(row)
      fold = int(fold)
      if row > buf_ln:
        continue
      r = row - start_row
      if fold > -1:
        rows_so_far += 1
        continue
      text = buf[r]
      text_ln = len(text)
      if text_ln > 0:
        if wrap:
          if text_ln > width * height and row < cursor_row:
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
        t1 = text[0:s_col]
        t2 = t1.replace(tab_v3_nr, sp_v3_nr *tabstop)
        adjust_start = len(t2) - len(t1)
        s_col -= adjust_start
        s_col = max(s_col, 1)
        m_col = min(m_col, text_ln)
        to_eval.append((row-1, s_col - 1, m_col -1, r))

    coords = shared_state.get(coords_key)
    contents_changed = None
    treesitter_eval = None

    # shrink to_eval based on what's already been checked if fade_mode=windows or fade_active
    tick_id = GLOBALS.tick_id

    if not coords:
      coords = shared_state[coords_key] = {
        'grid': [None] * buf_ln,
        'tick_id': tick_id,
        'now': GLOBALS.now
      }
      if enabletreesitter:
        treesitter_eval = to_eval
    # the check below only needs to happen when multiple of the same buffer
    # is faded. There isn't any point in querying treesitter multiple times
    # for the same visible area.
    # TODO: This could be further improved by monitoring an 'active' field
    # per coords key, but likely to only benefit edge cases by 1 or 2 ms.
    else:
      # If a highly improbable tick_id conflict occurred, state update would
      # be skipped for shared views. We can guarentee avoidence of this issue
      # by pre-checking the conflict and then setting the tick_id to an
      # impossible value.
      if coords['tick_id'] == tick_id and coords['now'] != GLOBALS.now:
        tick_id = 1
        coords['now'] = GLOBALS.now

      grid = coords['grid']
      grid_ln = len(grid)
      if enabletreesitter:
        if self.shared_state['active'] == 1:
          treesitter_eval = to_eval
        # if self.shared_state['active'] > 1 we can skip reprocessing
        # cells that have already been checked.
        else:
          treesitter_eval = []
          for (row, start_col, max_col, text_i) in to_eval:
            if row < 0:
              continue
            if row >= grid_ln or grid[row] == None:
              treesitter_eval.append((row, start_col, max_col, text_i))
              continue
            colors = grid[row]
            colors_ln = len(colors)
            for column in range(start_col, max_col+1):
              color = colors[column] if column < colors_ln else None
              # 't' is only used by treesitter highlighter. this allows us
              # us to skip requesting parts of the screen that were already
              # evaluated in different windows. This mostly benefits
              # fademode='windows' but can also improve buffer fading as well.
              if not color or color['t'] != tick_id:
                if len(treesitter_eval) and treesitter_eval[-1][2] == column - 1:
                  treesitter_eval[-1][2] += 1
                else:
                  treesitter_eval.append([row, column, column, text_i])
      # endif enabletreesitter
      # contents changed detection
      for (row, start_col, end_col, text_i) in to_eval:
        if row >= grid_ln or not grid[row] or end_col >= len(grid[row]):
          contents_changed = (row, 0)
          break
        else:
          text = buf[text_i]
          colors = grid[row]
          for column in range(start_col, end_col+1):
            current = colors[column]
            if current and current['c'] != text[column]:
              contents_changed = (row, column)
              break
            column += 1
          if contents_changed:
            break
      # the tick_id being different indicates that the buffer contents have
      # been updated.  The current window needs to sync up to these changes.
      if contents_changed or self.tick_id != coords['tick_id']:
        self.remove_matches()
      if contents_changed:
        coords['tick_id'] = tick_id
        coords['now'] = GLOBALS.now
        first_row = contents_changed[0]
        row = first_row
        # zero out the invalid rows
        for row in range(first_row, grid_ln):
          grid[row] = None
        if grid_ln < buf_ln:
          coords['grid'] = grid + [None]*(buf_ln-grid_ln)
        if grid_ln > buf_ln:
          coords['grid'] = grid[0:buf_ln]

    fade_grid = self.fade_grid
    # ensure we have updated grid and its sized appropriately
    grid = coords['grid']
    for (row, column, end_col, text_i) in to_eval:
      if row >= len(grid) or row < 0:
        continue
      text = buf[text_i]
      if grid[row] == None:
        grid[row] = [None] * len(text)
      elif len(text) < len(grid[row]):
        grid[row] = grid[row][0:len(text)]
      elif len(text) > len(grid[row]):
        grid[row] = grid[row] + [None] * (len(text) - len(grid[row]))
      else:
        grid[row]
      fade_row = fade_grid.get(row)
      if fade_row == None:
        fade_grid[row] = fade_row = {}

    # tick_id is just a quick & dirty way we can ensure that the state is
    # synced between multiple layers of changes
    # its used here to ensure that multiple windows are reflecting their
    # own state across a shared buffer state.
    # this needs to stay here as the previous logic ensures we are synced
    # based on the tick_id value.
    self.tick_id = coords['tick_id']

    # go through the visible area in to_eval.  Build a list of ids and gaps.
    # ids can contain synID, a int hlID, or default value. Strings are assumed
    # to be synID and will be processed using eval.
    # gaps are the areas that will need fading added.
    syn_eval = []
    syn_indices = []
    ids = []
    gaps = []
    needs_redraw = [False]
    if enabletreesitter and treesitter_eval and len(treesitter_eval):
      # disable try catch to surface errors.  TODO: consider re-enable
      # try:
        ts_results = vim.lua._vimade_legacy_treesitter.get_to_eval(bufnr, treesitter_eval)
      # except:
        # ts_results = None
    else:
      ts_results = None

    def process_treesitter(to_eval):
      ts_empty = {}
      for (row, start_col, end_col, text_i) in to_eval:
        if row >= len(grid) or row < 0:
          continue
        text = buf[text_i]
        colors = grid[row]
        ts_row = ts_results.get(str(row)) if ts_results else None
        fade_row = fade_grid.get(row)
        for column in range(start_col, end_col+1):
          color = colors[column]
          ch = text[column]
          s = None
          if ch != '' and ch != sp and ch != tab:
            ts_id = ts_row.get(str(column)) if ts_row else None
            if ts_id != None:
              s = int(ts_id)
            elif color == None or color['s'] == None: ## fallback to syn
              syn_eval.append('synID('+str(row+1)+','+str(column+1)+',0)')
              syn_indices.append(len(gaps))
              gaps.append([None, row, column])
          elif enablebasegroups == False:
            s = 0
          if not color:
            colors[column] = color = {'c': ch, 's': s}
            if s != None:
              gaps.append((s, row, column))
          elif s != None and color['s'] != s:
            color['s'] = s
            # if the syntax value changed (treesitter can updated async), we
            #need to refresh the screen this should only ever happen once.
            if not needs_redraw[0]:
              needs_redraw[0] = True
              gaps.clear()
              syn_eval.clear()
              syn_indices.clear()
              self.tick_id = coords['tick_id'] = tick_id
              coords['now'] = GLOBALS.now
              self.remove_matches()
              return process_treesitter(to_eval)
            gaps.append((s, row, column))
          elif color['s'] != None and not fade_row.get(column):
            gaps.append((color['s'], row, column))
          # tick_id here is used to skip changes that have already been processed during this run
          # this is completely safe and even if a conflict was encountered, which is highly improbable
          # this would self resolve on next tick.
          color['t'] = tick_id

    def process_syn(to_eval):
      for (row, start_col, end_col, text_i) in to_eval:
        if row >= len(grid) or row < 0:
          continue
        text = buf[text_i]
        colors = grid[row]
        fade_row = fade_grid.get(row)
        for column in range(start_col, end_col+1):
          color = colors[column]
          if color == None:
            ch = text[column]
            color = colors[column] = {'c': ch, 's': None}
            if ch != '' and ch != sp and ch != tab:
              syn_eval.append('synID('+str(row+1)+','+str(column+1)+',0)')
              syn_indices.append(len(gaps))
              gaps.append([None, row, column])
            elif enablebasegroups == False:
              color['s'] = 0
              gaps.append((0, row, column))
          elif color['s'] != None and not fade_row.get(column):
            gaps.append((color['s'], row, column))
          color['t'] = tick_id

    process_treesitter(to_eval) if enabletreesitter else process_syn(to_eval)

    if len(gaps):
      if len(syn_eval):
        syn_eval = IPC.eval_and_return('[' + ','.join(syn_eval) + ']')
        for i, id in enumerate(syn_eval):
          gap = gaps[syn_indices[i]]
          grid[gap[1]][gap[2]]['s'] = gap[0] = int(id) or 0

      matches = {}
      for (id, row, column) in gaps:
        color = grid[row][column]
        fade_row = fade_grid[row]
        if not fade_row.get(column):
          fade_row[column] = True
        c = column + 1
        r = row + 1
        if not id in matches:
          matches[id] = [[r, c, 1]]
        else:
          match = matches[id]
          if match[-1][0] == r and match[-1][1] + match[-1][2] == c:
            match[-1][2] += 1
          else:
            match.append([r, c, 1])

      items = matches.items()
      match_keys = [key for key,item in items]

      def next(replacement_ids):
        if len(match_keys):
          matchadds = []
          fade_priority = str(self.win.fadepriority)
          lambda_tup = lambda tup: '[' + ','.join(map(str,tup)) + ']'
          suffix = fade_priority + ',-1,{"window":'+str(winid)+'})'
          for i, (id, coords) in enumerate(items):
            prefix = 'matchaddpos("vimade_' + str(replacement_ids[i]) + '",['
            move = len(coords) if UNLIMITED_MATCHADDPOS else 8
            matchadds.extend([prefix \
                +','.join(map(lambda_tup, coords[i:i+move])) + '],' + suffix
                for i in range(0, len(coords), move)])

          if len(matchadds):
            def add_matches(matches):
              self.matches += matches
            IPC.batch_eval_and_return('['+','.join(matchadds)+']').then(add_matches)

      replacement_ids = HIGHLIGHTER.create_highlights(self.win, match_keys).then(next)

local M = {}

M.global_focus_enabled = false

local ANIMATOR = require('vimade.animator')
local DEFAULTS = require('vimade.focus.defaults')
local WIN_STATE
local GLOBALS
local FADER

local MATH_MAX = math.max
local MATH_MIN = math.min

local MAX_CACHED_GLOBALS_PER_TAB = vim.fn.exists('g:neovide') and 0 or 2
local FOCUS_NS = vim.api.nvim_create_namespace('vimade_focus_ns')
local UNUSED_CACHE_BY_TAB = {}
local AREAS = {}
local AREAS_SELF_LOOKUP = {}
local CONFIG = {}
local OPT_KEYS
local get_filtered_opt_keys = function(winid)
  if OPT_KEYS then
    return OPT_KEYS
  end
  local winnr = vim.api.nvim_win_get_number(winid)
  local opts = vim.fn.getwinvar(winnr, '&')
  opts.scroll = nil
  opts.scrollbind = nil
  opts.winbar = nil
  OPT_KEYS = vim.tbl_keys(opts)
  return OPT_KEYS
end


local bufs = {}

local hide_area = function(area)
  vim.api.nvim_win_set_config(area.winid, {
    relative = 'editor',
    height = 1,
    width = 1,
    hide = true,
    row = 0,
    col = 0,
    anchor = 'NW',
    focusable = false,
  })
  area.hide = true
end

local has_areas_active_in_tab = function(tabnr)
  tabnr = tabnr or vim.api.nvim_get_current_tabpage()
  local active = 0
  for _, area in pairs(AREAS) do
    if area.source.tabnr == tabnr then
      active = active + 1
    end
  end
  return active > 0
end

local close_area = function(area)
  local should_close = true
  local tab = UNUSED_CACHE_BY_TAB[area.source.tabnr]
  if not tab then
    tab = {length = 0}
    UNUSED_CACHE_BY_TAB[area.source.tabnr] = tab
  end
  if area.is_focus and tab.length < MAX_CACHED_GLOBALS_PER_TAB and (area.source.winid ~= GLOBALS.current.winid or not M.global_focus_enabled) then
    tab.length = tab.length + 1

    hide_area(area)
    table.insert(tab, area)

    area.state = {}
    area.source = {}
    should_close = false
  end

  if area.mark_id then
    vim.api.nvim_buf_del_extmark(area.source.bufnr, FOCUS_NS, area.mark_id)
  end
  if should_close and vim.api.nvim_win_is_valid(area.winid) then
    vim.api.nvim_win_close(area.winid, true)
  end

  AREAS_SELF_LOOKUP[area.winid] = nil
  AREAS[area.id] = nil
  area.id = nil
end

M.__init = function(args)
  FADER = args.FADER
  GLOBALS = args.GLOBALS
  WIN_STATE = args.WIN_STATE
  ANIMATOR.on('animator:after', function()
    -- deactivate any animating focus floats
    for _, area in pairs(AREAS_SELF_LOOKUP) do
      if area.is_focus and area.source.winid ~= GLOBALS.current.winid and not ANIMATOR.is_animating(area.winid) then
        close_area(area)
      end
    end
  end)
end


local update_tab_events = function()
  local is_active_in_tab = has_areas_active_in_tab() or M.global_focus_enabled
  if vim.fn.exists('VimadeFocusTab') == 1 or not is_active_in_tab then
    if not is_active_in_tab then
      pcall(vim.api.nvim_del_augroup_by_name, 'VimadeFocusTab')
    end
    return
  end

  local existing_timer = nil
  local defer_update = function(time_ms)
    time_ms = time_ms or 0
    if existing_timer and not existing_timer:is_closing() then
      existing_timer:close()
      existing_timer = nil
    end
    existing_timer = vim.defer_fn(function()
      existing_timer = nil
      FADER.tick()
    end, time_ms)
  end

  local group = vim.api.nvim_create_augroup('VimadeFocusTab', {clear = true})
  -- CursorMoved events need to be fast, these trigger A LOT. We defer here, but basically
  -- immediately.  This helps reduce unnecessary cursor flicking.  We need to optimize cursor
  -- rendering a bit more.
  vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI', 'TextChanged', 'TextChangedT'}, {
    group = group,
    callback = function()
      FADER.tick()
    end
  })
  -- IncSearch also needs to trigger
  vim.api.nvim_create_autocmd({'CmdlineChanged'}, {
    group = group,
    callback = function(arg)
      local cmdtype = vim.fn.getcmdtype()
      if cmdtype == '/' or cmdtype == '?' then
        defer_update()
      end
    end
  })
  vim.api.nvim_create_autocmd({'ModeChanged', 'WinScrolled'}, {
    group = group,
    callback = function ()
      defer_update(8)
    end
  })
end

local refresh_folds = function(top, bottom)
  local folds = {}
  local i = top
  while i <= bottom do
    local fold = vim.fn.foldclosedend(i)
    if fold ~= -1 then
      folds[i] = fold
      i = fold
    end
    i = i + 1
  end
  return folds
end

local get_area = function(config)
  local source_winid = config.win
  local bufnr = vim.api.nvim_win_get_buf(source_winid)
  local tabnr = vim.api.nvim_win_get_tabpage(source_winid)
  local mark_id = config.mark_id or nil
  local is_focus = config.mark_id == nil

  local id = is_focus and ('g-' .. source_winid) or ('m-' .. source_winid .. '-' .. mark_id)
  id = id .. '-' .. tabnr

  local area = AREAS[id]
  if not area then
    if is_focus then
      local tab = UNUSED_CACHE_BY_TAB[tabnr]
      if tab then
        while tab.length > 0 do
          area = table.remove(tab)
          tab.length = tab.length - 1
          if vim.api.nvim_win_is_valid(area.winid) then
            break
          end
        end
      end
    end

    area = area or {}
    area.id = id
    area.mark_id = mark_id
    area.is_mark = not is_focus
    area.is_focus = is_focus
    area.state = {}
    area.source = {}
    -- set here for mark bufchange check below
    area.source.bufnr = bufnr
    area.hide = true
    AREAS[id] = area
    if area.winid then
      AREAS_SELF_LOOKUP[area.winid] = area
    end
  end

  if not area.winid or not vim.api.nvim_win_is_valid(area.winid) then
    area.winid = vim.api.nvim_open_win(bufnr, false, {
      relative = 'editor',
      -- set to height 2 due to plugins that set winbar to all windows
      -- if the height isn't large enough this automatically throws E36 Not enough room
      height = 2,
      width = 1,
      hide = true,
      row = 0,
      col = 0,
      anchor = 'NW',
      focusable = false,
      style = 'minimal',
    })
    area.hide = true
    vim.wo[area.winid].winblend = 0
    -- tempoary hack to make this work with smooth scrolling plugins
    -- TODO remove this later
    -- vim.wo[area.winid].scrollbind = true
    AREAS_SELF_LOOKUP[area.winid] = area
  end

  local changed_bufs = false
  if area.source.bufnr ~= bufnr then
    -- if the buf changed and its a mark, we just clear the mark.  It's likely not worth the
    -- maintainence to try and maintain hidden buffers. It could also lead to other issues.
    -- 0
    if mark_id then
      return close_area(area)
    end
    changed_bufs = true
    vim.api.nvim_win_set_buf(area.winid, bufnr)
  end

  if area.source_winid ~= source_winid or changed_bufs then
    vim.w[area.winid].vimade_focus = source_winid
  end

  area.source.winid = source_winid
  area.source.bufnr = bufnr
  area.source.tabnr = tabnr

  return area
end

local get_mark_surrounding = function(buf, mark_id)
  local mark = vim.api.nvim_buf_get_extmark_by_id(buf, FOCUS_NS, mark_id, {details=true})
  return {mark[1]+1, mark[3].end_row}
end

M.update_area = function(config, cache)
  cache = cache or {}
  config = config or {}
  local winid = config.win or vim.api.nvim_get_current_win()

  local area = get_area({
    win = winid,
    mark_id = config.mark_id,
  })
  if not area then
    return
  end

  local surrounding = config.mark_id and get_mark_surrounding(area.source.bufnr, area.mark_id) or nil

  -- The logic below handles folds, diffs, wordwrap (as much as possible), combinations of previously mentioned, etc
  -- changing anything in these calculations needs thorough testing
  vim.api.nvim_win_call(winid, function()
    local win_cached = cache[winid]

    -- TODO maybe some of this stuff isn't used til later'
    -- would be quicker to maybe defer if possible
    if not cache.globals then
      cache.globals = {}
      cache.globals.cmdheight = vim.go.cmdheight
      cache.globals.lines = vim.go.lines
      cache.globals.mode = vim.fn.mode():sub(1,1):lower()
    end

    local win_state = WIN_STATE.get(winid)
    if not win_cached then
      win_cached = {}
      cache[winid] = win_cached
      win_cached.info = vim.fn.getwininfo(winid)[1]
      win_cached.filetype = vim.bo[area.source.bufnr]['ft']
      win_cached.cursor = vim.api.nvim_win_get_cursor(winid)
      win_cached.config = (win_state and win_state.win_config) or vim.api.nvim_win_get_config(winid)
      win_cached.winbar = vim.wo[winid].winbar
    end
    if not win_state or win_state.blocked then
      close_area(area)
      return
    end

    local info = win_cached.info
    local config = win_cached.config
    local cursor = win_cached.cursor
    local rows = cache.globals.lines
    local cmdheight = cache.globals.cmdheight
    local wincol = info.wincol
    -- when winbar is enabled, we need to push the winrow down
    local winrow = info.winrow + ((win_cached.winbar and win_cached.winbar ~= '') and 1 or 0)
    local width = info.width
    local topline = info.topline
    local botline = info.botline
    local win = {
      winid = area.source.winid,
      bufnr = area.source.bufnr,
      cursor = cursor,
      height = info.height,
      width = width,
      topline = topline,
      botline = botline,
    }
    local mode = cache.globals.mode

    -- this selects the visually selected line if the user is in Visual mode.
    if not area.mark_id and not surrounding and mode == 'v' then
      local visualpos = vim.fn.line("v")
      surrounding = {
        MATH_MIN(visualpos, cursor[1]),
        MATH_MAX(visualpos, cursor[1])
      }
    end
    -- iterate providers until we have a result
    if not surrounding then
      local providers = CONFIG.providers.filetypes[win_cached.filetype] or CONFIG.providers.filetypes.default
      for _, provider in ipairs(providers) do
        if provider and provider.get then
          surrounding = provider.get(topline, botline, win)
          if surrounding then
            break
          end
        end
      end
    end
    -- default to cursor position if not found
    if not surrounding then
      surrounding = {cursor[1], cursor[1] }
    end
    if not surrounding[1] then
      surrounding[1] = surrounding[2] or cursor[1]
    end
    if not surrounding[2] then
      surrounding[2] = surrounding[1] or cursor[1]
    end
    -- account for swapped start / end
    if surrounding[2] < surrounding[1] then
      local tmp = surrounding[2]
      surrounding[2] = surrounding[1]
      surrounding[1] = tmp
    end


    -- hide out of range areas
    if surrounding[2] < topline or surrounding[1] > botline then
      return not config.hide and hide_area(area)
    end

    if not win_cached.folds then
      win_cached.foldmethod = vim.wo[winid].foldmethod
      win_cached.folds = {}
      if win_cached.foldmethod == 'manual' then
        -- TODO move folds into state
        win_cached.folds = refresh_folds(win_cached.info.topline, win_cached.info.botline)
      else
        win_cached.folds = true
      end
    end
    area.state.folds = win_cached.folds

    local top_row = MATH_MAX(surrounding[1], topline)
    local end_row = MATH_MIN(surrounding[2], botline)

    -- top_only is the very first row at the top of the window
    -- top_only.all = the line + fill.
    -- top_only.fill = the amount of diff filled above the line.
    -- NOTE: the first line may have a height that extends beyond the window top in diff mode
    -- (this needs to be subtracted later)
    if not win_cached.top_only then
      win_cached.top_only =  vim.api.nvim_win_text_height(winid, {
        start_row = topline - 1,
        end_row = topline - 1,
      })
    end
    local top_only = win_cached.top_only
    -- top_part is the area above the target start_row, starting at the window topline
    -- NOTE: the first line may have a height that extends beyond the window top in diff mode
    -- (this needs to be subtracted later)
    local top_part =  vim.api.nvim_win_text_height(winid, {
      -- start_row = math.min(topline - 1, top_row - 1),
      start_row = topline - 1,
      end_row = top_row - 1,
    })
    -- total_part is the area from the window start to the bottom target row.
    -- NOTE: the first line may have a height that extends beyond the window top in diff mode
    -- (this needs to be subtracted later)
    local total_part =  vim.api.nvim_win_text_height(winid, {
      -- start_row = math.min(topline - 1, top_row - 1),
      start_row = topline - 1,
      end_row = end_row - 1,
    })
    -- top_line_part is just the start target row. This is only used to determine if the first row was
    -- subjected to wrap rules.  If it was, then we need to adjust the top and height to account for
    -- the difference
    local top_line_part =  vim.api.nvim_win_text_height(winid, {
      start_row = top_row - 1,
      end_row = top_row - 1
    })
    -- height_part is the height from (start_row + 1) to end_row.
    -- We skip the first line here because the height might have additional fill lines.  We need to determine
    -- these later and add back in the correct height.
    local height_part =  vim.api.nvim_win_text_height(winid, {
      start_row = math.min(top_row, end_row - 1),
      end_row = end_row - 1,
    })

    local top = top_part.all + winrow - 2 -- (sub 1 for winrow and 1 for top_part.all)
    local height = 0

    -- account for wrapping in the first line
    if top_line_part.all > 1 and top_line_part.fill == 0 then
      top = top - (top_line_part.all - 1)
      height = height + (top_line_part.all - 1)
    end

    if not win_cached.view then
      win_cached.view = vim.fn.winsaveview()
    end
    local view = win_cached.view

    local neg_extra_diff = view.topfill - top_only.fill
    height = height + total_part.all - top_part.all + 1
    
    top = top + neg_extra_diff

    -- Prevent anchoring in floating windows that extend past the cmdheight. Anchoring causes the float to "stick"
    -- to the bottom even though it should actually extend past the last line.  This causes the float to scroll
    -- when it shouldn't. This isn't caused by vimade, but instead but the plugin who created the source window
    -- incorrectly.
    if ((top + height)) > (rows - cmdheight) then
      height = height - (((top + height)) - (rows - cmdheight))
    end

    -- hides any focus / marks that are out of view.
    if height == 0 or top >= (winrow - 1 + info.height) or (top + height) <= (winrow - 1) then
      return not config.hide and hide_area(area)
    end

    -- safety clamps
    top = math.max(top, 0)
    height = math.min(MATH_MAX(height, 1), info.height)

    -- account for floating borders (this adds 1 top and left)
    if config.border then
      wincol = wincol + 1
      top = top + 1
    end

    -- sync the source window options to the area except for the ones previously excluded
    local opt_keys = get_filtered_opt_keys(winid)
    local area_opts = vim.wo[area.winid]
    local source_opts = vim.wo[winid]
    -- explicity unset winbar as some plugins try to stick it every window
    -- including floating windows.
    -- TODO(maybe it would be cool to have something here esp for marks...)
    area_opts.winbar = nil
    for _, key in ipairs(opt_keys) do
      local source_value = source_opts[key]
      if source_value ~= area_opts[key] then
        area_opts[key] = source_value
      end
    end

    local area_state = area.state
    local area_config = area_state.config or {}
    local area_view = area_state.view or {}
    local has_or_had_folds = area_state.had_folds or
      (area.state.folds ~= true and next(area.state.folds)) and true or false

    local set_area_config = false
    if area.hide or area_config.hide ~= false or area_config.height ~= height or area_config.width ~= width
      or area_config.row ~= top or area_config.col ~= (wincol - 1) then
      set_area_config = true
    end

    local set_area_view = false
    if top_row ~= area_view.topline or view.leftcol ~= area_view.leftcol
      or view.skipcol ~= area_view.skipcol or view.topfill ~= area_view.topfill
      or area_view.lnum ~= cursor[1] or area_view.col ~= cursor[2] then
      set_area_view = true
    end

    if set_area_config or set_area_view or has_or_had_folds then
      vim.api.nvim_win_call(area.winid, function()
        if set_area_config then
          local zindex = area.is_mark and 2 or 1
          area_state.config = {
            relative = 'editor',
            height = height,
            width = width,
            anchor = 'NW',
            row = top,
            col = wincol - 1,
            hide = false,
            focusable = false,
            zindex = config.zindex and (config.zindex + zindex) or zindex,
          }
          area.hide = false
          -- TODO we need to defer set_config for redraw consistency
          vim.api.nvim_win_set_config(area.winid, area_state.config)
        end

        if has_or_had_folds then
          if win_cached.foldmethod == 'manual' then
            if area_state.had_folds then
              area_state.had_folds = false
              pcall(vim.cmd,'normal! zE')
            end
            local folds = area.state.folds
            local had_folds = false
            local i = topline
            while i <= botline do
              local end_ = folds[i]
              if end_ then
                had_folds = true
                vim.cmd(i..','..end_ ..' fold')
                i = end_
              end
              i = i + 1
            end
            area_state.had_folds = had_folds
          end
        end

        -- if we unfolded, we need to re-set the view as well
        if has_or_had_folds or set_area_view then
          area_state.view = {
            topline = top_row,
            leftcol = view.leftcol,
            lnum = cursor[1],
            col = cursor[2],
            skipcol = view.skipcol,
            -- important topfill=0 otherwise vim performs some auto decision making that can be wrong!
            topfill = 0,
          }
          vim.fn.winrestview(area_state.view)
        end
      end)
    end

    if mode == 'n' then
      -- TODO confirm flash behavior -- we were using this but its a performance killer
      -- also you should only do this for the current window ones
      -- vim.api.nvim__redraw({win=area_win.winid, flush=true, valid=true})
    end
  end)

  return area
end

local id = 0
M.update = function(config)
  config = config or {}
  -- local start_time = vim.uv.hrtime()
  local last_ei
  if config.prevent_events then
    last_ei = vim.go.ei
    vim.go.ei = 'all'
  end

  local cache = {}
  local tabnr = config.tabnr or vim.api.nvim_get_current_tabpage()
  local winid = config.winid or vim.api.nvim_get_current_win()
  local winids = {}

  for _, area in pairs(AREAS) do
    -- update marks and global_focus windows that are not in the current window
    if area.source.tabnr == tabnr and (area.mark_id or area.source.winid ~= winid) then
      -- the source window needs to be valid! otherwise this area is done!
      if vim.api.nvim_win_is_valid(area.source.winid) then
        local area = M.update_area({win = area.source.winid, mark_id = area.mark_id}, cache)
        if area then
          winids[area.winid] = true
        end
      else
        close_area(area)
      end
    end
  end

  if M.global_focus_enabled then
    -- update the current window (in case it doesn't exist yet)
    local area = M.update_area({win = winid}, cache)
    if area then
      winids[area.winid] = true
    end
  end

  -- print((vim.uv.hrtime() - start_time)*1e-6)
  if config.prevent_events then
    vim.go.ei = last_ei
  end
  return winids
end

-- TODO see if this behavior is intuitive
-- Removes any marks that overlap the selection. If no marks were removed, a new mark is added.
-- config = {
  -- @optional range={start, end} [default = cursor_location],
  -- @optional winid: number [default = vim.api.nvim_get_current_win()]
-- }
M.mark_toggle = function(config)
  if not (M.mark_remove(config)) then
    M.mark_set(config)
  end
end

-- Places a mark between the range of lines in the window.
-- config = {
  -- @optional range={start, end} [default = cursor_location],
  -- @optional winid: number [default = vim.api.nvim_get_current_win()]
-- }
M.mark_set = function(config)
  local winid = config.winid or vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local range = config.range
  if not range then
    local cursor = vim.api.nvim_win_get_cursor(winid)
    range = {cursor[1], cursor[1]}
  end
  local mark_id = vim.api.nvim_buf_set_extmark(bufnr, FOCUS_NS, range[1]-1, 0, {
    end_row = range[2],
    end_col = 0,
    hl_group = 'VimadeMark' -- TODO lets apply a slight inversion on this as well so that it is easy to spot
  })

  M.update_area({
    win = winid,
    mark_id = mark_id, 
  })

  update_tab_events()
end

-- Removes all marks meeting the criteria. If no criteria is included, all marks are removed.
-- Note: providing a range will remove any marks overlapping that range.
-- config = {
  -- @optional range: {start, end} -- NOTE: If range is provided without winid, the current window is assumed.
  -- @optional winid: number
  -- @optional bufnr: number
  -- @optional tabnr: number
-- }
M.mark_remove = function(config)
  local winid = config.winid
  local bufnr = config.bufnr
  local tabnr = config.tabnr

  if config.range and not config.winid then
    winid = vim.api.nvim_get_current_win()
  end
  local to_delete = {}
  for _, area in pairs(AREAS) do
    if area.is_mark then
      if (not winid and not bufnr and not tabnr)
        or (winid and area.source.winid == winid)
        or (bufnr and area.source.bufnr == bufnr)
        or (tabnr and area.source.tabnr == tabnr) then
        table.insert(to_delete, area)
      end
    end
  end
  local marks_in_range
  if config.range then
    local marks = vim.api.nvim_buf_get_extmarks(bufnr or vim.api.nvim_win_get_buf(winid), FOCUS_NS, {config.range[1] - 1, 0}, {config.range[2] - 1, 0}, {overlap = true})
    marks_in_range = {}
    for _, mark in ipairs(marks) do
      marks_in_range[mark[1]] = true
    end
  end

  local removed = false
  for _, area in ipairs(to_delete) do
    if not marks_in_range or marks_in_range[area.mark_id] then
      removed = true
      close_area(area)
    end
  end

  update_tab_events()

  return removed
end

M.activate_focus = function()
  M.global_focus_enabled = true

  M.update({
    prevent_events = true
  })

  update_tab_events()
end

-- Off only turns off the global focus areas. Marks are still active
M.deactivate_focus = function()
  M.global_focus_enabled = false
  for _, area in pairs(AREAS) do
    if not area.mark_id then
      close_area(area)
    end
  end

  update_tab_events()
end

-- Note: this should only be called internally by vimade.
M.cleanup = function(active_winids)
  for _, area in pairs(AREAS) do
    if not active_winids[area.source.winid]
      or area.is_focus and area.source.winid ~= GLOBALS.current.winid and not ANIMATOR.is_animating(area.winid) then
      close_area(area)
    end
  end
end

-- monitor tab events, we may deactive some events depending on whether areas are actually
-- present.
local group = vim.api.nvim_create_augroup('VimadeFocus', {clear = true})
vim.api.nvim_create_autocmd({'TabEnter'}, {
  group = group,
  callback = function ()
    vim.defer_fn(
    function()
      FADER.tick()
      update_tab_events()
    end, 0)
  end
})

M.get = function (winid)
  return AREAS_SELF_LOOKUP[winid]
end


M.setup = function(config)
  CONFIG = DEFAULTS(config)
  M.update({
    prevent_events = true
  })
  update_tab_events()
end

return M

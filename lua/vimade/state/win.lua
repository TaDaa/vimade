local M = {}

local bit = require('bit')
local BIT_BAND = bit.band
local BIT_BOR = bit.bor

local NAMESPACE = require('vimade.state.namespace')
local REAL_NAMESPACE = require('vimade.state.real_namespace')
local LINK = require('vimade.config_helpers.link')
local BLOCKLIST = require('vimade.config_helpers.blocklist')
local COLOR_UTIL = require('vimade.util.color')
local COMPAT = require('vimade.util.compat')
local TYPE = require('vimade.util.type')
local FOCUS = require('vimade.focus')

local HIGHLIGHTERS = {
  require('vimade.highlighters.terminal'),
  require('vimade.highlighters.namespace'),
}

local GLOBALS
local FADER

M.__init = function(args)
  FADER = args.FADER
  GLOBALS = args.GLOBALS
  FADER.on('tick:before', function ()
    M.current = nil
  end)
end

M.cache = {}

local _update_state = function (next, current, state)
  local modified = false
  for field, value in pairs(next) do
    if current[field] ~= value then
      current[field] = value
      modified = true
    end
  end
  return modified and state or GLOBALS.READY
end

-- return without updating state
M.get = function(winid)
  return M.cache[winid]
end

M.unhighlight = function (win)
  win.nc = false
  for _, highlighter in ipairs(HIGHLIGHTERS) do
    if not highlighter.is_type or highlighter.is_type(win) then
      highlighter.unhighlight(win)
    end
  end
end

M.cleanup = function (active_winids)
  for winid, value in pairs(M.cache) do
    if active_winids[winid] == nil then
      M.cache[winid] = nil
      NAMESPACE.clear_winid(winid)
    end
  end
end

M.__create = function (winid)
  if M.cache[winid] == nil then
    local area = FOCUS.get(winid)
    local win = {
      winid = winid,
      bufnr = nil,
      terminal = nil,
      width = -1,
      height = -1,
      linked = false,
      blocked = false,
      blocked_highlights = {},
      nc = false,
      hi_key = '',
      is_active_win = nil,
      is_active_buf = nil,
      area_owner = nil,
      area = area,
      is_focus = area and area.is_focus, -- should never change
      is_mark = area and area.is_mark, -- should never change
      style_state = {
        animations = {},
        custom = {}
      },
      timestamps = {
        active_win = 0,
        active_buf = 0,
        nc = 0,
      },
      winhl = nil,
      real_ns = nil,
      ns = nil,
      state = GLOBALS.READY,
      style = {},
      terminal = false,
      terminal_match = nil,
      -- raw global styles that were used to build this win
      _global_style = {},
      buf_opts = nil,
      buf_vars = nil,
      win_opts = nil,
      win_vars = nil,
    }
    M.cache[winid] = win
  end
  return M.cache[winid]
end

M.refresh_active = function (winid)
  local win = M.refresh(winid, true)
  return win
end

M.refresh = function (winid, is_active)
  if not vim.api.nvim_win_is_valid(winid) then
    return
  end
  local win = M.__create(winid)
  if is_active then
    M.current = win
  end

  win.state = GLOBALS.READY
  win.winid = winid
  win.bufnr = vim.api.nvim_win_get_buf(winid)
  win.buf_name = vim.api.nvim_buf_get_name(win.bufnr)
  win.win_type = vim.fn.win_gettype(win.winid)
  win.win_config = vim.api.nvim_win_get_config(win.winid)
  win.buf_opts = vim.bo[win.bufnr]
  win.buf_vars = vim.b[win.bufnr]
  win.win_opts = vim.wo[win.winid]
  win.win_vars = vim.w[win.winid]
  win.terminal = win.buf_opts.buftype == 'terminal'

  local is_active_win = win.winid == GLOBALS.current.winid
  local is_active_buf = win.bufnr == GLOBALS.current.bufnr

  -- area timestamps and 'active' status is inherited from the owner window
  -- it does not need to be set or relied on.
  if not win.area then
    if is_active_win ~= win.is_active_win then
      win.is_active_win = is_active_win
      win.timestamps.active_win = GLOBALS.now
    end
    if is_active_buf ~= win.is_active_buf then
      win.is_active_buf = is_active_buf
      win.timestamps.active_win = GLOBALS.now
    end
  else
    local area_owner = M.get(win.area.source.winid)
    if area_owner then
      win.area_owner = area_owner
    end
    if  win.area.hide then
      return
    end
  end

  local can_nc = not (vim.b[win.bufnr].vimade_disabled == 1
    or vim.w[win.winid].vimade_disabled == 1)

  local blocked = false
  -- areas should skip the blocklist in all scenarios
  if not win.area then
    for key, value in pairs(GLOBALS.blocklist) do
      if type(value) == 'table' then
        blocked = BLOCKLIST.DEFAULT(win, M.current, value)
      elseif type(value) == 'function' then
        blocked = value(win, M.current)
      end
      if blocked == true then
        can_nc = false
        break
      end
    end
    win.blocked = blocked
  end

  if blocked then
    return M.unhighlight(win)
  end

  local should_nc = false
  local hi_active = can_nc and GLOBALS.vimade_fade_active
  local hi_inactive = can_nc

  if GLOBALS.nc_windows and win.is_active_win then
    should_nc = hi_active
  elseif GLOBALS.nc_buffers and win.is_active_buf then
    should_nc = hi_active
  elseif (GLOBALS.nc_windows or GLOBALS.nc_buffers) then
    should_nc = hi_inactive
  end

  local linked = false
  if M.current and not is_active and not blocked then
    for key, value in pairs(GLOBALS.link) do
      if type(value) == 'table' then
        linked = LINK.DEFAULT(win, M.current, value)
      elseif type(value) == 'function' then
        linked = value(win, M.current)
      end
      if linked == true then
        should_nc = hi_active
        break
      end
    end
  end
  win.linked = linked

  -- check namespaces
  -- TODO this should actually occur before blocked
  local active_ns = COMPAT.nvim_get_hl_ns({winid = win.winid})
  local winhl
  local real_ns
  if NAMESPACE.is_vimade_ns(active_ns) == true then
    real_ns = win.real_ns
    winhl = win.winhl
  else
    winhl = vim.wo[win.winid].winhl
    real_ns = winhl and 0 or (active_ns == -1 and 0 or active_ns)
  end
  win.real_ns = real_ns
  win.winhl = winhl
  vim.w[win.winid]._vimade_real_ns = real_ns

  if (should_nc and not win.nc) or (not should_nc and win.nc) then
    win.timestamps.nc = GLOBALS.now
  end

  win.state = BIT_BOR(win.state, _update_state({
    nc = should_nc
  }, win, GLOBALS.CHANGED))

  local basebg = GLOBALS.basebg
  local basebg_key = ''
  if type(basebg) == 'function' then
    basebg = basebg(win, M.current)
  end
  if basebg then
    basebg = COLOR_UTIL.to24b(basebg)
  end
  if type(basebg) == 'number' then
    win.basebg = basebg
    basebg_key = 'bg(' .. basebg .. ')'
  else
    win.basebg = nil
  end


  local rerun_style = false
  if #win._global_style ~= #GLOBALS.style then
    rerun_style = true
  else
    for i, s in ipairs(GLOBALS.style) do
      if win._global_style[i] ~= s then
        rerun_style = true
        break
      end
    end
  end
  if rerun_style == true then
    win.style = {}
    win._global_style = {}
    for i, s in ipairs(GLOBALS.style) do
      win._global_style[i] = s
      win.style[i] = s.attach(win, win.style_state)
    end
  end

  local hi_key = (winhl or win.real_ns) .. ':' 
  hi_key = hi_key .. ':' .. basebg_key

  -- this is to separate out the logic for inactive vs active.  we can use this for highlighting
  -- the active ns in the future
  local style_active = 0
  if not blocked then
    for i, s in ipairs(win.style) do
      s.before(win, win.style_state)
      local style_key = s.key(win, style_state)
      if string.len(style_key) > 0 then
        if style_active > 0 then
          hi_key = hi_key .. '#'
        end
        hi_key = hi_key .. style_key
        style_active = style_active + 1
      end
    end
    win.blocked_highlights = BLOCKLIST.HIGHLIGHTS(win, M.current)
    hi_key = hi_key .. ':bh(' .. BLOCKLIST.TO_HIGHLIGHTS_KEY(win.blocked_highlights) .. ')'
  end

  local redraw = false
  if style_active > 0
    and (not win.ns
    or REAL_NAMESPACE.is_desync(win.ns.real)
    or not GLOBALS.nohlcheck
    or win.hi_key ~= hi_key
    or BIT_BAND(GLOBALS.tick_state, GLOBALS.RECALCULATE) > 0) then
    local ns = NAMESPACE.get_replacement(win, real_ns, hi_key, false)
    if ns.modified then
      redraw = true
    end
    if ns.modified or ns ~= win.ns or win.hi_key ~= hi_key then
      win.state = BIT_BOR(GLOBALS.CHANGED, win.state)
    end
    win.ns = ns
  end

  win.hi_key = hi_key

  if win.ns and win.ns.real.complete_highlights then
    for _, highlighter in ipairs(HIGHLIGHTERS) do
      if not highlighter.is_type or highlighter.is_type(win) then
        if style_active == 0 then
          highlighter.unhighlight(win)
        else
          highlighter.highlight(win, redraw)
        end
      end
    end
  end
  return win
end

return M

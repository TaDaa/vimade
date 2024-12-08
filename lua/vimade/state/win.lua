local M = {}

local NAMESPACE = require('vimade.state.namespace')
local LINK = require('vimade.config_helpers.link')
local BLOCKLIST = require('vimade.config_helpers.blocklist')
local HIGHLIGHTER = require('vimade.highlighter')
local COLOR_UTIL = require('vimade.util.color')
local COMPAT = require('vimade.util.compat')
local TYPE = require('vimade.util.type')
local GLOBALS
local FADER

M.__init = function(args)
  FADER = args.FADER
  GLOBALS = args.GLOBALS
  FADER.on('tick:before', function ()
    M.ns_cache = {}
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
M.get = function(wininfo)
  return M.cache[tonumber(wininfo.winid)]
end

M.unhighlight = function (winid)
  local win = M.cache[winid]
  if win then
    win.nc = false
  end
end

M.cleanup = function (wininfos)
  local map = {}
  for key, wininfo in pairs(wininfos) do
    map[tonumber(wininfo.winid)] = true
  end
  for winid, value in pairs(M.cache) do
    if map[winid] == nil then
      M.cache[winid] = nil
      NAMESPACE.clear_winid(winid)
    end
  end
end

M.__create = function (winid)
  if M.cache[winid] == nil then
    local win = {
      winid = winid,
      winnr = nil,
      bufnr = nil,
      tabnr = nil,
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
      style_state = {
        animations = {},
        custom = {}
      },
      timestamps = {
        active_win = 0,
        active_buf = 0,
        nc = 0,
      },
      real_ns = 0,
      ns = nil,
      state = GLOBALS.READY,
      style = {},
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

M.refresh_active = function (wininfo)
  local win = M.refresh(wininfo, true)
  return win
end

M.refresh = function (wininfo, is_active)
  local winid = tonumber(wininfo.winid)
  local win = M.__create(winid)
  if is_active then
    M.current = win
  end

  win.state = GLOBALS.READY
  win.winid = winid
  win.terminal = wininfo.terminal
  win.winnr = tonumber(wininfo.winnr)
  win.bufnr = tonumber(wininfo.bufnr)
  win.tabnr = tonumber(wininfo.tabnr)

  win.buf_name = vim.api.nvim_buf_get_name(win.bufnr)
  win.win_type = vim.fn.win_gettype(win.winid)
  win.win_config = vim.api.nvim_win_get_config(win.winid)
  win.buf_opts = vim.bo[win.bufnr]
  win.buf_vars = vim.b[win.bufnr]
  win.win_opts = vim.wo[win.winid]
  win.win_vars = vim.w[win.winid]

  local is_active_win = win.winid == GLOBALS.current.winid
  local is_active_buf = win.bufnr == GLOBALS.current.bufnr

  if is_active_win ~= win.is_active_win then
    win.is_active_win = is_active_win
    win.timestamps.active_win = GLOBALS.now
  end
  if is_active_buf ~= win.is_active_buf then
    win.is_active_buf = is_active_buf
    win.timestamps.active_win = GLOBALS.now
  end

  local can_nc = not (vim.b[win.bufnr].vimade_disabled == 1
    or vim.w[win.winid].vimade_disabled == 1)

  local blocked = false
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

  local should_nc = false
  local hi_active = can_nc and GLOBALS.vimade_fade_active
  local hi_inactive = can_nc

  if GLOBALS.nc_windows and win.is_active_win then
    should_nc = hi_active
  elseif GLOBALS.nc_buffers and win.is_active_buf then
    should_nc = hi_active
  else
    should_nc = hi_inactive
  end

  local linked = false
  if M.current and not is_active then
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
  local active_ns = COMPAT.nvim_get_hl_ns({winid = win.winid})
  local real_ns
  if NAMESPACE.is_vimade_ns(active_ns) == true then
    real_ns = win.real_ns
  else
    real_ns = active_ns == -1 and 0 or active_ns
  end
  win.real_ns =  real_ns
  vim.w[win.winid]._vimade_real_ns = real_ns

  if (should_nc and not win.nc) or (not should_nc and win.nc) then
    win.timestamps.nc = GLOBALS.now
  end

  win.state = bit.bor(win.state, _update_state({
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

  local hi_key = win.real_ns .. ':' 
  if win.is_active_win then
    hi_key = 'ac:' .. hi_key
  else
    hi_key = 'nc:' .. hi_key
  end
  hi_key = hi_key .. ':' .. basebg_key

  -- this is to separate out the logic for inactive vs active.  we can use this for highlighting
  -- the active ns in the future
  local style_active = 0
  if blocked == false then
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
    hi_key = hi_key .. ':bh' .. BLOCKLIST.TO_HIGHLIGHTS_KEY(win.blocked_highlights)
  end

  if style_active > 0
    and (not win.ns
    or not GLOBALS.nohlcheck
    or win.ns.modified
    or win.hi_key ~= hi_key
    or bit.band(GLOBALS.tick_state, GLOBALS.RECALCULATE) > 0) then
    local ns = NAMESPACE.get_replacement(win, real_ns, hi_key)
    if ns.modified == true or win.hi_key ~= hi_key then
      win.state = bit.bor(GLOBALS.CHANGED, win.state)
      ns.modified = true
    end
    win.hi_key = hi_key
    win.ns = ns
  end

  -- every namespace needs to be set again, this is related to the issues where the Neovim API
  -- sets / returns incorrect values for namespace highlights.
  if win.ns and win.ns.real.complete_highlights then
    if style_active == 0 then
      win.current_ns = win.real_ns
    else
      if M.ns_cache[win.ns.vimade_ns] == nil then
        HIGHLIGHTER.set_highlights(win)
        M.ns_cache[win.ns.vimade_ns] = true
      end
      win.current_ns = win.ns.vimade_ns
    end
  end
  return win
end

return M

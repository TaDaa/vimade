local M = {}
local GLOBALS = require('vimade.state.globals')
local NAMESPACE = require('vimade.state.namespace')
local LINK = require('vimade.config_helpers.link')
local BLOCKLIST = require('vimade.config_helpers.blocklist')

M.cache = {}
M.current = nil

M.READY = 0
M.ERROR = 1
M.CHANGED = 2

local _update_state = function (next, current, state)
  local modified = false
  for field, value in pairs(next) do
    if current[field] ~= value then
      current[field] = value
      modified = true
    end
  end
  return modified and state or M.READY
end

-- return without updating state
M.get = function(wininfo)
  return M.cache[tonumber(wininfo.winid)]
end

M.unfade = function (winid)
  local win = M.cache[winid]
  if win then
    win.faded = false
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
     win = {
      winid = winid,
      winnr = nil,
      bufnr = nil,
      tabnr = nil,
      terminal = nil,
      width = -1,
      height = -1,
      linked = false,
      blocked = false,
      faded = false,
      is_active_win = nil,
      is_active_buf = nil,
      real_ns = nil,
      ns = nil,
      modified = M.READY,
      buf_opts = function(self)
        return vim.bo[self.bufnr]
      end,
      buf_vars = function(self)
        return vim.b[self.bufnr]
      end,
      win_opts = function(self)
        return vim.wo[self.winid]
      end,
      win_vars = function(self)
        return vim.w[self.winid]
      end,
    }
    M.cache[winid] = win
  end
  return M.cache[winid]
end

M.from_current = function (wininfo)
  local win = M.from_other(wininfo, true)
  M.current = win
  return win
end

M.from_other = function (wininfo, skip_link)
  local winid = tonumber(wininfo.winid)
  local win = M.__create(winid)

  win.modified = M.READY
  win.winid = winid
  win.terminal = wininfo.terminal
  win.winnr = tonumber(wininfo.winnr)
  win.bufnr = tonumber(wininfo.bufnr)
  win.tabnr = tonumber(wininfo.tabnr)

  win.buf_name = vim.api.nvim_buf_get_name(win.bufnr)
  win.win_config = vim.api.nvim_win_get_config(win.winid)

  win.is_active_win = win.winid == GLOBALS.current.winid
  win.is_active_buf = win.bufnr == GLOBALS.current.bufnr

  local can_fade = not (vim.b[win.bufnr].vimade_disabled == 1
    or vim.w[win.winid].vimade_disabled == 1)

  local blocked = false
  for key, value in pairs(GLOBALS.blocklist) do
    if type(value) == 'table' then
      blocked = BLOCKLIST.DEFAULT(win, M.current, value)
    elseif type(value) == 'function' then
      blocked = value(win, M.current)
    end
    if blocked == true then
      can_fade = false
      break
    end
  end

  local should_fade = false
  local fade_active = can_fade and GLOBALS.vimade_fade_active
  local fade_inactive = can_fade

  if GLOBALS.fade_windows and win.is_active_win then
    should_fade = fade_active
  elseif GLOBALS.fade_buffers and win.is_active_buf then
    should_fade = fade_active
  else
    should_fade = fade_inactive
  end

  local linked = false
  if M.current and not skip_link then
    for key, value in pairs(GLOBALS.link) do
      if type(value) == 'table' then
        linked = LINK.DEFAULT(win, M.current, value)
      elseif type(value) == 'function' then
        linked = value(win, M.current)
      end
      if linked == true then
        should_fade = fade_active
        break
      end
    end
  end
  win.linked = linked

  -- check namespaces
  local ns = vim.api.nvim_get_hl_ns({winid = win.winid})
  local real_ns
  if NAMESPACE.is_vimade_ns(ns) == true then
    real_ns = vim.w[win.winid]._vimade_real_ns or 0
  else
    real_ns = ns == -1 and 0 or ns
  end
  win.real_ns =  real_ns
  vim.w[win.winid]._vimade_real_ns = real_ns

  if GLOBALS.fadeconditions then
    for i, condition in ipairs(GLOBALS.fadeconditions) do
      local override = condition(win, M.current)
      -- the first condition that returns a bool value wins
      if override == true or override == false then
        should_fade = override
        break
      end
    end
  end

  win.modified = bit.bor(win.modified, _update_state({
    faded = should_fade
  }, win, M.CHANGED))


  if should_fade == true then
    local tint
    local fadelevel
    if type(GLOBALS.tint) == 'function' then
      tint = GLOBALS.tint(win, M.current)
    else
      tint = GLOBALS.tint
    end
    if type(GLOBALS.fadelevel) == 'function' then
      fadelevel = GLOBALS.fadelevel(win, M.current)
    else
      fadelevel = GLOBALS.fadelevel
    end
    win.modified = bit.bor(win.modified, _update_state({
      fadelevel = fadelevel,
      tint = tint,
    }, win, M.CHANGED))


    if not GLOBALS.nohlcheck
      or GLOBALS.tick_state >= GLOBALS.RECALCULATE then
      local ns = NAMESPACE.get_replacement(win, real_ns)
      if ns.modified == true then
        win.modified = bit.bor(M.CHANGED, win.modified)
      end
      win.ns = ns
    end
  end

  -- already checked --

  return win
end

return M

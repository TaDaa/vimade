local M = {}
local GLOBALS = require('vimade.state.globals')
local NAMESPACE = require('vimade.state.namespace')
local LINK = require('vimade.config_helpers.link')
local BLOCKLIST = require('vimade.config_helpers.blocklist')
local HIGHLIGHTER = require('vimade.highlighter')
local COMPAT = require('vimade.util.compat')

M.cache = {}
M.current = nil
M.fading_cache = {
  tick_id = -1
}

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
      hi_key = '',
      is_active_win = nil,
      is_active_buf = nil,
      real_ns = nil,
      ns = nil,
      state = GLOBALS.READY,
      modifiers = {},
      -- raw global modifiers that were used to build this win
      _global_modifiers = {},
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

M.refresh_active = function (wininfo)
  local win = M.refresh(wininfo, true)
  M.current = win
  return win
end

M.refresh = function (wininfo, skip_link)
  local winid = tonumber(wininfo.winid)
  local win = M.__create(winid)

  win.state = GLOBALS.READY
  win.winid = winid
  win.terminal = wininfo.terminal
  win.winnr = tonumber(wininfo.winnr)
  win.bufnr = tonumber(wininfo.bufnr)
  win.tabnr = tonumber(wininfo.tabnr)

  win.buf_name = vim.api.nvim_buf_get_name(win.bufnr)
  win.win_type = vim.fn.win_gettype(win.winid)
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
  local ns = COMPAT.nvim_get_hl_ns({winid = win.winid})
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

  win.state = bit.bor(win.state, _update_state({
    faded = should_fade
  }, win, GLOBALS.CHANGED))


  local rerun_modifiers = false
  if should_fade == true then
    if #win._global_modifiers ~= #GLOBALS.modifiers then
      rerun_modifiers = true
    else
      for i, mod in ipairs(GLOBALS.modifiers) do
        if win._global_modifiers[i] ~= mod then
          rerun_modifiers = true
          break
        end
      end
    end
    if rerun_modifiers == true then
      win.modifiers = {}
      win._global_modifiers = {}
      for i, mod in ipairs(GLOBALS.modifiers) do
        win._global_modifiers[i] = mod
        win.modifiers[i] = mod(win)
      end
    end

    local hi_key = ''
    for i, mod in ipairs(win.modifiers) do
      mod.before()
      hi_key = hi_key .. '#' .. mod.key(i)
    end

    if not win.ns
      or not GLOBALS.nohlcheck
      or win.hi_key ~= hi_key
      or GLOBALS.tick_state >= GLOBALS.RECALCULATE then
      local ns = NAMESPACE.get_replacement(win, real_ns, hi_key)
      if ns.modified == true then
        win.state = bit.bor(GLOBALS.CHANGED, win.state)
      end
      win.ns = ns
      win.hi_key = hi_key
    end
  end

  if bit.band(bit.bor(GLOBALS.tick_state, win.state), GLOBALS.CHANGED) > 0 then
    if win.faded then
      if M.fading_cache.tick_id ~= GLOBALS.tick_id  then
        M.fading_cache = {tick_id = GLOBALS.tick_id}
      end
      if M.fading_cache[win.ns.vimade_ns] == nil then
        HIGHLIGHTER.set_highlights(win)
        M.fading_cache[win.ns.vimade_ns] = true
      end
      COMPAT.nvim_win_set_hl_ns(win.winid, win.ns.vimade_ns)
    else
      COMPAT.nvim_win_set_hl_ns(win.winid, win.real_ns)
    end
  end

  return win
end

return M

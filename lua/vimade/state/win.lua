local M = {}
local NAMESPACE = require('vimade.state.namespace')
local LINK = require('vimade.config_helpers.link')
local BLOCKLIST = require('vimade.config_helpers.blocklist')
local HIGHLIGHTER = require('vimade.highlighter')
local COMPAT = require('vimade.util.compat')
local GLOBALS
local FADER

M.__init = function(args)
  FADER = args.FADER
  GLOBALS = args.GLOBALS
  FADER.on('tick:before', function ()
    M.fading_cache = {}
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
      faded_time = 0,
      faded = false,
      hi_key = '',
      is_active_win = nil,
      is_active_buf = nil,
      real_ns = 0,
      ns = nil,
      state = GLOBALS.READY,
      style = {},
      -- raw global styles that were used to build this win
      _global_style = {},
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
  local active_ns = COMPAT.nvim_get_hl_ns({winid = win.winid})
  local real_ns
  if NAMESPACE.is_vimade_ns(active_ns) == true then
    real_ns = win.real_ns
  else
    real_ns = active_ns == -1 and 0 or active_ns
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

  if (should_fade and not win.faded) or (not should_fade and win.faded) then
    win.faded_time = vim.loop.now()
  end

  win.state = bit.bor(win.state, _update_state({
    faded = should_fade
  }, win, GLOBALS.CHANGED))

  local rerun_style = false

  if should_fade == true then
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
        win.style[i] = s.attach(win)
      end
    end

    local hi_key = win.real_ns .. ':' 

    -- this is to separate out the logic for inactive vs active.  we can use this for highlighting
    -- the active ns in the future
    if not is_active_win then
      hi_key = 'nc:' .. hi_key
    end

    for i, s in ipairs(win.style) do
      s.before()
      hi_key = hi_key .. '#' .. s.key(i)
    end

    if not win.ns
      or not GLOBALS.nohlcheck
      or win.ns.modified
      or win.hi_key ~= hi_key
      or bit.band(GLOBALS.tick_state, GLOBALS.RECALCULATE) > 0 then
      local ns = NAMESPACE.get_replacement(win, real_ns, hi_key)
      if ns.modified == true or win.hi_key ~= hi_key then
        win.state = bit.bor(GLOBALS.CHANGED, win.state)
        ns.modified = true
      end
      win.hi_key = hi_key
      win.ns = ns
    end
  end

  -- every namespace needs to be set again, this is related to the issues where the Neovim API
  -- sets / returns incorrect values for namespace highlights.
  if win.ns and win.faded and win.ns.real.complete_highlights then
    if M.fading_cache[win.ns.vimade_ns] == nil then
      HIGHLIGHTER.set_highlights(win)
      M.fading_cache[win.ns.vimade_ns] = true
    end
    COMPAT.nvim_win_set_hl_ns(win.winid, win.ns.vimade_ns or 0)
    win.current_ns = win.ns.vimade_ns
  elseif not win.faded then
    -- TODO allow active highlights
    COMPAT.nvim_win_set_hl_ns(win.winid, win.real_ns or 0)
    win.current_ns = win.real_ns
  end

  return win
end

return M

local M = {}

local TYPE = require('vimade.util.type')
local COMPAT = require('vimade.util.compat')
local HIGHLIGHTER = require('vimade.highlighter')
local REAL_NAMESPACE = require('vimade.state.real_namespace')
local GLOBALS

M.__init = function (globals)
  GLOBALS = globals
end

M.key_lookup = {}
M.real_ns_lookup = {}
M.vimade_active_ns_lookup = {}
M.winid_lookup = {}
M.used_ns = {}
M.free_ns = {}


local ids = 0
local get_next_id = function ()
  ids = ids + 1
  return ids
end

-- will_reuse should only be set if the calling window will
-- for sure reuse the namespace
M.clear_winid = function (winid, will_self_reuse)
  local current_win_ns = M.winid_lookup[winid] 
  M.winid_lookup[winid] = nil
  if current_win_ns ~= nil then
    current_win_ns.windows[winid] = nil

    if next(current_win_ns.windows) == nil then
      M.key_lookup[current_win_ns.key] = nil
      M.vimade_active_ns_lookup[current_win_ns.vimade_ns] = nil
      table.insert(M.free_ns, current_win_ns)
    end
  end
end

M.get_replacement = function (win, real_ns, hi_key, skip_create)
  local key = hi_key

  local ns = M.key_lookup[key]
  local current_win_ns = M.winid_lookup[win.winid]

  -- see if the ns was switched, if so we need to clear the win
  if ns == nil or ( current_win_ns ~= nil and current_win_ns ~= ns) then
    M.clear_winid(win.winid, ns == nil)
    ns = M.key_lookup[key]
  end
  if ns == nil then
    if skip_create then
      return nil
    end
    ns = table.remove(M.free_ns) or {
      -- vimade_ns = vim.api.nvim_create_namespace('vimade_' .. get_next_id()),
      vimade_ns = vim.api.nvim_create_namespace(''),
      vimade_highlights = {},
    }
    ns.key = key
    ns.real_ns =real_ns
    ns.windows = {}
    ns.modified = true

    M.key_lookup[key] = ns
    M.vimade_active_ns_lookup[ns.vimade_ns] = ns
    M.used_ns[ns.vimade_ns] = true
  end

  ns.windows[win.winid] = win
  M.winid_lookup[win.winid] = ns

  -- refresh highlights and changed state --
  M.check_ns_modified(ns)
  return ns
end

M.check_ns_modified = function(ns)
  local real = REAL_NAMESPACE.refresh(ns.real_ns, false)
  ns.modified = real.modified
  ns.real = real
end

M.is_vimade_ns = function (vimade_ns)
  return M.used_ns[vimade_ns] ~= nil
end

M.from_winid = function (winid)
  local result = M.winid_lookup[winid]
  return result and result.vimade_ns
end

return M

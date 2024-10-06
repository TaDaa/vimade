local M = {}
local COLORS = require('vimade.colors')
local TYPE = require('vimade.util.type')
local COMPAT = require('vimade.util.compat')
local GLOBALS

M.__init = function (globals)
  GLOBALS = globals
end

M.key_lookup = {}
M.real_ns_lookup = {}
M.vimade_ns_lookup = {}
M.winid_lookup = {}
M.free_ns = {}

local ids = 0
local get_next_id = function ()
  ids = ids + 1
  return ids
end

M.get_replacement = function (win, real_ns, skip_create)
  local key = real_ns .. ':' .. (win.fadelevel or '') .. ':' .. COLORS.get_tint_key(win.tint) or ''
  local ns = M.key_lookup[key]
  if ns == nil then
    if skip_create then
      return nil
    end
    ns = {
      key = key,
      real_ns = real_ns,
      vimade_ns = table.remove(M.free_ns) or vim.api.nvim_create_namespace('vimade_' .. get_next_id()),
      windows = {},
    }
    M.key_lookup[key] = ns
    M.vimade_ns_lookup[ns.vimade_ns] = ns
  end

  local current_win_ns = M.winid_lookup[win.winid]
  if current_win_ns and current_win_ns ~= ns then
    M.clear_winid(win.winid)
  end

  ns.windows[win.winid] = win
  M.winid_lookup[win.winid] = ns

  -- refresh highlights and changed state --
  M.check_ns_modified(ns)

  return ns
end

M.check_ns_modified = function(ns)
  if ns.tick_id ~= GLOBALS.tick_id then
    ns.tick_id = GLOBALS.tick_id
    local highlights = COMPAT.nvim_get_hl(ns.real_ns, {})
    if TYPE.deep_compare(ns.real_highlights, highlights) == false then
      ns.modified = true
    else
      ns.modified = false
    end
    ns.real_highlights = highlights
  end
end

M.is_vimade_ns = function (vimade_ns)
  return M.vimade_ns_lookup[vimade_ns] ~= nil
end

M.from_winid = function (winid)
  local result = M.winid_lookup[winid]
  return result and result.vimade_ns
end

M.clear_winid = function (winid)
  local current_win_ns = M.winid_lookup[winid] 
  if current_win_ns ~= nil then
    current_win_ns.windows[winid] = nil
    if not next(current_win_ns.windows) then
      M.key_lookup[current_win_ns.key] = nil
      M.vimade_ns_lookup[current_win_ns.vimade_ns] = nil
      table.insert(M.free_ns, current_win_ns.vimade_ns)
    end
  end
end

return M

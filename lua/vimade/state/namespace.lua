local M = {}

local TYPE = require('vimade.util.type')
local COMPAT = require('vimade.util.compat')
local REAL_NAMESPACE = require('vimade.state.real_namespace')

local TABLE_INSERT = table.insert
local TABLE_REMOVE = table.remove

-- we want a high enough number for good probability of collisions
-- during an animation. 200 should provide more than enough for basic
-- configurations. The animation itself needs to round time to nearest
-- good value (~16ms) to ensure the cache hit-rate is high enough.
---
-- The worst case here are long duration animations and animations that
-- are impossible to be deterministic. The ripple recipe is a presents
-- this issue well, where the re-use rate is implicitly limited due to
-- how the calculation scales infinitely based on distance. TODO we should
-- ensure that ripple is bucketed.
--
-- Why 200?:
--   - 36 per default settings for Default, Minimalist, and Paradox recipes.
--   - 109 per default settings for Duo (36 in/out start/window, 36 in/out start/buffer, 36 in/out window/buffer)
--   - Marks and focus will add another potential 72 to the above (TODO update this accordingly when ready)
local PENDING_LIMIT = 200

local key_lookup = {}
local winid_lookup = {}
local used_ns = {}
local free_ns = {}
local pending_free_ns = {}
local pending_free_ns_length = 0


local ids = 0
local get_next_id = function ()
  ids = ids + 1
  return ids
end

-- will_reuse should only be set if the calling window will
-- for sure reuse the namespace
M.clear_winid = function (winid, will_self_reuse)
  local current_win_ns = winid_lookup[winid] 
  winid_lookup[winid] = nil
  if current_win_ns ~= nil then
    current_win_ns.windows[winid] = nil
    if next(current_win_ns.windows) == nil then
      TABLE_INSERT(pending_free_ns, current_win_ns)
      key_lookup[current_win_ns.key] = nil
      pending_free_ns_length = pending_free_ns_length + 1
      if pending_free_ns_length > PENDING_LIMIT then
        TABLE_INSERT(free_ns, TABLE_REMOVE(pending_free_ns, 1))
        pending_free_ns_length = PENDING_LIMIT
      end
    end
  end
end

-- This discards and uncaches all namespaces managed by vimade. This is useful
-- when the namespace reaches an unrecoverable state (e.g. switching between some
-- colorschemes may break the namespace link state).
M.discard_all = function()
  for winid, state in pairs(winid_lookup) do
    M.clear_winid(winid)
  end
  free_ns = {}
  pending_free_ns_length = 0
  pending_free_ns = {}
end

M.get_replacement = function (win, real_ns, hi_key, skip_create)
  local key = hi_key

  local ns = key_lookup[key]
  local current_win_ns = winid_lookup[win.winid]

  -- see if the ns was switched, if so we need to clear the win
  if ns == nil or (current_win_ns ~= nil and current_win_ns ~= ns) then
    M.clear_winid(win.winid, ns == nil)
    ns = key_lookup[key]
    if not ns then
      -- also check the pending_free_ns
      for i, pending_ns in ipairs(pending_free_ns) do
        if pending_ns.key == key then
          ns = pending_ns
          TABLE_REMOVE(pending_free_ns, i)
          ns.dupe = true
          pending_free_ns_length = pending_free_ns_length - 1
          key_lookup[pending_ns.key] = pending_ns
          break
        end
      end
    end
  end
  if ns == nil then
    if skip_create then
      return nil
    end
    ns = TABLE_REMOVE(free_ns) or {
      -- vimade_ns = vim.api.nvim_create_namespace('vimade_' .. get_next_id()),
      vimade_ns = vim.api.nvim_create_namespace(''),
      vimade_highlights = {},
    }
    ns.key = key
    ns.real_ns =real_ns
    ns.windows = {}
    ns.modified = true
    ns.created = true

    key_lookup[key] = ns
    used_ns[ns.vimade_ns] = true
  end

  ns.windows[win.winid] = win
  winid_lookup[win.winid] = ns

  -- refresh highlights and changed state --
  M.check_ns_modified(ns)
  return ns
end

M.check_ns_modified = function(ns)
  local real = REAL_NAMESPACE.refresh(ns.real_ns, false)
  if ns.created or real.modified or real.sync_id ~= ns.sync_id then
    ns.modified = true
    ns.created = false
    ns.sync_id = real.sync_id
  else
    -- if ns.dupe then
    --   print('skipped due to dupe', pending_free_ns_length)
    -- end
    ns.modified = false
  end
  ns.dupe = nil
  ns.real = real
end

M.is_vimade_ns = function (vimade_ns)
  return used_ns[vimade_ns] ~= nil
end

M.from_winid = function (winid)
  local result = winid_lookup[winid]
  return result and result.vimade_ns
end

return M

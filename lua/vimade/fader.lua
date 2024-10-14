local M = {}
local NAMESPACE = require('vimade.state.namespace')
local GLOBALS = require('vimade.state.globals')
local ANIMATOR = require('vimade.animator')
local HIGHLIGHTER = require('vimade.highlighter')
local WIN_STATE = require('vimade.state.win')
local COMPAT = require('vimade.util.compat')

-- internal only
local update = function (only_these_windows)
  local windows = vim.fn.getwininfo()
  local fade_windows = GLOBALS.fademode == 'windows'
  local fade_buffers = not fade_windows
  local current = GLOBALS.current
  local updated_cache = {}

  for i, wininfo in pairs(windows) do
    -- we skip only_these_windows here because we need to know who the active window is
    -- for linking and other ops
    if current.winid == wininfo.winid then
      -- current needs to be processed head-of-time see win_state.lua
      -- this is necessary to determine linked behavior
      WIN_STATE.refresh_active(wininfo)
      break
    end
  end

  for i, wininfo in pairs(windows) do
    if current.tabnr == wininfo.tabnr and current.winid ~= wininfo.winid
      and (not only_these_windows or only_these_windows[wininfo.winid]) then
      WIN_STATE.refresh(wininfo)
    end
  end
  WIN_STATE.cleanup(windows)
end

-- external --
M.setup = function (config)
  return GLOBALS.setup(config)
end

M.getInfo = function ()
  return GLOBALS.getInfo()
end

M.recalculate = function ()
  local windows = vim.fn.getwininfo()
  local current = GLOBALS.current
  local updated_cache = {}

  -- TODO likely deprecate this, just pipe via HLCHECK or rename HLCHECK
  -- to RECALCULATE
  GLOBALS.refresh_global_ns()
  for i, wininfo in pairs(windows) do
    local win = WIN_STATE.get(wininfo)
    if win ~= nil and win.ns ~= nil and win.ns.vimade_ns ~= nil then
      if updated_cache[win.ns.vimade_ns] == nil then
        HIGHLIGHTER.set_highlights(win)
        updated_cache[win.ns.vimade_ns] = true
      end
      if win.faded == true then
        vim.api.nvim_win_set_hl_ns(win.winid, win.ns.vimade_ns)
      end
    end
  end
end

M.redraw = function()
  M.tick(GLOBALS.HLCHECK)
end

M.animate = function ()
  local only_these_windows = ANIMATOR.refresh()
  M.tick(nil, only_these_windows)
end

M.tick = function (override_tick_state, only_these_windows)
  GLOBALS.refresh(override_tick_state)
  local last_ei = vim.go.ei

  if bit.band(GLOBALS.RECALCULATE, GLOBALS.tick_state) > 0 then
    M.recalculate()
  end

  -- if the tick_state changed during an animation, we need to use that frame
  -- to sync the windows
  if GLOBALS.tick_state > 0 and only_these_windows then
    only_these_windows = nil
  end

  update(only_these_windows)

  vim.go.ei = last_ei
end

M.unfadeAll = function ()
  local windows = vim.api.nvim_list_wins()
  local current = GLOBALS.current

  for i, winid in pairs(windows) do
    local ns = COMPAT.nvim_get_hl_ns({winid = winid})
    if NAMESPACE.is_vimade_ns(ns) == true then
        local real_ns = vim.api._vimade_real_ns or 0
        vim.api.nvim_win_set_hl_ns(winid, real_ns)
        WIN_STATE.unfade(winid)
    end
  end
end

return M

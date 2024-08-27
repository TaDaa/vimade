local M = {}
local NAMESPACE = require('vimade.state.namespace')
local GLOBALS = require('vimade.state.globals')
local HIGHLIGHTER = require('vimade.highlighter')
local WIN_STATE = require('vimade.state.win')
--
-- internal only / do not expose --
local fade = function (win, updated_cache)
  if updated_cache[win.ns.vimade_ns] == nil then
    HIGHLIGHTER.set_highlights(win)
    updated_cache[win.ns.vimade_ns] = true
  end

  vim.api.nvim_win_set_hl_ns(win.winid, win.ns.vimade_ns)
end

local unfade = function (win)
  vim.api.nvim_win_set_hl_ns(win.winid, win.real_ns)
end

local update = function (global_update)
  local windows = vim.fn.getwininfo()
  local fade_windows = GLOBALS.fademode == 'windows'
  local fade_buffers = not fade_windows
  local current = GLOBALS.current
  local updated_cache = {}

  for i, wininfo in pairs(windows) do
    if current.winid == wininfo.winid then
      -- current needs to be processed head-of-time see win_state.lua
      -- this is necessary to determine linked behavior
      local win = WIN_STATE.from_current(wininfo)
      if global_update > 0 or bit.band(WIN_STATE.CHANGED, win.modified) > 0 then
        if win.faded then
          fade(win, updated_cache)
        else
          unfade(win)
        end
      end
      break
    end
  end

  for i, wininfo in pairs(windows) do
    if current.tabnr == wininfo.tabnr and current.winid ~= wininfo.winid then
      local win = WIN_STATE.from_other(wininfo)
      if global_update > 0 or bit.band(WIN_STATE.CHANGED, win.modified) > 0 then
        if win.faded then
          fade(win, updated_cache)
        else
          unfade(win)
        end
      end
    end
  end
  WIN_STATE.cleanup(windows)
end

-- external --

M.recalculate = function ()
  local windows = vim.fn.getwininfo()
  local current = GLOBALS.current
  local updated_cache = {}

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


M.tick = function ()
  GLOBALS.refresh()
  local last_ei = vim.go.ei

  if bit.band(GLOBALS.RECALCULATE, GLOBALS.tick_state) > 0 then
    M.recalculate()
  end

  update(bit.band(GLOBALS.UPDATE, GLOBALS.tick_state), win_config)


  vim.go.ei = last_ei
end

M.unfadeAll = function ()
  local windows = vim.api.nvim_list_wins()
  local current = GLOBALS.current

  for i, winid in pairs(windows) do
    local ns = vim.api.nvim_get_hl_ns({winid = winid})
    if NAMESPACE.is_vimade_ns(ns) == true then
        local real_ns = vim.api._vimade_real_ns or 0
        vim.api.nvim_win_set_hl_ns(winid, real_ns)
        WIN_STATE.unfade(winid)
    end
  end
end

return M

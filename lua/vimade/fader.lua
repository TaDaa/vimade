local M = {}
local ANIMATOR = require('vimade.animator')
local COMPAT = require('vimade.util.compat')
local EXCLUDE = require('vimade.style.exclude')
local FADE = require('vimade.style.fade')
local GLOBALS = require('vimade.state.globals')
local HIGHLIGHTER = require('vimade.highlighter')
local INCLUDE = require('vimade.style.include')
local NAMESPACE = require('vimade.state.namespace')
local REAL_NAMESPACE = require('vimade.state.real_namespace')
local TINT = require('vimade.style.tint')
local WIN_STATE = require('vimade.state.win')

-- internal only
local update = function ()
  local windows = vim.fn.getwininfo()
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
    if current.tabnr == wininfo.tabnr and current.winid ~= wininfo.winid then
      WIN_STATE.refresh(wininfo)
    end
  end
  for i, wininfo in pairs(windows) do
    if current.tabnr == wininfo.tabnr then
      local win = WIN_STATE.get(wininfo)
      if win.current_ns ~= nil then
        COMPAT.nvim_win_set_hl_ns(wininfo.winid, win.current_ns)
      end
    end
  end
  WIN_STATE.cleanup(windows)
end

M.callbacks = {}
M.on = function (name, callback)
  if not M.callbacks[name] then
    M.callbacks[name] = {}
  end
  table.insert(M.callbacks[name], callback)
end

M.notify = function (name)
  local callbacks = M.callbacks[name]
  if callbacks then
    for k, callback in ipairs(callbacks) do
      callback()
    end
  end
end

-- external --
M.setup = function (config)
  return GLOBALS.setup(config)
end

M.getInfo = function ()
  return GLOBALS.getInfo()
end

M.redraw = function()
  M.tick(bit.bor(GLOBALS.RECALCULATE, GLOBALS.CHANGED))
end

M.animate = function ()
  -- animations are monitored via events, no special handling required here
  M.tick()
end

M.tick = function (override_tick_state)
  local last_ei = vim.go.ei
  vim.go.ei ='all'
  M.notify('tick:before')
  GLOBALS.refresh(override_tick_state)

  update()

  M.notify('tick:after')
  vim.go.ei = last_ei
end

M.unhighlightAll = function ()
  local windows = vim.api.nvim_list_wins()
  local current = GLOBALS.current

  for i, winid in pairs(windows) do
    local ns = COMPAT.nvim_get_hl_ns({winid = winid})
    if NAMESPACE.is_vimade_ns(ns) == true then
        local real_ns = vim.w[winid]._vimade_real_ns or 0
        vim.api.nvim_win_set_hl_ns(winid, real_ns)
        WIN_STATE.unhighlight(winid)
    end
  end
end

ANIMATOR.__init({FADER=M, GLOBALS=GLOBALS})
HIGHLIGHTER.__init({FADER=M, GLOBALS=GLOBALS})
REAL_NAMESPACE.__init({FADER=M, GLOBALS=GLOBALS})
FADE.__init({FADER=M, GLOBALS=GLOBALS})
TINT.__init({FADER=M, GLOBALS=GLOBALS})
EXCLUDE.__init({FADER=M, GLOBALS=GLOBALS})
INCLUDE.__init({FADER=M, GLOBALS=GLOBALS})
WIN_STATE.__init({FADER=M, GLOBALS=GLOBALS})

return M

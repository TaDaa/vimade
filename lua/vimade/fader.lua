local M = {}
local bit = require('bit')

local ANIMATE = require('vimade.style.value.animate')
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

  local style = GLOBALS.style
  for i, s in ipairs(style) do
    if s.tick then
      s.tick()
    end
  end

  for i, wininfo in ipairs(windows) do
    -- we skip only_these_windows here because we need to know who the active window is
    -- for linking and other ops
    if current.winid == wininfo.winid then
      -- current needs to be processed head-of-time see win_state.lua
      -- this is necessary to determine linked behavior
      WIN_STATE.refresh_active(wininfo)
      break
    end
  end

  for i, wininfo in ipairs(windows) do
    if current.tabnr == wininfo.tabnr and current.winid ~= wininfo.winid then
      WIN_STATE.refresh(wininfo)
    end
  end

  -- Neovim will sometimes corrupt namespaces. This happens frequently in 0.8.0 and much less
  -- on newer versions.  Corrupted namespaces results in flickers, lost highlights, or completely
  -- incorrect colors.  We can detect it by ensuring the first highlight in a namespace (vimade_control)
  -- always has our expected color values. When the values are wrong, we need to reset every color
  -- in that namespace and force redraw.
  local corrupted_namespaces = {}
  for i, wininfo in ipairs(windows) do
    if current.tabnr == wininfo.tabnr then
      local win = WIN_STATE.get(wininfo)
      -- check if the namespace is owned by vimade and whether its currently active
      -- ensures that the 
      if win.ns and win.current_ns and win.current_ns == win.ns.vimade_ns then
        local result = COMPAT.nvim_get_hl(win.ns.vimade_ns, {name = 'vimade_control'})
        if result.fg ~= 0XFEDCBA or result.bg ~= 0X123456 then
          if not corrupted_namespaces[win.ns.vimade_ns] then
            corrupted_namespaces[win.ns.vimade_ns] = true
            HIGHLIGHTER.set_highlights(win)
          end
          COMPAT.nvim__redraw({win=win.winid, valid=false})
        end
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
  M.notify('tick:refresh')

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

ANIMATE.__init({FADER=M, GLOBALS=GLOBALS})
ANIMATOR.__init({FADER=M, GLOBALS=GLOBALS})
COMPAT.__init({FADER=M, GLOBALS=GLOBALS})
HIGHLIGHTER.__init({FADER=M, GLOBALS=GLOBALS})
REAL_NAMESPACE.__init({FADER=M, GLOBALS=GLOBALS})
FADE.__init({FADER=M, GLOBALS=GLOBALS})
TINT.__init({FADER=M, GLOBALS=GLOBALS})
EXCLUDE.__init({FADER=M, GLOBALS=GLOBALS})
INCLUDE.__init({FADER=M, GLOBALS=GLOBALS})
WIN_STATE.__init({FADER=M, GLOBALS=GLOBALS})

return M

local M = {}
local bit = require('bit')
local BIT_BAND = bit.band
local BIT_BOR = bit.bor

local ANIMATE = require('vimade.style.value.animate')
local ANIMATOR = require('vimade.animator')
local COMPAT = require('vimade.util.compat')
local FADE = require('vimade.style.fade')
local CONDITION = require('vimade.style.value.condition')
local DEFAULT = require('vimade.recipe.default')
local GLOBALS = require('vimade.state.globals')
local HIGHLIGHTER = require('vimade.highlighters.namespace')
local FOCUS = require('vimade.focus')
local NAMESPACE = require('vimade.state.namespace')
local REAL_NAMESPACE = require('vimade.state.real_namespace')
local TINT = require('vimade.style.tint')
local WIN_STATE = require('vimade.state.win')

local TABLE_INSERT = table.insert

local events = require('vimade.util.events')()

M.on = events.on

-- internal only
local update = function ()
  local windows = vim.api.nvim_tabpage_list_wins(0)
  local current = GLOBALS.current
  local updated_cache = {}

  areas = FOCUS.update({
    winid = GLOBALS.current.winid,
    tabnr = GLOBALS.current.tabnr,
    prevent_events = false,
  })

  local style = GLOBALS.style
  for i, s in ipairs(style) do
    if s.tick then
      s.tick()
    end
  end

  if BIT_BAND(GLOBALS.tick_state, GLOBALS.DISCARD_NS) > 0 then
    NAMESPACE.discard_all()
  end
  if current.winid ~= -1 then
    WIN_STATE.refresh_active(current.winid)
  end
  for i, winid in ipairs(windows) do
    -- Refresh the non-area windows first. We need to know the state of the area_owner
    -- before processing areas.
    if current.winid ~= winid and not FOCUS.get(winid) then
      WIN_STATE.refresh(winid)
    end
  end

  -- Now check the areas.
  for winid, _ in pairs(areas) do
    WIN_STATE.refresh(winid)
    TABLE_INSERT(windows, winid)
  end

  -- Neovim will sometimes corrupt namespaces. This happens frequently in 0.8.0 and much less
  -- on newer versions.  Corrupted namespaces results in flickers, lost highlights, or completely
  -- incorrect colors.  We can detect it by ensuring the first highlight in a namespace (vimade_control)
  -- always has our expected color values. When the values are wrong, we need to reset every color
  -- in that namespace and force redraw.
  local corrupted_namespaces = {}
  for i, winid in ipairs(windows) do
    local win = WIN_STATE.get(winid)
    -- check if the namespace is owned by vimade and whether its currently active
    -- ensures that the 
    if win and win.ns and win.current_ns and win.current_ns == win.ns.vimade_ns then
      local result = COMPAT.nvim_get_hl(win.ns.vimade_ns, {name = 'vimade_control'})
      if result.fg ~= 0XFEDCBA or result.bg ~= 0X123456 then
        if not corrupted_namespaces[win.ns.vimade_ns] then
          corrupted_namespaces[win.ns.vimade_ns] = true
          HIGHLIGHTER.set_highlights(win)
        end
        COMPAT.nvim__redraw({win=winid, valid=false})
      end
    end
  end

  if BIT_BAND(GLOBALS.tick_state, GLOBALS.CHANGED) > 0 then
    local active_winids ={}
    local winids = vim.api.nvim_list_wins()
    for key, winid in pairs(winids) do
      active_winids[winid] = true
    end
    WIN_STATE.cleanup(active_winids)
    FOCUS.cleanup(active_winids)
  end
end

-- external --
M.setup = function (config)
  GLOBALS.setup(config)
  FOCUS.setup(config.focus or {})
end

M.getInfo = function ()
  return GLOBALS.getInfo()
end

M.redraw = function()
  M.tick(BIT_BOR(GLOBALS.RECALCULATE, GLOBALS.DISCARD_NS, GLOBALS.CHANGED))
end

M.animate = function ()
  -- animations are monitored via events, no special handling required here
  M.tick()
end

M.tick = function (override_tick_state)
  if vim.g.vimade_running == 0 then
    return
  end
  local last_ei = vim.go.ei
  vim.go.ei ='all'

  events.notify('tick:before')
  GLOBALS.refresh(override_tick_state)
  events.notify('tick:refresh')

  update()

  events.notify('tick:after')
  vim.go.ei = last_ei
end

M.disable = function()
  M.unhighlightAll()
  FOCUS.disable()
end

M.unhighlightAll = function ()
  local windows = vim.api.nvim_list_wins()
  local current = GLOBALS.current

  for i, winid in pairs(windows) do
    local ns = COMPAT.nvim_get_hl_ns({winid = winid})
    if NAMESPACE.is_vimade_ns(ns) == true then
      local win = WIN_STATE.get(winid)
      if win then
        WIN_STATE.unhighlight(win)
      end
    end
  end
end

FOCUS.on('focus:on', M.tick)
FOCUS.on('focus:off', M.tick)
FOCUS.on('focus:mark', M.tick)

ANIMATE.__init({FADER=M, GLOBALS=GLOBALS})
ANIMATOR.__init({FADER=M, GLOBALS=GLOBALS})
COMPAT.__init({FADER=M, GLOBALS=GLOBALS})
CONDITION.__init({FADER=M, GLOBALS=GLOBALS})
DEFAULT.__init({FADER=M, GLOBALS=GLOBALS})
FADE.__init({FADER=M, GLOBALS=GLOBALS})
FOCUS.__init({FADER=M, GLOBALS=GLOBALS})
HIGHLIGHTER.__init({FADER=M, GLOBALS=GLOBALS})
REAL_NAMESPACE.__init({FADER=M, GLOBALS=GLOBALS})
TINT.__init({FADER=M, GLOBALS=GLOBALS})
WIN_STATE.__init({FADER=M, GLOBALS=GLOBALS})

return M

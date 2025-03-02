local M = {}

local COLOR_UTIL = require('vimade.util.color')
local COMPAT = require('vimade.util.compat')
local TYPE = require('vimade.util.type')
local GLOBALS

local bit = require('bit')
local BIT_BAND = bit.band
local TABLE_INSERT = table.insert
local NVIM_SET_HL = vim.api.nvim_set_hl
-- contains pattern matches per tick cycle. This works because highlights aren't going to
-- change mid-tick, therefore we know our matches are good for the entire cycle, allowing us
-- to only need to find matching names one time (and then re-use those names later).
local pattern_cache = {}

-- ns_cache ensures we only perform set_highlight computation once per namespace per tick.
local ns_cache = {}

M.__init = function(args)
  GLOBALS = args.GLOBALS
  args.FADER.on('tick:before', function()
    pattern_cache = {}
    ns_cache = {}
  end)
end

M.set_highlights = function(win)
  local copy_ns
  if GLOBALS.termguicolors then
    copy_ns = TYPE.copy_hl_ns_gui
  else
    copy_ns = TYPE.copy_hl_ns_cterm
  end
  local default_fg = GLOBALS.is_dark and 0xFFFFFF or 0x000000
  local default_bg = GLOBALS.is_dark and 0x000000 or 0xFFFFFF
  local default_sp = default_fg
  local default_ctermfg = GLOBALS.is_dark and 231 or 0
  local default_ctermbg = GLOBALS.is_dark and 0 or 231
  local basebg = win.basebg or nil
  local highlights = copy_ns(win.ns.real.complete_highlights)
  local normal_nc = highlights.NormalNC or {}
  local normal = highlights.Normal or {}
  local blocked_highlights = win.blocked_highlights
  local vimade_highlights = win.ns.vimade_highlights
  local ns = win.ns
  local vimade_ns = win.ns.vimade_ns

  if GLOBALS.termguicolors then
    default_ctermfg = nil
    default_ctermbg = nil
  else
    default_fg = nil
    default_bg = nil
    default_sp = nil
  end
  
  -- remember normal and normal_nc may also be linked, however their
  -- color properties have already been inherited in real_namespace.lua
  -- and will reflect the real values.
  if not win.is_active_win then
    if normal_nc.ctermbg ~= nil then
      normal.ctermbg = normal_nc.ctermbg
    end
    if normal_nc.ctermfg ~= nil then
      normal.ctermfg = normal_nc.ctermfg
    end
    if normal_nc.bg ~= nil then
      normal.bg = normal_nc.bg
    end
    if normal_nc.fg ~= nil then
      normal.fg = normal_nc.fg
    end
    if normal_nc.sp ~= nil then
      normal.sp = normal_nc.sp
    end
    -- maybe
    if vim.go.laststatus == 3 then
      highlights.StatusLine = nil
    end
  end

  local normal_bg = normal.bg or default_bg
  local normal_fg = normal.fg or default_fg
  local normal_sp = normal.sp or normal.fg or default_sp
  local normal_ctermfg = normal.ctermfg or default_ctermfg
  local normal_ctermbg = normal.ctermbg or default_ctermbg

  local normal_target = {
    name = '',
    fg = normal_fg,
    bg = basebg or normal_bg,
    sp = normal_sp,
    ctermfg = normal_ctermfg,
    ctermbg = basebg and COLOR_UTIL.toRgb(basebg) or normal_ctermbg,
    normal_bg = normal.bg
  }

  local style = win.style
  local link_cache = {}

  -- default normal properties
  -- ensure that bg is unset for transparent backgrounds (cterm/guibg=NONE)
  normal.name = 'Normal'
  if normal.fg == nil then
    normal.fg = normal_fg
  end
  if normal.ctermfg == nil then
    normal.ctermfg = normal_ctermfg
  end
  -- highlights are pre-copied
  -- NormalNC should just Normal highlights since Vimade understands what values
  -- should be used for inactive windows or buffers.
  highlights.NormalNC = TYPE.copy_hl(normal)

  -- store the used target for debugging purposes only
  ns.normal_target = normal_target

  -- Resist caching the code below, the Neovim API is extremely buggy and changing minor things
  -- here will probably break how the API responds with color values.  This is an infrequent bug.
  -- The trick to make the code all work together is to ALWAYS CALL `nvim_set_hl`. Every so often
  -- Neovim will store an incorrect value, this has nothing to do with this plugin, the values simply
  -- don't match and contain properties that may have never been set.  We have to always overwrite
  -- the highlights to make things work.  The only consistency in the API is when using linked
  -- highights.  Everything ese is a crapshoot.
  -- To test:
  -- set let g:vimade.fademode='windows'
  -- Use Neotree or any plugin that creates a circular highlight between the namespace and global.
  -- Quickly switch between windows with Vimade enabled.  Eventually you will see a window with
  -- colors that make no sense, or completely underlined.  When this happens it means either the
  -- API set the wrong values or the API read the wrong values as they never match the values we cache.
  -- This only happens when you skip calls to nvim_set_hl and nvim_win_set_hl.
  --
  -- tldr; don't cache the changes you need to do except for links.

  -- vimade_control is used to ensure that the namespace hasn't become corrupted. Neovim seems to have a bug
  -- that occurs every so often that either causes a user visible flicker or completely incorrect colors.
  -- When this happens the first set highlights seem to be most effected, therefore we set vimade_control FIRST.
  -- then check it again after all the highlights have been set for all windows.  This re-check process currently
  -- happens in fader.lua
  NVIM_SET_HL(vimade_ns, 'vimade_control', {bg=0x123456, fg=0xFEDCBA})

  -- Pre-check blocked highlights by exact match.
  local blocked = {}
  for _, name in ipairs(blocked_highlights.exact) do
    blocked[name] = highlights[name]
    highlights[name] = nil
  end
  -- Pre-check blocked highlights by pattern. We cache the lookup each tick
  -- so that we don't suffer performance degredation with multiple windows
  for _, pattern in ipairs(blocked_highlights.pattern) do
    local cached = pattern_cache[pattern]
    if not cached then
      cached = {}
      pattern_cache[pattern] = cached
      for name, hi in pairs(highlights) do
        if name:find(pattern) then
          TABLE_INSERT(cached, name)
        end
      end
    end
    for k, name in ipairs(cached) do
      blocked[name] = highlights[name]
      highlights[name] = nil
    end
  end
  --
  -- precheck highlights for ones that are no longer found. If not found, clear the highlight
  -- in our namespace.  Ensures compatibility with highlights that are unset after calculation.
  vimade_highlights.vimade_0 = nil
  for name, highlight in pairs(vimade_highlights) do
    if highlights[name] == nil and blocked[name] == nil then
      -- despite the neovim docs, using an empty {} here actually clears the highlight and does
      -- not inherit color information from the global namespace.  Instead we hack the behavior
      -- by linking the namespace to its global value.
      NVIM_SET_HL(vimade_ns, name, {link = name})
      vimade_highlights[name] = nil
    end
  end

  -- See #89 - This sets blocked highlights to the color that they should have been. This prevents
  -- blocked highlights from linking to a color that would have been manipulated.
  for name, hi in pairs(blocked) do
    hi.link = nil
    hi.name = nil
    vimade_highlights[name] = hi
    NVIM_SET_HL(vimade_ns, name, hi)
  end

  highlights.vimade_0 = nil
  highlights.vimade_control = nil

  local nt_copy = {
    name = '',
    fg = normal_target.fg,
    bg = normal_target.bg,
    sp = normal_target.sp,
    ctermfg = normal_target.ctermfg,
    ctermbg = normal_target.ctermbg,
    normal_bg = normal_target.normal_bg,
  }

  nt_copy.name = normal_target.name
  -- See #92. Highlights that link to blocked highlights likely should not be blocked.
  -- Additionally, highlights that link directly to Normal and NormalNC
  -- must be unlinked.
  blocked.Normal = true
  blocked.NormalNC = true
  for name, hi in pairs(highlights) do
    if blocked[hi.link] then
      hi.link = nil
    end
  end
  for _, s in ipairs(style) do
    s.modify(highlights, nt_copy)
  end

  for name, hi in pairs(highlights) do
    -- copies area required here as user mutations are expected. Deep copy due to cterm
    -- resuse the existing copy here for performance reasons and manually reassign
    -- all fields
    hi.name = nil
    NVIM_SET_HL(vimade_ns, name, hi)
    vimade_highlights[name] = hi
  end
  if vimade_highlights.Normal then
    NVIM_SET_HL(vimade_ns, 'vimade_0', vimade_highlights.Normal)
    vimade_highlights.vimade_0 = vimade_highlights.Normal
  end
end

M.highlight = function(win, redraw)
  if redraw then
    if ns_cache[win.ns.vimade_ns] == nil then
      ns_cache[win.ns.vimade_ns] = true
      M.set_highlights(win)
    end
    win.current_ns = win.ns.vimade_ns
    COMPAT.nvim_win_set_hl_ns(win.winid, win.current_ns)
  elseif BIT_BAND(GLOBALS.CHANGED, win.state) > 0 then
    win.current_ns = win.ns.vimade_ns
    COMPAT.nvim_win_set_hl_ns(win.winid, win.current_ns)
  end
end

M.unhighlight = function(win)
  if win.current_ns ~= win.real_ns then
    if win.winhl then
      win.current_ns = win.real_ns
      -- Related to #92 - use the global namespace when a winhl existed
      -- this seems to automatically put winhl back in place, although seems
      -- counterintuitive.
      COMPAT.nvim_win_set_hl_ns(win.winid, 0)
      -- TODO: For some reason resetting winhl breaks snacks.dashboard:
      -- Adding the following line causes winhl to persist after the buffer changes
      -- so don't use for now.
      -- vim.wo[win.winid].winhl = win.winhl
    elseif win.real_ns then
      win.current_ns = win.real_ns
      COMPAT.nvim_win_set_hl_ns(win.winid, win.current_ns)
    end
  end
end

return M

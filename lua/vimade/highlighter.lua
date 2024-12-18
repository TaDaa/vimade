local M = {}
local COLOR_UTIL = require('vimade.util.color')
local TYPE = require('vimade.util.type')
local GLOBALS

local nvim_set_hl = vim.api.nvim_set_hl

M.__init = function (args)
  GLOBALS = args.GLOBALS
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
  
  -- we have to unlink Normal and NormalNC highlights from any shenanigans that plugins are doing
  -- things should still fade as expected.
  normal.link = nil
  if normal_nc.link then
    normal_nc.link = nil
  end

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

  local nt_copy = {
    name = '',
    fg = normal_target.fg,
    bg = normal_target.bg,
    sp = normal_target.sp,
    ctermfg = normal_target.ctermfg,
    ctermbg = normal_target.ctermbg,
    normal_bg = normal_target.normal_bg,
  }
  for i, s in ipairs(style) do
    s.modify(normal, nt_copy)
  end

  -- clear name
  normal.name = nil
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
  nvim_set_hl(vimade_ns, 'vimade_control', {bg=0x123456, fg=0xFEDCBA})

  nvim_set_hl(vimade_ns, 'vimade_0', normal)
  vimade_highlights.vimade_0 = normal

  -- precheck highlights for ones that are no longer found. If not found, clear the highlight
  -- in our namespace.  Ensures compatibility with highlights that are unset after calculation.
  for name, highlight in pairs(vimade_highlights) do
    if name == 'NormalNC' or name =='Normal' or name == 'vimade_0' then
      --pass
    elseif highlights[name] == nil then
      -- despite the neovim docs, using an empty {} here actually clears the highlight and does
      -- not inherit color information from the global namespace.  Instead we hack the behavior
      -- by linking the namespace to its global value.
      nvim_set_hl(vimade_ns, name, {link = name})
      vimade_highlights[name] = nil
    end
  end

  -- highlights are pre-copied
  -- remove Normal/NormalNC since this a precopy anyways
  highlights.Normal = nil
  highlights.NormalNC = nil
  highlights.vimade_0 = nil
  highlights.vimade_control = nil

  -- TODO allow functions for blocked_highlights, should be fine to support this now

  -- anything blocked can be set to link to itself
  for name, v in pairs(blocked_highlights) do
    if v == true then
      highlights[name] = nil
      -- despite the neovim docs, using an empty {} here actually clears the highlight and does
      -- not inherit color information from the global namespace.  Instead we hack the behavior
      -- by linking the namespace to its global value.
      nvim_set_hl(vimade_ns, name, {link = name})
    end
  end

  for name, hi in pairs(highlights) do
    -- copies area required here as user mutations are expected. Deep copy due to cterm
    -- resuse the existing copy here for performance reasons and manually reassign
    -- all fields
    nt_copy.name = normal_target.name
    nt_copy.fg = normal_target.fg
    nt_copy.bg = normal_target.bg
    nt_copy.sp = normal_target.sp
    nt_copy.ctermfg = normal_target.ctermfg
    nt_copy.ctermbg = normal_target.ctermbg
    nt_copy.normal_bg = normal_target.normal_bg

    hi.name = name

    --TODO(see https://github.com/TaDaa/vimade/issues/81)
    --Don't enable this again below (it shouldn't be needed any more anyways)
    -- set default fg highlights if they are unset
    --if hi.fg == nil then
    --end
    --if hi.ctermfg == nil then
    --end

    for _, s in ipairs(style) do
      s.modify(hi, nt_copy)
    end

    hi.name = nil

    nvim_set_hl(vimade_ns, name, hi)
    vimade_highlights[name] = hi
  end
  nvim_set_hl(vimade_ns, 'NormalNC',  normal)
  nvim_set_hl(vimade_ns, 'Normal', normal)
end

return M

local M = {}
local COLOR_UTIL = require('vimade.util.color')
local TYPE = require('vimade.util.type')

local GLOBALS

M.__init = function (args)
  GLOBALS = args.GLOBALS
end

local REQUIRED_HI_KEYS = {
  'fg',
  'bg',
  'sp',
  'blend',
  'ctermfg',
  'ctermbg',
}
local SECONDARY_HI_KEYS = {
  'bold',
  'standout',
  'underline',
  'undercurl',
  'underdouble',
  'underdotted',
  'underdashed',
  'strikethrough',
  'italic',
  'reverse',
  'nocombine',
}

local get_replacement_parts = function (target_hi, keys, delimiter, output)
  local replacement_key = ''
  for i, key in ipairs(keys) do
    local c = target_hi[key]
    output[key] = target_hi[key]
    if c ~= nil then
      if type(c) == 'boolean' then
        c = c and 'y' or 'n'
      end
      replacement_key = replacement_key .. delimiter .. i .. delimiter .. c
    end
  end
  return replacement_key
end

local get_replacement_key = function (target_hi, ns)
  local output = {}
  local replacement_key = get_replacement_parts(target_hi, REQUIRED_HI_KEYS, ':', output)
  if replacement_key ~= '' then
    replacement_key = replacement_key.. get_replacement_parts(target_hi, SECONDARY_HI_KEYS, '#', output)
    if target_hi.cterm then
      replacement_key = replacement_key .. get_replacement_parts(target_hi.cterm, SECONDARY_HI_KEYS, '!', output)
    end
    return replacement_key
  end
  return nil
end

-- todo this should be and/or group of windows, we are only running this potentially once per window
M.set_highlights = function(win)
  local default_fg = GLOBALS.is_dark and 0xFFFFFF or 0x000000
  local default_bg = GLOBALS.is_dark and 0x000000 or 0xFFFFFF
  local default_sp = default_fg
  local default_ctermfg = GLOBALS.is_dark and 231 or 0
  local default_ctermbg = GLOBALS.is_dark and 0 or 231
  local basebg = win.basebg or nil
  local highlights = win.ns.real.complete_highlights
  local normal_nc = TYPE.deep_copy(highlights.NormalNC or {})
  local normal = TYPE.deep_copy(highlights.Normal or {})

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
  -- perf
  --local cnt_linked = 0
  --local cnt_new_links = 0
  --local total_cnt = 0
  --local skipped = 0
  --local existing = 0
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
  -- run normal styles
  local nt_copy = TYPE.deep_copy(normal_target)
  for i, s in ipairs(style) do
    s.modify(normal, nt_copy)
  end
  -- clear name
  normal.name = nil
  -- store the used target for debugging purposes only
  win.ns.normal_target = normal_target

  local existing_normal = win.ns.vimade_highlights['vimade_0']

  local cache_key = get_replacement_key(normal, win.ns)
  link_cache[cache_key] = 'vimade_0'


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

  local cache_key = get_replacement_key(normal, win.ns)
  link_cache[cache_key] = 'vimade_0'
  vim.api.nvim_set_hl(win.ns.vimade_ns, 'vimade_0', normal)
  win.ns.vimade_highlights['vimade_0'] = normal

  -- we use links to reduce the amount of actual highlights that need to be configured.  We can instead
  -- link existing highlights to ones that already match the target colors.  This reduces the
  -- overall definitions by 80-90%.
  local existing_normal = win.ns.vimade_highlights['Normal']
  -- perf
  --if existing_normal and existing_normal.link == 'vimade_0' then
    --existing = existing + 1
  --end
  if existing_normal == nil or existing_normal.link ~= 'vimade_0' then
    local linked_normal = {link='vimade_0'}
    vim.api.nvim_set_hl(win.ns.vimade_ns, 'NormalNC',  linked_normal)
    vim.api.nvim_set_hl(win.ns.vimade_ns, 'Normal', linked_normal)
    win.ns.vimade_highlights['Normal'] = linked_normal
    win.ns.vimade_highlights['NormalNC'] = linked_normal
  end

  for name, highlight in pairs(highlights) do
    -- perf
    --total_cnt = total_cnt + 1
    if name == 'NormalNC' or name =='Normal' then
      --pass
    else
      -- copies area required here as user mutations are expected. Deep copy due to cterm
      local hi = TYPE.deep_copy(highlight)
      local hi_target = TYPE.deep_copy(normal_target)

      hi.name = name

      --TODO(see https://github.com/TaDaa/vimade/issues/81)
      --Don't enable this again below (it shouldn't be needed any more anyways)
      -- set default fg highlights if they are unset
      --if hi.fg == nil then
      --end
      --if hi.ctermfg == nil then
      --end

      for i, s in ipairs(style) do
        s.modify(hi, hi_target)
      end

      hi.name = nil

      local existing_hi = win.ns.vimade_highlights[name]
      local cache_key = get_replacement_key(hi, win.ns)

      -- perf
      --if hi.link ~= nil then
        --skipped = skipped + 1
      --end

      -- TODO re-add link skipping (removed for g:fademode='windows' animations)
      -- given a valid cache key, we check to see if we can link it something already
      -- existing in the namespace.  This is a common scenario and usually the answer is yes
      if cache_key ~= nil then
        if link_cache[cache_key] then
          -- perf
          -- only create links for highlights that are not in the replacement namespace already
          -- or those that are linked to the wrong highlight (or not at all)
          if existing_hi == nil or existing_hi.link ~= link_cache[cache_key] then
            local linked_hi = {link=link_cache[cache_key]}
            vim.api.nvim_set_hl(win.ns.vimade_ns, name, linked_hi)
            win.ns.vimade_highlights[name] = linked_hi
            --cnt_linked = cnt_linked + 1
          --else
            --existing = existing + 1
          end
        else
          link_cache[cache_key] = name
          vim.api.nvim_set_hl(win.ns.vimade_ns, name, hi)
          win.ns.vimade_highlights[name] = hi
          --cnt_new_links = cnt_new_links + 1
        end
      end
    end
  end
  --print('existing', existing,'linked', cnt_linked, 'skipped', skipped, 'new_links', cnt_new_links, 'total_cnt', total_cnt)
end


return M


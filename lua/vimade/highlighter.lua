local M = {}
local GLOBALS = require('vimade.state.globals')
local TYPE = require('vimade.util.type')

local get_highlights = function (win, config)
  local output = TYPE.deep_copy(GLOBALS.global_highlights)
  if win.ns.real_ns ~=0 then
    local overrides = TYPE.deep_copy(win.ns.real_highlights)
    for name, override in pairs(overrides) do
      if output[name] == nil then
        output[name] = override
      else
        local global_highlight = output[name]
        for key, value in pairs(override) do
          global_highlight[key] = value
        end
      end
    end
    return output
  else
    return output
  end
end

M.set_highlights = function(win)
  local fade = win.fadelevel
  local tint = win.tint
  local default_fg = GLOBALS.is_dark and 0xFFFFFF or 0x000000
  local default_bg = GLOBALS.is_dark and 0x000000 or 0xFFFFFF
  local default_sp = default_fg
  local default_ctermfg = GLOBALS.is_dark and 231 or 0
  local default_ctermbg = GLOBALS.is_dark and 0 or 231
  local highlights = win.ns.complete_highlights
  local normal_nc = TYPE.deep_copy(highlights.NormalNC or {})
  local normal = TYPE.deep_copy(highlights.Normal or {})
  
  -- we have to unlink Normal and NormalNC highlights from any shenanigans that plugins are doing
  -- things should still fade as expected.
  normal.link = nil
  if normal_nc.link then
    normal_nc.link = nil
  end

  if win.is_active_win then
    --pass
  else
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

  local normal_fg = normal.fg or default_fg
  local normal_bg = normal.bg or default_bg
  local normal_sp = normal.sp or default_sp
  local normal_ctermfg = normal.ctermfg or default_ctermfg
  local normal_ctermbg = normal.ctermbg or default_ctermbg

  local normal_target = {
    name = '',
    fg = normal_fg,
    bg = normal_bg,
    sp = normal_sp,
    ctermfg = normal_ctermfg,
    ctermbg = normal_ctermbg,
  }

  local style = win.style
  for name, highlight in pairs(highlights) do
    if name == 'NormalNC' or name =='Normal' then
      --pass
    else
      -- copies area required here as user mutations are expected
      local hi = TYPE.shallow_copy(highlight)
      local hi_target = TYPE.shallow_copy(normal_target)

      -- set default fg highlights if they are unset
      hi.name = name
      if hi.fg == nil then
        hi.fg = normal_fg
      end
      if hi.ctermfg == nil then
        hi.ctermfg = normal_ctermfg
      end

      for i, s in ipairs(style) do
        s.modify(hi, hi_target)
      end

      -- name needs to be unset before call nvim_set_hl
      hi.name = nil
      vim.api.nvim_set_hl(win.ns.vimade_ns, name, hi)
    end
  end

  -- set default fg highlights if they are unset
  normal.name = 'Normal'
  if normal.fg == nil then
    normal.fg = normal_fg
  end
  if normal.ctermfg == nil then
    normal.ctermfg = normal_ctermfg
  end

  for i, s in ipairs(style) do
    s.modify(normal, normal_target)
  end
  normal.name = nil
  vim.api.nvim_set_hl(win.ns.vimade_ns, 'NormalNC' , normal)
  vim.api.nvim_set_hl(win.ns.vimade_ns, 'Normal' , normal)
  vim.api.nvim_set_hl(win.ns.vimade_ns, 'vimade_0' , normal)
end
return M

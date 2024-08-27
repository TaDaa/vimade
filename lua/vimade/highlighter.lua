local M = {}
local COLORS = require('vimade.colors')
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
  local default_bg = GLOBALS.is_dark and 0 or 0xFFFFFF
  local default_ctermbg = GLOBALS.is_dark and 0 or 255
  local highlights = get_highlights(win, {})
  local normal_nc = TYPE.deep_copy(highlights.NormalNC)
  local normal = TYPE.deep_copy(highlights.Normal)

  if win.is_active_win then
    --pass
  else
    if normal_nc.ctermbg ~= nil then
      normal.ctermbg = normal_nc.ctermbg
    end
    if normal_nc.bg ~= nil then
      normal.bg = normal_nc.bg
    end
  end

  local normal_bg = normal.bg or default_bg
  local normal_ctermbg = normal.ctermbg or default_ctermbg

  local target = {
    bg = normal_bg,
    fg = normal_bg,
    sp = normal_bg,
    ctermfg = normal_ctermbg,
    ctermbg = normal_ctermbg,
  }


  if tint and (tint.bg or tint.fg or tint.sp) then
    local tint_out = COLORS.tint(tint, normal_bg, normal_ctermbg)
    if tint_out.fg ~= nil then
      target.fg = tint_out.fg
    end
    if tint_out.ctermfg ~= nil then
      target.ctermfg = tint_out.ctermfg
    end
    if tint_out.sp ~= nil then
      target.sp = tint_out.sp
    end
    if tint_out.bg ~= nil then
      target.bg = tint_out.bg
    end
    if tint_out.ctermbg ~= nil then
      target.ctermbg = tint_out.ctermbg
    end
  end

  for name, highlight in pairs(highlights) do
    if name == 'NormalNC' or name =='Normal' then
      --pass
    else
      local hi = M.create_highlight(highlight, target, fade)
      vim.api.nvim_set_hl(win.ns.vimade_ns, name, hi)
    end
  end
  normal = M.create_highlight(normal, target, fade)
  vim.api.nvim_set_hl(win.ns.vimade_ns, 'NormalNC' , normal)
  vim.api.nvim_set_hl(win.ns.vimade_ns, 'Normal' , normal)
  vim.api.nvim_set_hl(win.ns.vimade_ns, 'vimade_0' , normal)
end

M.create_highlight = function(highlight, target, fade)
  local result = TYPE.deep_copy(highlight)
  if result.fg ~= nil then
    result.fg = COLORS.interpolate24b(highlight.fg, target.fg, fade)
  end
  if result.bg ~= nil then
    result.bg = COLORS.interpolate24b(highlight.bg, target.bg, fade)
  end
  if result.sp ~= nil then
    result.sp = COLORS.interpolate24b(highlight.sp, target.sp, fade)
  end
  if result.blend ~= nil then
    --always assume blend is 100
    result.blend = COLORS.interpolateLinear(highlight.blend, 100, fade)
  end
  if result.ctermfg ~= nil then
    result.ctermfg = COLORS.interpolate256(highlight.ctermfg, target.ctermfg, fade)
  end
  if result.ctermbg ~= nil then
    result.ctermbg = COLORS.interpolate256(highlight.ctermbg, target.ctermbg, fade)
  end
  return result
end

return M

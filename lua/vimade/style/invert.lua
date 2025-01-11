local M = {}

local CONDITION = require('vimade.style.value.condition')
local COLOR_UTIL = require('vimade.util.color')
local TYPE = require('vimade.util.type')
local VALIDATE = require('vimade.util.validate')

local INTERPOLATE_256 = COLOR_UTIL.interpolate256
local INTERPOLATE_24B = COLOR_UTIL.interpolate24b
local TO_RGB = COLOR_UTIL.toRgb

-- @required
-- number | {
--   @optional fg = 0-1,         # applies the given intensity to text
--   @optional bg = 0-1,         # applies the given intensity to background
--   @optional sp = 0-1,         # applies the given intensity to special
-- }
M.Invert = function(config)
  local result = {}
  local _value = config.value 
  local _condition = config.condition or CONDITION.INACTIVE
  result.tick = config.tick
  result.attach = function(win)
    local invert = _value
    local condition = _condition
    local style = {}
    style.win = win
    style._condition = _condition
    style._animating = false
    style.resolve = function (value, state)
      return VALIDATE.invert(TYPE.resolve_all_fn(value, style, state))
    end
    style.before = function (win, state)
      invert = style.resolve(_value, state)
      -- condition needs to be the last check due to animation checks
      if type(_condition) == 'function' then
        condition = _condition(style, state)
      end
    end
    style.key = function (win, state)
      if condition == false then
        return ''
      end
      return 'INV-' .. (invert.fg or 0) .. '-' .. (invert.bg or 0) .. '-' .. (invert.sp or 0)
    end
    style.modify = function (highlights, to_hl)
      if condition == false or invert == nil then
        return
      end
      local color
      if to_hl.fg then
        to_hl.fg = INTERPOLATE_24B(to_hl.fg, 0xFFFFFF - to_hl.fg, 1 - invert.fg)
      end
      if to_hl.bg then
        to_hl.bg = INTERPOLATE_24B(to_hl.bg, 0xFFFFFF - to_hl.bg, 1 - invert.bg)
      end
      if to_hl.sp then
        to_hl.sp = INTERPOLATE_24B(to_hl.sp, 0xFFFFFF - to_hl.sp, 1 - invert.sp)
      end
      if to_hl.ctermfg then
        color = TO_RGB(to_hl.ctermfg, true)
        to_hl.ctermfg = INTERPOLATE_256(color, {255 - color[1], 255 - color[2], 255 - color[3]}, 1 - invert.fg)
      end
      if to_hl.ctermbg then
        color = TO_RGB(to_hl.ctermbg, true)
        to_hl.ctermbg = INTERPOLATE_256(color, {255 - color[1], 255 - color[2], 255 - color[3]}, 1 - invert.bg)
      end
      for _, hl in pairs(highlights) do
        if not hl.link then
          if hl.fg then
            hl.fg = INTERPOLATE_24B(hl.fg, 0xFFFFFF - hl.fg, 1 - invert.fg)
          end
          if hl.bg then
            hl.bg = INTERPOLATE_24B(hl.bg, 0xFFFFFF - hl.bg, 1 - invert.bg)
          end
          if hl.sp then
            hl.sp = INTERPOLATE_24B(hl.sp, 0xFFFFFF - hl.sp, 1 - invert.sp)
          end
          if hl.ctermfg then
            color = TO_RGB(hl.ctermfg, true)
            hl.ctermfg = INTERPOLATE_256(color, {255 - color[1], 255 - color[2], 255 - color[3]}, 1 - invert.fg)
          end
          if hl.ctermbg then
            color = TO_RGB(hl.ctermbg, true)
            hl.ctermbg = INTERPOLATE_256(color, {255 - color[1], 255 - color[2], 255 - color[3]}, 1 - invert.bg)
          end
        end
      end
    end
    return style
  end
  result.value = function (replacement)
    if replacement ~= nil then
      _value = replacement
      return result
    end
    return _value
  end
  return result
end

return M

local M = {}

local CONDITION = require('vimade.style.value.condition')
local COLOR_UTIL = require('vimade.util.color')
local TYPE = require('vimade.util.type')
local VALIDATE = require('vimade.util.validate')
local GLOBALS

M.__init = function(args)
  GLOBALS = args.GLOBALS
end

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
    style.modify = function (hl, to_hl)
      if condition == false or hl.link or invert == nil then
        return
      end
      for i, hi in pairs({hl, to_hl}) do
        for j, key in pairs({'fg', 'bg', 'sp'}) do
          local color = hi[key]
          if color ~= nil then
            hi[key] = COLOR_UTIL.interpolate24b(color, 0xFFFFFF - color, 1 - invert[key])
          end
        end
        for j, keys in pairs({{'ctermfg', 'fg'}, {'ctermbg', 'bg'}}) do
          local key = keys[1]
          local i_key = keys[2]
          local color = hi[key]
          if color ~= nil then
            color = COLOR_UTIL.toRgb(color, true)
            local target = {255 - color[1], 255 - color[2], 255 -color[3]}
            hi[key] = COLOR_UTIL.interpolate256(color, target , 1 - invert[i_key])
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

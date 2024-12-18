local COLOR_UTIL = require('vimade.util.color')
local M = {}

local TO_RGB = COLOR_UTIL.toRgb
local TO_24B = COLOR_UTIL.to24b
local MATH_MIN = math.min
local MATH_MAX = math.max

local RANGE
local INTENSITY
local RGB
local COLOR


M.range = function (value, min, max, default)
  default = default or 0
  if type(value) ~= 'number' then
    value = tonumber(value)
  end
  if value == nil then
    return default
  end
  return MATH_MIN(MATH_MAX(value, min), max)
end
RANGE = M.range

M.fade = function (value)
  return RANGE(value, 0, 1, 0.4)
end

M.intensity = function (value)
  return RANGE(value, 0, 1, 1)
end
INTENSITY = M.intensity

M.rgb = function (value)
  if type(value) ~= 'table' then
    return nil
  end
  value[1] = RANGE(value[1], 0, 255, 0)
  value[2] = RANGE(value[2], 0, 255, 0)
  value[3] = RANGE(value[3], 0, 255, 0)
  return value
end
RGB = M.rgb

M.color = function (value, is256)
  is256 = is256 or false
  if type(value) == 'table' then
    return RGB(value)
  end
  if type(value) == 'string' then
    value = TO_24B(value)
  end
  if is256 then
    return RANGE(value, 0, 255, 0)
  else
    return RANGE(value, 0, 0xFFFFFF, 0)
  end
end
COLOR = M.color

M.invert = function (value)
  if type(value) == 'number' then
    value = RANGE(value, 0, 1, 0)
    return {fg = value, bg = value, sp = value}
  end
  if type(value) == 'table' then
    value.fg = RANGE(value.fg, 0, 1, 0)
    value.bg = RANGE(value.bg, 0, 1, 0)
    value.sp = RANGE(value.sp, 0, 1, 0)
    return value
  end
  return {fg = 0, bg = 0, sp = 0}
end

local tint_attr = function (value)
  if type(value) ~= 'table' then
    return nil
  end
  if value.rgb then
    value.rgb = COLOR(value.rgb)
    if type(value.rgb) ~= 'table' and value.rgb then
      value.rgb = TO_RGB(value.rgb)
    end
    value.intensity = INTENSITY(value.intensity)
  elseif value.intensity then
    value.intensity = INTENSITY(value.intensity)
  end
  if value.rgb and value.intensity then
    return value
  end
  return nil
end

M.tint = function (value)
  if type(value) ~= 'table' then
    return nil
  end
  for k, v in pairs(value) do
    if k ~= 'fg' and k ~= 'bg' and k ~= 'sp' then
      value[k] = nil
    else
      value[k] = tint_attr(v)
    end
  end
  return value
end

return M

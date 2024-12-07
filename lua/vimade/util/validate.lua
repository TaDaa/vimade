local COLOR_UTIL = require('vimade.util.color')
local M = {}

M.range = function (value, min, max, default)
  default = default or 0
  if type(value) ~= 'number' then
    value = tonumber(value)
  end
  if value == nil then
    return default
  end
  return math.min(math.max(value, min), max)
end

M.fade = function (value)
  return M.range(value, 0, 1, 0.4)
end

M.intensity = function (value)
  return M.range(value, 0, 1, 1)
end

M.rgb = function (value)
  if type(value) ~= 'table' then
    return nil
  end
  value[1] = M.range(value[1], 0, 255, 0)
  value[2] = M.range(value[2], 0, 255, 0)
  value[3] = M.range(value[3], 0, 255, 0)
  return value
end

M.color = function (value, is256)
  is256 = is256 or false
  if type(value) == 'table' then
    return M.rgb(value)
  end
  if type(value) == 'string' then
    value = COLOR_UTIL.to24b(value)
  end
  if is256 then
    return M.range(value, 0, 255, 0)
  else
    return M.range(value, 0, 0xFFFFFF, 0)
  end
end

M.invert = function (value)
  if type(value) == 'number' then
    value = M.range(value, 0, 1, 0)
    return {fg = value, bg = value, sp = value}
  end
  if type(value) == 'table' then
    if value.fg then
      value.fg = M.range(value.fg, 0, 1, 0)
    end
    if value.bg then
      value.bg = M.range(value.bg, 0, 1, 0)
    end
    if value.sp then
      value.sp = M.range(value.sp, 0, 1, 0)
    end
    return value
  end
  return {fg = 0, bg = 0, sp = 0}
end

M.tint_attr = function (value)
  if type(value) ~= 'table' then
    return nil
  end
  if value.rgb then
    value.rgb = M.color(value.rgb)
    if type(value.rgb) ~= 'table' and value.rgb then
      value.rgb = COLOR_UTIL.toRgb(value.rgb)
    end
    value.intensity = M.intensity(value.intensity)
  elseif value.intensity then
    value.intensity = M.intensity(value.intensity)
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
      value[k] = M.tint_attr(v)
    end
  end
  return value
end

return M

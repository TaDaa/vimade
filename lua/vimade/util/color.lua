local M = {}
local bit = require('bit')

local BIT_BAND = bit.band
local BIT_LSHIFT = bit.lshift
local BIT_RSHIFT = bit.rshift
local MATH_ABS = math.abs
local MATH_FLOOR = math.floor
local MATH_MAX = math.max
local MATH_MIN = math.min
local STRING_SUB = string.sub
local STRING_LEN = string.len
local STRING_FORMAT = string.format

local RGB_256 = {{0,0,0},{128,0,0},{0,128,0},{128,128,0},{0,0,128},{128,0,128},{0,128,128},{192,192,192},{128,128,128},{255,0,0},{0,255,0},{255,255,0},{0,0,255},{255,0,255},{0,255,255},{255,255,255},{0,0,0},{0,0,95},{0,0,135},{0,0,175},{0,0,215},{0,0,255},{0,95,0},{0,95,95},{0,95,135},{0,95,175},{0,95,215},{0,95,255},{0,135,0},{0,135,95},{0,135,135},{0,135,175},{0,135,215},{0,135,255},{0,175,0},{0,175,95},{0,175,135},{0,175,175},{0,175,215},{0,175,255},{0,215,0},{0,215,95},{0,215,135},{0,215,175},{0,215,215},{0,215,255},{0,255,0},{0,255,95},{0,255,135},{0,255,175},{0,255,215},{0,255,255},{95,0,0},{95,0,95},{95,0,135},{95,0,175},{95,0,215},{95,0,255},{95,95,0},{95,95,95},{95,95,135},{95,95,175},{95,95,215},{95,95,255},{95,135,0},{95,135,95},{95,135,135},{95,135,175},{95,135,215},{95,135,255},{95,175,0},{95,175,95},{95,175,135},{95,175,175},{95,175,215},{95,175,255},{95,215,0},{95,215,95},{95,215,135},{95,215,175},{95,215,215},{95,215,255},{95,255,0},{95,255,95},{95,255,135},{95,255,175},{95,255,215},{95,255,255},{135,0,0},{135,0,95},{135,0,135},{135,0,175},{135,0,215},{135,0,255},{135,95,0},{135,95,95},{135,95,135},{135,95,175},{135,95,215},{135,95,255},{135,135,0},{135,135,95},{135,135,135},{135,135,175},{135,135,215},{135,135,255},{135,175,0},{135,175,95},{135,175,135},{135,175,175},{135,175,215},{135,175,255},{135,215,0},{135,215,95},{135,215,135},{135,215,175},{135,215,215},{135,215,255},{135,255,0},{135,255,95},{135,255,135},{135,255,175},{135,255,215},{135,255,255},{175,0,0},{175,0,95},{175,0,135},{175,0,175},{175,0,215},{175,0,255},{175,95,0},{175,95,95},{175,95,135},{175,95,175},{175,95,215},{175,95,255},{175,135,0},{175,135,95},{175,135,135},{175,135,175},{175,135,215},{175,135,255},{175,175,0},{175,175,95},{175,175,135},{175,175,175},{175,175,215},{175,175,255},{175,215,0},{175,215,95},{175,215,135},{175,215,175},{175,215,215},{175,215,255},{175,255,0},{175,255,95},{175,255,135},{175,255,175},{175,255,215},{175,255,255},{215,0,0},{215,0,95},{215,0,135},{215,0,175},{215,0,215},{215,0,255},{215,95,0},{215,95,95},{215,95,135},{215,95,175},{215,95,215},{215,95,255},{215,135,0},{215,135,95},{215,135,135},{215,135,175},{215,135,215},{215,135,255},{215,175,0},{215,175,95},{215,175,135},{215,175,175},{215,175,215},{215,175,255},{215,215,0},{215,215,95},{215,215,135},{215,215,175},{215,215,215},{215,215,255},{215,255,0},{215,255,95},{215,255,135},{215,255,175},{215,255,215},{215,255,255},{255,0,0},{255,0,95},{255,0,135},{255,0,175},{255,0,215},{255,0,255},{255,95,0},{255,95,95},{255,95,135},{255,95,175},{255,95,215},{255,95,255},{255,135,0},{255,135,95},{255,135,135},{255,135,175},{255,135,215},{255,135,255},{255,175,0},{255,175,95},{255,175,135},{255,175,175},{255,175,215},{255,175,255},{255,215,0},{255,215,95},{255,215,135},{255,215,175},{255,215,215},{255,215,255},{255,255,0},{255,255,95},{255,255,135},{255,255,175},{255,255,215},{255,255,255},{8,8,8},{18,18,18},{28,28,28},{38,38,38},{48,48,48},{58,58,58},{68,68,68},{78,78,78},{88,88,88},{98,98,98},{108,108,108},{118,118,118},{128,128,128},{138,138,138},{148,148,148},{158,158,158},{168,168,168},{178,178,178},{188,188,188},{198,198,198},{208,208,208},{218,218,218},{228,228,228},{238,238,238}}
local RGB_THRESHOLDS = {-1, 0, 95, 135, 175, 215, 255, 256, length = 8}
local GREY_THRESHOLDS = {-1, 8, 18, 28, 38, 48, 58, 68, 78, 88, 98, 108, 118, 128, 138, 148, 158, 168, 178, 188, 198, 208, 218, 228, 238, 258, length=26}
local LOOKUP_256_RGB = {}
for i,rgb in pairs(RGB_256) do
  LOOKUP_256_RGB[rgb[1]..'-'..rgb[2]..'-'..rgb[3]] = i - 1
end
local INTERPOLATE_LINEAR

M.to24b = function(color, is256)
  local r
  local g
  local b

  if is256 and type(color) == 'number' then
    color = RGB_256[color+1] or RGB_256[1]
  end

  if type(color) == 'table' then
    r = tonumber(color[1]) or 0
    g = tonumber(color[2]) or 0
    b = tonumber(color[3]) or 0
    return tonumber('0x'..STRING_FORMAT('%02x',r)..STRING_FORMAT('%02x',g)..STRING_FORMAT('%02x',b)) or 0
  elseif type(color) == 'string' then
    -- convert vim/nvim highlight patterns to normal numbers
    if STRING_SUB(color, 1, 1) == '#' then
      color = '0x' .. STRING_SUB(color, 2, STRING_LEN(color))
    end
    -- lua tonumber gracefully handles invalid input and various base types.
    return tonumber(color) or 0
  elseif type(color) == 'number' then
    return color
  end
end

M.toRgb = function (color, is256)
  local r
  local g
  local b

  if type(color) == 'string' and STRING_SUB(color, 1, 1) == '#' then
    color = tonumber('0x' .. STRING_SUB(color, 2, STRING_LEN(color))) or 0
  end
  if type(color) == 'number' then
    if is256 then
     color = RGB_256[color+1] or RGB_256[1]
    else
      r = BIT_RSHIFT(BIT_BAND(color, 0xFF0000), 16)
      g = BIT_RSHIFT(BIT_BAND(color, 0x00FF00), 8)
      b = BIT_BAND(color, 0x0000FF)
    end
  end
  if type(color) == 'table' then
    r = color[1]
    g = color[2]
    b = color[3]
  end
  return {r,g,b}
end

M.interpolate24b = function(source, target, fade)
  local target_r = BIT_RSHIFT(BIT_BAND(target, 0xFF0000), 16)
  local target_g = BIT_RSHIFT(BIT_BAND(target, 0x00FF00), 8)
  local target_b = BIT_BAND(target, 0x0000FF)
  local r = MATH_FLOOR(target_r + (BIT_RSHIFT(BIT_BAND(source, 0xFF0000), 16) - target_r) * fade)
  local g = MATH_FLOOR(target_g + (BIT_RSHIFT(BIT_BAND(source, 0x00FF00), 8) - target_g) * fade)
  local b = MATH_FLOOR(target_b + (BIT_BAND(source, 0x0000FF) - target_b) * fade)
  return BIT_LSHIFT(r, 16) + BIT_LSHIFT(g, 8) + b
end

M.interpolateLinear = function(source, target, fade)
  return MATH_FLOOR(target + (source - target) * fade)
end
INTERPOLATE_LINEAR = M.interpolateLinear

M.interpolateRgb = function(source, target, fade)
  source = source or target or {0,0,0}
  target = target or source
  local r = INTERPOLATE_LINEAR(source[1], target[1], fade)
  local g = INTERPOLATE_LINEAR(source[2], target[2], fade)
  local b = INTERPOLATE_LINEAR(source[3], target[3], fade)
  return {r,g,b}
end

M.interpolateFloat = function(source, target, fade)
  source = source or 0
  target = target or 0
  fade = fade or 1
  return target + (source - target) * fade
end

M.interpolate256 = function(source, target, fade, prefer_color)
  prefer_color = prefer_color or false
  local source = type(source) == 'table' and source or RGB_256[source+1]
  local to = type(target) == 'table' and target or RGB_256[target+1]
  local r = 0
  local g = 0
  local b = 0
  if source == to then
    r = source[1]
    g = source[2]
    b = source[3]
  else
    local target = {MATH_FLOOR(to[1]+(source[1]-to[1])*fade), MATH_FLOOR(to[2]+(source[2]-to[2])*fade), MATH_FLOOR(to[3]+(source[3]-to[3])*fade)}
    local dir = (to[1]+to[2]+to[3]) / 3 - (source[1]+source[2]+source[3]) / 3
    local i = 0
    local rgb_result = {0,0,0}
    local grey_result = {0,0,0}
    for k, v in ipairs(target) do
        i = i + 1
        local j = 2
        while j <= RGB_THRESHOLDS.length do
          if v > RGB_THRESHOLDS[j] then
            j = j + 1
          else
            if v <= (RGB_THRESHOLDS[j]/2.5 + RGB_THRESHOLDS[j-1]/2) then
              rgb_result[i] = j - 1 
            else
              rgb_result[i] = j
            end
            break
          end
        end
        j = 2
        while j <= GREY_THRESHOLDS.length do
          if v > GREY_THRESHOLDS[j] then
            j = j+1
          else
            if v < (GREY_THRESHOLDS[j]/2.5 + GREY_THRESHOLDS[j-1]/2) then
              grey_result[i] = j - 1 
            else
              grey_result[i] = j
            end
            break
          end
        end
    end
    r = rgb_result[1]
    g = rgb_result[2]
    b = rgb_result[3]
    local r0 = target[1]
    local g0 = target[2]
    local b0 = target[3]
    local thres = 25
    dir = (dir > thres) and -1 or 1
    if dir < 0 then
      r = r + dir
      g = g + dir
      b = b + dir
    end
    if r == g and g == b and r == b then
      if (r0 >= g0 or r0 >= b0) and (r0 <= g0 or r0 <= b0) then
        if g0 - thres > r0 then g = rgb_result[2]+dir end
        if b0 - thres > r0 then b = rgb_result[3]+dir end
        if g0 + thres < r0 then g = rgb_result[2]-dir end
        if b0 + thres < r0 then b = rgb_result[3]-dir end
      elseif (g0 >= r0 or g0 >= b0) and (g0 <= r0 or g0 <= b0) then
        if r0 - thres > g0 then r = rgb_result[1]+dir end
        if b0 - thres > g0 then b = rgb_result[3]+dir end
        if r0 + thres < g0 then r = rgb_result[1]-dir end
        if b0 + thres < g0 then b = rgb_result[3]-dir end
      elseif (b0 >= g0 or b0 >= r0) and (b0 <= g0 or b0 <= r0) then
        if g0 - thres > b0 then g = rgb_result[2]+dir end
        if r0 - thres > b0 then r = rgb_result[1]+dir end
        if g0 + thres < b0 then g = rgb_result[2]-dir end
        if r0 + thres < b0 then r = rgb_result[1]-dir end
      end
    end
    if r < 2 or g < 2 or b < 2 then
      r = r + 1
      g = g + 1
      b = b + 1
    end
    if r == 8 or g == 8 or b == 8 then
      r = r - 1
      g = g - 1
      b = b - 1
    end
    r = MATH_MIN(MATH_MAX(r, 2), 7)
    g = MATH_MIN(MATH_MAX(g, 2), 7)
    b = MATH_MIN(MATH_MAX(b, 2), 7)
    r = RGB_THRESHOLDS[r]
    g = RGB_THRESHOLDS[g]
    b = RGB_THRESHOLDS[b]


    local grey = MATH_MAX(grey_result[1], grey_result[2], grey_result[3])
    grey = MATH_MIN(MATH_MAX(grey, 2), GREY_THRESHOLDS.length - 1)
    grey = GREY_THRESHOLDS[grey]

    if MATH_ABS(grey-r0) + MATH_ABS(grey - g0) + MATH_ABS(grey - b0)
      < (MATH_ABS(r-r0) + MATH_ABS(g - g0) + MATH_ABS(b - b0)) / (prefer_color == true and 100 or 1.2) then
      r = grey
      g = grey
      b = grey
    end
  end
  return LOOKUP_256_RGB[r .. '-' .. g .. '-' .. b]
end

return M

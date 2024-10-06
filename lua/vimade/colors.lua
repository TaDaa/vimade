local M = {}
local TINT = require('vimade.config_helpers.tint')
local COLOR_UTIL = require('vimade.util.color')

local tint24b = function (tint, bg24)
  if not tint.type or tint.type == TINT.MIX then
    return COLOR_UTIL.to24b(M.interpolate24b(COLOR_UTIL.to24b(tint.rgb), bg24, tint.intensity or 1))
  elseif tint.type == TINT.REPLACE then
    return COLOR_UTIL.to24b(tint.rgb)
  end

end
local tint256 = function (tint, bg256)
  if not tint.type or tint.type == TINT.MIX then
    --local result = M.interpolate256(0, COLOR_UTIL.toRgb(tint.rgb), 0, true)
    --result = M.interpolate256(result, COLOR_UTIL.toRgb(bg256),  tint.intensity)
    --return result
    local result = M.interpolate24b(COLOR_UTIL.to24b(tint.rgb), bg256, tint.intensity or 1)
    result = COLOR_UTIL.to24b(result)
    result = COLOR_UTIL.toRgb(result)
    return M.interpolate256(0, result, 0, true)
  elseif tint.type == TINT.REPLACE then
    return M.interpolate256(0, COLOR_UTIL.toRgb(tint.rgb), 1 - tint.intensity, true)
  end
end

M.get_tint_key = function(tint)
  if not tint then
    return ''
  end
  local bg = tint.bg
  local fg = tint.fg or bg
  local sp = tint.sp or fg

  local sp_rgb
  local fg_rgb
  local bg_rgb
  if sp and type(sp.rgb) ~= 'table' then
    sp_rgb = COLOR_UTIL.toRgb(sp.rgb)
  end
  if fg and type(fg.rgb) ~= 'table' then
    fg_rgb = COLOR_UTIL.toRgb(fg.rgb)
  end
  if bg and type(bg.rgb) ~= 'table' then
    bg_rgb = COLOR_UTIL.toRgb(bg.rgb)
  end

  return (sp_rgb and (sp_rgb[1]..sp_rgb[2]..sp_rgb[3]..(sp.intensity or 1)) or '')
   ..(fg_rgb and (fg_rgb[1]..fg_rgb[2]..fg_rgb[3]..(fg.intensity or 1)) or '')
   ..(bg_rgb and (bg_rgb[1]..bg_rgb[2]..bg_rgb[3]..(bg.intensity or 1)) or '')
end

M.tint = function (tint, bg24, bg256)
  local result = {}
  local bg = tint.bg
  local fg = tint.fg
  local sp = tint.sp
  local ctermbg = COLOR_UTIL.to24b(bg256, true)

  if bg then
    result.bg = tint24b(bg, bg24)
    result.ctermbg = tint256(bg, ctermbg)
  end

  result.fg = fg and tint24b(fg, bg24) or result.bg
  result.ctermfg = fg and tint256(fg, ctermbg) or result.ctermbg
  result.sp = sp and tint24b(sp, bg24) or result.fg

  return result
end

M.interpolate24b = function(source, target, fade)
  local target_r = bit.rshift(bit.band(target, 0xFF0000), 16)
  local target_g = bit.rshift(bit.band(target, 0x00FF00), 8)
  local target_b = bit.band(target, 0x0000FF)
  local r = M.interpolateLinear(bit.rshift(bit.band(source, 0XFF0000), 16), target_r, fade)
  local g = M.interpolateLinear(bit.rshift(bit.band(source, 0X00FF00), 8), target_g, fade)
  local b = M.interpolateLinear(bit.band(source, 0X0000FF), target_b, fade)
  return '#'..string.format('%02x',r)..string.format('%02x',g)..string.format('%02x',b)
end

M.interpolateLinear = function(source, target, fade)
  return math.floor(target + (source - target) * fade)
end

-- TODO update python version with updated grey algo
M.interpolate256 = function(source, target, fade, prefer_color)
  prefer_color = prefer_color or false
  local source = type(source) == 'table' and source or COLOR_UTIL.RGB_256[source+1]
  local to = type(target) == 'table' and target or COLOR_UTIL.RGB_256[target+1]
  local r = 0
  local g = 0
  local b = 0
  if source == to then
    r = source[1]
    g = source[2]
    b = source[3]
  else
    local target = {math.floor(to[1]+(source[1]-to[1])*fade), math.floor(to[2]+(source[2]-to[2])*fade), math.floor(to[3]+(source[3]-to[3])*fade)}
    local dir = (to[1]+to[2]+to[3]) / 3 - (source[1]+source[2]+source[3]) / 3
    local i = 0
    local rgb_result = {0,0,0}
    local grey_result = {0,0,0}
    for k, v in ipairs(target) do
        i = i + 1
        local j = 2
        while j <= COLOR_UTIL.RGB_THRESHOLDS.length do
          if v > COLOR_UTIL.RGB_THRESHOLDS[j] then
            j = j + 1
          else
            if v <= (COLOR_UTIL.RGB_THRESHOLDS[j]/2.5 + COLOR_UTIL.RGB_THRESHOLDS[j-1]/2) then
              rgb_result[i] = j - 1 
            else
              rgb_result[i] = j
            end
            break
          end
        end
        j = 2
        while j <= COLOR_UTIL.GREY_THRESHOLDS.length do
          if v > COLOR_UTIL.GREY_THRESHOLDS[j] then
            j = j+1
          else
            if v < (COLOR_UTIL.GREY_THRESHOLDS[j]/2.5 + COLOR_UTIL.GREY_THRESHOLDS[j-1]/2) then
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
    r = math.min(math.max(r, 2), 7)
    g = math.min(math.max(g, 2), 7)
    b = math.min(math.max(b, 2), 7)
    r = COLOR_UTIL.RGB_THRESHOLDS[r]
    g = COLOR_UTIL.RGB_THRESHOLDS[g]
    b = COLOR_UTIL.RGB_THRESHOLDS[b]


    local grey = math.max(grey_result[1], grey_result[2], grey_result[3])
    grey = math.min(math.max(grey, 2), COLOR_UTIL.GREY_THRESHOLDS.length - 1)
    grey = COLOR_UTIL.GREY_THRESHOLDS[grey]

    if math.abs(grey-r0) + math.abs(grey - g0) + math.abs(grey - b0)
      < (math.abs(r-r0) + math.abs(g - g0) + math.abs(b - b0)) / (prefer_color == true and 100 or 1.2) then
      r = grey
      g = grey
      b = grey
    end
  end
  return COLOR_UTIL.LOOKUP_256_RGB[r .. '-' .. g .. '-' .. b]
end

return M

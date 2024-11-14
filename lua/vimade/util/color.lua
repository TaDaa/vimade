local M = {}

M.RGB_256 = {{0,0,0},{128,0,0},{0,128,0},{128,128,0},{0,0,128},{128,0,128},{0,128,128},{192,192,192},{128,128,128},{255,0,0},{0,255,0},{255,255,0},{0,0,255},{255,0,255},{0,255,255},{255,255,255},{0,0,0},{0,0,95},{0,0,135},{0,0,175},{0,0,215},{0,0,255},{0,95,0},{0,95,95},{0,95,135},{0,95,175},{0,95,215},{0,95,255},{0,135,0},{0,135,95},{0,135,135},{0,135,175},{0,135,215},{0,135,255},{0,175,0},{0,175,95},{0,175,135},{0,175,175},{0,175,215},{0,175,255},{0,215,0},{0,215,95},{0,215,135},{0,215,175},{0,215,215},{0,215,255},{0,255,0},{0,255,95},{0,255,135},{0,255,175},{0,255,215},{0,255,255},{95,0,0},{95,0,95},{95,0,135},{95,0,175},{95,0,215},{95,0,255},{95,95,0},{95,95,95},{95,95,135},{95,95,175},{95,95,215},{95,95,255},{95,135,0},{95,135,95},{95,135,135},{95,135,175},{95,135,215},{95,135,255},{95,175,0},{95,175,95},{95,175,135},{95,175,175},{95,175,215},{95,175,255},{95,215,0},{95,215,95},{95,215,135},{95,215,175},{95,215,215},{95,215,255},{95,255,0},{95,255,95},{95,255,135},{95,255,175},{95,255,215},{95,255,255},{135,0,0},{135,0,95},{135,0,135},{135,0,175},{135,0,215},{135,0,255},{135,95,0},{135,95,95},{135,95,135},{135,95,175},{135,95,215},{135,95,255},{135,135,0},{135,135,95},{135,135,135},{135,135,175},{135,135,215},{135,135,255},{135,175,0},{135,175,95},{135,175,135},{135,175,175},{135,175,215},{135,175,255},{135,215,0},{135,215,95},{135,215,135},{135,215,175},{135,215,215},{135,215,255},{135,255,0},{135,255,95},{135,255,135},{135,255,175},{135,255,215},{135,255,255},{175,0,0},{175,0,95},{175,0,135},{175,0,175},{175,0,215},{175,0,255},{175,95,0},{175,95,95},{175,95,135},{175,95,175},{175,95,215},{175,95,255},{175,135,0},{175,135,95},{175,135,135},{175,135,175},{175,135,215},{175,135,255},{175,175,0},{175,175,95},{175,175,135},{175,175,175},{175,175,215},{175,175,255},{175,215,0},{175,215,95},{175,215,135},{175,215,175},{175,215,215},{175,215,255},{175,255,0},{175,255,95},{175,255,135},{175,255,175},{175,255,215},{175,255,255},{215,0,0},{215,0,95},{215,0,135},{215,0,175},{215,0,215},{215,0,255},{215,95,0},{215,95,95},{215,95,135},{215,95,175},{215,95,215},{215,95,255},{215,135,0},{215,135,95},{215,135,135},{215,135,175},{215,135,215},{215,135,255},{215,175,0},{215,175,95},{215,175,135},{215,175,175},{215,175,215},{215,175,255},{215,215,0},{215,215,95},{215,215,135},{215,215,175},{215,215,215},{215,215,255},{215,255,0},{215,255,95},{215,255,135},{215,255,175},{215,255,215},{215,255,255},{255,0,0},{255,0,95},{255,0,135},{255,0,175},{255,0,215},{255,0,255},{255,95,0},{255,95,95},{255,95,135},{255,95,175},{255,95,215},{255,95,255},{255,135,0},{255,135,95},{255,135,135},{255,135,175},{255,135,215},{255,135,255},{255,175,0},{255,175,95},{255,175,135},{255,175,175},{255,175,215},{255,175,255},{255,215,0},{255,215,95},{255,215,135},{255,215,175},{255,215,215},{255,215,255},{255,255,0},{255,255,95},{255,255,135},{255,255,175},{255,255,215},{255,255,255},{8,8,8},{18,18,18},{28,28,28},{38,38,38},{48,48,48},{58,58,58},{68,68,68},{78,78,78},{88,88,88},{98,98,98},{108,108,108},{118,118,118},{128,128,128},{138,138,138},{148,148,148},{158,158,158},{168,168,168},{178,178,178},{188,188,188},{198,198,198},{208,208,208},{218,218,218},{228,228,228},{238,238,238}}
M.RGB_THRESHOLDS = {-1, 0, 95, 135, 175, 215, 255, 256, length = 8}
M.GREY_THRESHOLDS = {-1, 8, 18, 28, 38, 48, 58, 68, 78, 88, 98, 108, 118, 128, 138, 148, 158, 168, 178, 188, 198, 208, 218, 228, 238, 258, length=26}
M.LOOKUP_256_RGB = {}
for i,rgb in pairs(M.RGB_256) do
  M.LOOKUP_256_RGB[rgb[1]..'-'..rgb[2]..'-'..rgb[3]] = i - 1
end

M.to24b = function(color, is256)
  local r
  local g
  local b

  if is256 and type(color) == 'number' then
    color = M.RGB_256[color+1] or M.RGB_256[1]
  end

  if type(color) == 'table' then
    r = color[1] or 0
    g = color[2] or 0
    b = color[3] or 0
    local result = tonumber('0x'..string.format('%02x',r)..string.format('%02x',g)..string.format('%02x',b))
    return result
  elseif type(color) == 'string' and string.sub(color, 1, 1) == '#' then
    color = '0x' .. string.sub(color, 2, string.len(color))
    return tonumber(color) or 0
  elseif type(color) == 'number' then
    return color
  end
end

M.toRgb = function (color, is256)
  local r
  local g
  local b

  if type(color) == 'string' and string.sub(color, 1, 1) == '#' then
    color = tonumber('0x' .. string.sub(color, 2, string.len(color))) or 0
  end
  if type(color) == 'number' then
    if is256 then
     color = M.RGB_256[color+1] or M.RGB_256[1]
    else
      r = bit.rshift(bit.band(color, 0xFF0000), 16)
      g = bit.rshift(bit.band(color, 0x00FF00), 8)
      b = bit.band(color, 0x0000FF)
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
  local target_r = bit.rshift(bit.band(target, 0xFF0000), 16)
  local target_g = bit.rshift(bit.band(target, 0x00FF00), 8)
  local target_b = bit.band(target, 0x0000FF)
  local r = M.interpolateLinear(bit.rshift(bit.band(source, 0XFF0000), 16), target_r, fade)
  local g = M.interpolateLinear(bit.rshift(bit.band(source, 0X00FF00), 8), target_g, fade)
  local b = M.interpolateLinear(bit.band(source, 0X0000FF), target_b, fade)
  return bit.lshift(r, 16) + bit.lshift(g, 8) + b
end

M.interpolateRgb = function(source, target, fade)
  source = source or target or {0,0,0}
  target = target or source
  local r = M.interpolateLinear(source[1], target[1], fade)
  local g = M.interpolateLinear(source[2], target[2], fade)
  local b = M.interpolateLinear(source[3], target[3], fade)
  return {r,g,b}
end

M.interpolateLinear = function(source, target, fade)
  return math.floor(target + (source - target) * fade)
end

M.interpolateFloat = function(source, target, fade)
  source = source or 0
  target = target or 0
  fade = fade or 1
  return target + (source - target) * fade
end

M.interpolate256 = function(source, target, fade, prefer_color)
  prefer_color = prefer_color or false
  local source = type(source) == 'table' and source or M.RGB_256[source+1]
  local to = type(target) == 'table' and target or M.RGB_256[target+1]
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
        while j <= M.RGB_THRESHOLDS.length do
          if v > M.RGB_THRESHOLDS[j] then
            j = j + 1
          else
            if v <= (M.RGB_THRESHOLDS[j]/2.5 + M.RGB_THRESHOLDS[j-1]/2) then
              rgb_result[i] = j - 1 
            else
              rgb_result[i] = j
            end
            break
          end
        end
        j = 2
        while j <= M.GREY_THRESHOLDS.length do
          if v > M.GREY_THRESHOLDS[j] then
            j = j+1
          else
            if v < (M.GREY_THRESHOLDS[j]/2.5 + M.GREY_THRESHOLDS[j-1]/2) then
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
    r = M.RGB_THRESHOLDS[r]
    g = M.RGB_THRESHOLDS[g]
    b = M.RGB_THRESHOLDS[b]


    local grey = math.max(grey_result[1], grey_result[2], grey_result[3])
    grey = math.min(math.max(grey, 2), M.GREY_THRESHOLDS.length - 1)
    grey = M.GREY_THRESHOLDS[grey]

    if math.abs(grey-r0) + math.abs(grey - g0) + math.abs(grey - b0)
      < (math.abs(r-r0) + math.abs(g - g0) + math.abs(b - b0)) / (prefer_color == true and 100 or 1.2) then
      r = grey
      g = grey
      b = grey
    end
  end
  return M.LOOKUP_256_RGB[r .. '-' .. g .. '-' .. b]
end

return M

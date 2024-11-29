import sys
import math
M = sys.modules[__name__]

M.RGB_256 = ((0,0,0),(128,0,0),(0,128,0),(128,128,0),(0,0,128),(128,0,128),(0,128,128),(192,192,192),(128,128,128),(255,0,0),(0,255,0),(255,255,0),(0,0,255),(255,0,255),(0,255,255),(255,255,255),(0,0,0),(0,0,95),(0,0,135),(0,0,175),(0,0,215),(0,0,255),(0,95,0),(0,95,95),(0,95,135),(0,95,175),(0,95,215),(0,95,255),(0,135,0),(0,135,95),(0,135,135),(0,135,175),(0,135,215),(0,135,255),(0,175,0),(0,175,95),(0,175,135),(0,175,175),(0,175,215),(0,175,255),(0,215,0),(0,215,95),(0,215,135),(0,215,175),(0,215,215),(0,215,255),(0,255,0),(0,255,95),(0,255,135),(0,255,175),(0,255,215),(0,255,255),(95,0,0),(95,0,95),(95,0,135),(95,0,175),(95,0,215),(95,0,255),(95,95,0),(95,95,95),(95,95,135),(95,95,175),(95,95,215),(95,95,255),(95,135,0),(95,135,95),(95,135,135),(95,135,175),(95,135,215),(95,135,255),(95,175,0),(95,175,95),(95,175,135),(95,175,175),(95,175,215),(95,175,255),(95,215,0),(95,215,95),(95,215,135),(95,215,175),(95,215,215),(95,215,255),(95,255,0),(95,255,95),(95,255,135),(95,255,175),(95,255,215),(95,255,255),(135,0,0),(135,0,95),(135,0,135),(135,0,175),(135,0,215),(135,0,255),(135,95,0),(135,95,95),(135,95,135),(135,95,175),(135,95,215),(135,95,255),(135,135,0),(135,135,95),(135,135,135),(135,135,175),(135,135,215),(135,135,255),(135,175,0),(135,175,95),(135,175,135),(135,175,175),(135,175,215),(135,175,255),(135,215,0),(135,215,95),(135,215,135),(135,215,175),(135,215,215),(135,215,255),(135,255,0),(135,255,95),(135,255,135),(135,255,175),(135,255,215),(135,255,255),(175,0,0),(175,0,95),(175,0,135),(175,0,175),(175,0,215),(175,0,255),(175,95,0),(175,95,95),(175,95,135),(175,95,175),(175,95,215),(175,95,255),(175,135,0),(175,135,95),(175,135,135),(175,135,175),(175,135,215),(175,135,255),(175,175,0),(175,175,95),(175,175,135),(175,175,175),(175,175,215),(175,175,255),(175,215,0),(175,215,95),(175,215,135),(175,215,175),(175,215,215),(175,215,255),(175,255,0),(175,255,95),(175,255,135),(175,255,175),(175,255,215),(175,255,255),(215,0,0),(215,0,95),(215,0,135),(215,0,175),(215,0,215),(215,0,255),(215,95,0),(215,95,95),(215,95,135),(215,95,175),(215,95,215),(215,95,255),(215,135,0),(215,135,95),(215,135,135),(215,135,175),(215,135,215),(215,135,255),(215,175,0),(215,175,95),(215,175,135),(215,175,175),(215,175,215),(215,175,255),(215,215,0),(215,215,95),(215,215,135),(215,215,175),(215,215,215),(215,215,255),(215,255,0),(215,255,95),(215,255,135),(215,255,175),(215,255,215),(215,255,255),(255,0,0),(255,0,95),(255,0,135),(255,0,175),(255,0,215),(255,0,255),(255,95,0),(255,95,95),(255,95,135),(255,95,175),(255,95,215),(255,95,255),(255,135,0),(255,135,95),(255,135,135),(255,135,175),(255,135,215),(255,135,255),(255,175,0),(255,175,95),(255,175,135),(255,175,175),(255,175,215),(255,175,255),(255,215,0),(255,215,95),(255,215,135),(255,215,175),(255,215,215),(255,215,255),(255,255,0),(255,255,95),(255,255,135),(255,255,175),(255,255,215),(255,255,255),(8,8,8),(18,18,18),(28,28,28),(38,38,38),(48,48,48),(58,58,58),(68,68,68),(78,78,78),(88,88,88),(98,98,98),(108,108,108),(118,118,118),(128,128,128),(138,138,138),(148,148,148),(158,158,158),(168,168,168),(178,178,178),(188,188,188),(198,198,198),(208,208,208),(218,218,218),(228,228,228),(238,238,238))
M.RGB_THRESHOLDS = (-1, 0, 95, 135, 175, 215, 255, 256)
M.GREY_THRESHOLDS = (-1, 8, 18, 28, 38, 48, 58, 68, 78, 88, 98, 108, 118, 128, 138, 148, 158, 168, 178, 188, 198, 208, 218, 228, 238, 258)
M.LOOKUP_256_RGB = {}
for i,rgb in enumerate(M.RGB_256):
  M.LOOKUP_256_RGB['%d-%d-%d' % (rgb[0], rgb[1], rgb[2])] = i

def to24b(color, is256 = False):
  r = 0
  g = 0
  b = 0

  if is256 and type(color) == int:
    color = M.RGB_256[color] or M.RGB_256[0]

  if type(color) in (tuple, list):
    ln = len(color)
    r = ln > 0 and int(color[0]) or 0
    g = ln > 1 and int(color[1]) or 0
    b = ln > 2 and int(color[2]) or 0
    result = '0x' + hex(r)[2:].zfill(2) + '' + hex(g)[2:].zfill(2) + '' + hex(b)[2:].zfill(2)
    return int(result, 16) or 0
  elif type(color) == str:
    # convert vim/nvim highlight patterns to normal numbers
    if color[0] == '#':
      color = '0x' + color[1:]
    try:
      # int(*,0) will infer the base type (base16 or 10) automatically.
      # python throws an exception if it can't be converted.
      return int(color, 0) or 0
    except:
      pass
  elif type(color) in (int, float):
    return int(color or 0)
  return None

def toRgb(color, is256 = False):
  r = 0
  g = 0
  b = 0

  if type(color) == str and len(color) > 0 and color[0] == '#':
    color = int('0x'+color[1:], 16) or 0
  if type(color) == int:
    if is256:
     color = M.RGB_256[color] or M.RGB_256[0]
    else:
      r = (color & 0xFF0000) >> 16
      g = (color & 0x00FF00) >> 8
      b = (color & 0x0000FF)
  if type(color) in (list, tuple):
    r = color[0]
    g = color[1]
    b = color[2]
  return [r,g,b]

def interpolate24b(source, target, fade):
  return (int(M.interpolateLinear((source & 0xFF0000) >> 16, (target & 0xFF0000) >> 16, fade)) << 16) \
      + (int(M.interpolateLinear((source & 0x00FF00) >> 8, (target & 0x00FF00) >> 8, fade)) << 8) \
      + int(M.interpolateLinear((source & 0x0000FF), (target & 0x0000FF), fade))

def interpolateRgb(source, target, fade):
  source = source if source != None else target
  source = source if source != None else [0,0,0]
  target = target if target != None else source
  r = interpolateLinear(source[0], target[0], fade)
  g = interpolateLinear(source[1], target[1], fade)
  b = interpolateLinear(source[2], target[2], fade)
  return [r, g, b]

def interpolateLinear(source, target, fade):
  return math.floor(target + (source - target) * fade)

def interpolateFloat(source, target, fade):
  source = source if source != None else 0
  target = target if target != None else 0
  fade = fade if fade != None else 1
  return target + (source - target) * fade

def interpolate256(source, target, fade, prefer_color = False):
  source = source if type(source) == list else M.RGB_256[source]
  to = target if type(target) == list else M.RGB_256[target]
  r = 0
  g = 0
  b = 0
  if source == to:
    r = source[0]
    g = source[1]
    b = source[2]
  else:
    target = [math.floor(to[0]+(source[0]-to[0])*fade), math.floor(to[1]+(source[1]-to[1])*fade), math.floor(to[2]+(source[2]-to[2])*fade)]
    dir = (to[0]+to[1]+to[2]) / 3 - (source[0]+source[1]+source[2]) / 3
    i = -1
    rgb_result = [0,0,0]
    grey_result = [0,0,0]
    for v in target:
      i = i + 1
      j = 1
      while j < len(M.RGB_THRESHOLDS):
        if v > M.RGB_THRESHOLDS[j]:
          j = j + 1
        else:
          if v <= (M.RGB_THRESHOLDS[j]/2.5 + M.RGB_THRESHOLDS[j-1]/2):
            rgb_result[i] = j - 1 
          else:
            rgb_result[i] = j
          break
      j = 1
      while j < len(M.GREY_THRESHOLDS):
        if v > M.GREY_THRESHOLDS[j]:
          j = j+1
        else:
          if v < (M.GREY_THRESHOLDS[j]/2.5 + M.GREY_THRESHOLDS[j-1]/2):
            grey_result[i] = j - 1 
          else:
            grey_result[i] = j
          break
    r = rgb_result[0]
    g = rgb_result[1]
    b = rgb_result[2]
    r0 = target[0]
    g0 = target[1]
    b0 = target[2]
    thres = 25
    dir = -1 if (dir > thres) else 1
    if dir < 0:
      r += dir
      g += dir
      b += dir
    if r == g and g == b and r == b:
      if (r0 >= g0 or r0 >= b0) and (r0 <= g0 or r0 <= b0):
        if g0 - thres > r0: g = rgb_result[1]+dir
        if b0 - thres > r0: b = rgb_result[2]+dir
        if g0 + thres < r0: g = rgb_result[1]-dir
        if b0 + thres < r0: b = rgb_result[2]-dir
      elif (g0 >= r0 or g0 >= b0) and (g0 <= r0 or g0 <= b0):
        if r0 - thres > g0: r = rgb_result[0]+dir
        if b0 - thres > g0: b = rgb_result[2]+dir
        if r0 + thres < g0: r = rgb_result[0]-dir
        if b0 + thres < g0: b = rgb_result[2]-dir
      elif (b0 >= g0 or b0 >= r0) and (b0 <= g0 or b0 <= r0):
        if g0 - thres > b0: g = rgb_result[1]+dir
        if r0 - thres > b0: r = rgb_result[0]+dir
        if g0 + thres < b0: g = rgb_result[1]-dir
        if r0 + thres < b0: r = rgb_result[0]-dir
    if r < 1 or g < 1 or b < 1:
      r = r + 1
      g = g + 1
      b = b + 1
    if r == 7 or g == 7 or b == 7:
      r = r - 1
      g = g - 1
      b = b - 1
    r = min(max(r, 1), 6)
    g = min(max(g, 1), 6)
    b = min(max(b, 1), 6)
    r = M.RGB_THRESHOLDS[r]
    g = M.RGB_THRESHOLDS[g]
    b = M.RGB_THRESHOLDS[b]


    grey = max(grey_result[0], grey_result[1], grey_result[2])
    grey = min(max(grey, 1), len(M.GREY_THRESHOLDS)-2)
    grey = M.GREY_THRESHOLDS[grey]

    if abs(grey-r0) + abs(grey - g0) + abs(grey - b0) \
      < (abs(r-r0) + abs(g - g0) + abs(b - b0)) / (100 if prefer_color == True else 1.2):
      r = grey
      g = grey
      b = grey
  return M.LOOKUP_256_RGB['%d-%d-%d' % (r, g, b)]

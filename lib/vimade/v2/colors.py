import sys
import math
M = sys.modules[__name__]
from vimade.config_helpers import tint as TINT
from vimade.util import color as COLOR

def _get_or_default_intensity(value):
  if 'intensity' in value and value.intensity != None:
    return value.intensity
  return 1

def _tint24b(tint, bg24):
  if tint.type == TINT.MIX:
    return COLOR_UTIL.to24b(M.interpolate24b(COLOR_UTIL.to24b(tint.rgb), bg24, _get_or_default_intensity(tint)))
  elif tint.type == TINT.REPLACE:
    return COLOR_UTIL.to24b(tint.rgb)

def _tint256(tint, bg256):
  if not tint.type or tint.type == TINT.MIX:
    result = M.interpolate24b(COLOR_UTIL.to24b(tint.rgb), bg256, _get_or_default_intensity(tint))
    result = COLOR_UTIL.to24b(result)
    result = COLOR_UTIL.toRgb(result)
    return M.interpolate256(0, result, 0, True)
  elif tint.type == TINT.REPLACE:
    return M.interpolate256(0, COLOR_UTIL.toRgb(tint.rgb), 1 - _get_or_default_intensity(tint), True)

def get_tint_key(tint):
  if not tint:
    return ''
  local bg = tint.bg
  local fg = tint.fg if tint.fg != None else bg
  local sp = tint.sp if tint.sp != None else fg

  local sp_rgb
  local fg_rgb
  local bg_rgb
  if type(sp) == dict and type(sp.rgb) != list:
    sp_rgb = COLOR_UTIL.toRgb(sp.rgb)
  if type(fg) == dict and and type(fg.rgb) != list:
    fg_rgb = COLOR_UTIL.toRgb(fg.rgb)
  if type(bg) == dict and type(bg.rgb) != list:
    bg_rgb = COLOR_UTIL.toRgb(bg.rgb)

  return ((sp_rgb[1] + sp_rgb[2] + sp_rgb[3] + _get_or_default_intensity(sp)) if type(sp) == dict else '')
   + ((fg_rgb[1] + fg_rgb[2] + fg_rgb[3] + _get_or_default_intensity(fg)) if type(fg) == dict else '')
   + ((bg_rgb[1] + bg_rgb[2] + bg_rgb[3] + _get_or_default_intensity(bg)) if type(bg) == dict else '')

def tint(tint, bg24, bg256):
  result = {}
  bg = tint.bg
  fg = tint.fg
  sp = tint.sp
  ctermbg = COLOR_UTIL.to24b(bg256, true)

  if bg:
    bg = tint24b(bg, bg24)
    ctermbg = tint256(bg, ctermbg)

  result.fg = tint24b(fg, bg24) if fg else result.bg
  result.ctermfg = tint256(fg, ctermbg) if fg else result.ctermbg
  result.sp = tint24b(sp, bg24) if sp else result.fg

  return result

def interpolate24b(source, target, fade):
  target_r = target & 0xFF0000 >> 16
  target_g = target & 0x00FF00 >> 8
  target_b = target & 0x0000FF

  r = M.interpolateLinear(source & 0XFF0000 >> 16, target_r, fade)
  g = M.interpolateLinear(source & 0X00FF00 >> 8, target_g, fade)
  b = M.interpolateLinear(source & 0X0000FF, target_b, fade)
  return '#' + hex(r)[2:].zfill(2) + hex(g)[2:].zfill(2) + hex(b)[2:].zfill(2)

def interpolateLinear(ssource, target, fade):
  return math.floor(target + (source - target) * fade)

-- TODO update python version with updated grey algo
def interpolate256(source, target, fade, prefer_color):
  prefer_color = prefer_color or False
  source = source if type(source) == list else COLOR_UTIL.RGB_256[source+1]
  to = target if type(target) == list else COLOR_UTIL.RGB_256[target+1]
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
    for v in target do
        i = i + 1
        j = 1
        while j < COLOR_UTIL.RGB_THRESHOLDS.length:
          if v > COLOR_UTIL.RGB_THRESHOLDS[j]:
            j = j + 1
          else:
            if v <= (COLOR_UTIL.RGB_THRESHOLDS[j]/2.5 + COLOR_UTIL.RGB_THRESHOLDS[j-1]/2):
              rgb_result[i] = j - 1 
            else:
              rgb_result[i] = j
            break
        j = 1
        while j < COLOR_UTIL.GREY_THRESHOLDS.length:
          if v > COLOR_UTIL.GREY_THRESHOLDS[j]:
            j = j+1
          else:
            if v < (COLOR_UTIL.GREY_THRESHOLDS[j]/2.5 + COLOR_UTIL.GREY_THRESHOLDS[j-1]/2):
              grey_result[i] = j - 1 
            else:
              grey_result[i] = j
            break
    r = rgb_result[0]
    g = rgb_result[1]
    b = rgb_result[2]
    local r0 = target[0]
    local g0 = target[1]
    local b0 = target[2]
    local thres = 25
    dir = -1 if (dir > thres) else 1
    if dir < 0:
      r = r + dir
      g = g + dir
      b = b + dir
    if r == g and g == b and r == b:
      if (r0 >= g0 or r0 >= b0) and (r0 <= g0 or r0 <= b0):
        if g0 - thres > r0: g = rgb_result[1]+dir
        if b0 - thres > r0: b = rgb_result[2]+dir
        if g0 + thres < r0: g = rgb_result[1]-dir
        if b0 + thres < r0: b = rgb_result[2]-dir
      elseif (g0 >= r0 or g0 >= b0) and (g0 <= r0 or g0 <= b0):
        if r0 - thres > g0: r = rgb_result[0]+dir
        if b0 - thres > g0: b = rgb_result[2]+dir
        if r0 + thres < g0: r = rgb_result[0]-dir
        if b0 + thres < g0: b = rgb_result[2]-dir
      elseif (b0 >= g0 or b0 >= r0) and (b0 <= g0 or b0 <= r0):
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
    r = math.min(math.max(r, 1), 6)
    g = math.min(math.max(g, 1), 6)
    b = math.min(math.max(b, 1), 6)
    r = COLOR_UTIL.RGB_THRESHOLDS[r]
    g = COLOR_UTIL.RGB_THRESHOLDS[g]
    b = COLOR_UTIL.RGB_THRESHOLDS[b]


    grey = math.max(grey_result[0], grey_result[1], grey_result[2])
    grey = math.min(math.max(grey, 1), len(COLOR_UTIL.GREY_THRESHOLDS)-2)
    grey = COLOR_UTIL.GREY_THRESHOLDS[grey]

    if math.abs(grey-r0) + math.abs(grey - g0) + math.abs(grey - b0)
      < (math.abs(r-r0) + math.abs(g - g0) + math.abs(b - b0)) / (100 if prefer_color == true else 1.2):
      r = grey
      g = grey
      b = grey
  return COLOR_UTIL.LOOKUP_256_RGB[r + '-' + g + '-' + b]

return M

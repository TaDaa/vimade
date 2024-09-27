import sys
import math
M = sys.modules[__name__]

from vimade.v2.config_helpers import tint as TINT
from vimade.v2.state import globals as GLOBALS
from vimade.v2.util import color as COLOR_UTIL

def _get_or_default_intensity(tint):
  return tint.get('intensity', 1)

def _tint24b(tint, bg24):
  tint_type = tint.get('type', TINT.MIX)
  if tint_type == TINT.MIX:
    return COLOR_UTIL.to24b(M.interpolate24b(COLOR_UTIL.to24b(tint['rgb']), bg24, tint.get('intensity',1)))
  elif tint_type == TINT.REPLACE:
    return COLOR_UTIL.to24b(tint['rgb'])

def _tint256(tint, bg256):
  tint_type = tint.get('type', TINT.MIX)
  if tint_type == TINT.MIX:
    result = M.interpolate24b(COLOR_UTIL.to24b(tint['rgb']), bg256, tint.get('intensity', 1))
    result = COLOR_UTIL.to24b(result)
    result = COLOR_UTIL.toRgb(result)
    return M.interpolate256(0, result, 0, True)
  elif tint_type == TINT.REPLACE:
    return M.interpolate256(0, COLOR_UTIL.toRgb(tint['rgb']), 1 - tint.get('intensity', 1), True)

def get_tint_key(tint):
  if not tint:
    return ''
  bg = tint.get('bg')
  fg = tint.get('fg', bg)
  sp = tint.get('sp', fg)

  sp_rgb = fg_rgb = bg_rgb = None
  if type(sp) == dict and type(sp['rgb']) == list:
    sp_rgb = COLOR_UTIL.toRgb(sp['rgb'])
  if type(fg) == dict and type(fg['rgb']) == list:
    fg_rgb = COLOR_UTIL.toRgb(fg['rgb'])
  if type(bg) == dict and type(bg['rgb']) == list:
    bg_rgb = COLOR_UTIL.toRgb(bg['rgb'])

  return ''.join([
    ''.join(map(str, sp_rgb)) + str(sp.get('intensity', 1)) if sp_rgb else '',
    ''.join(map(str, fg_rgb)) + str(fg.get('intensity', 1)) if fg_rgb else '',
    ''.join(map(str, bg_rgb)) + str(bg.get('intensity', 1)) if bg_rgb else ''])

def convertHi(hi, default = [None, None, None, None, None]):
  if GLOBALS.is_nvim:
    hi = [default[i] if int(x) == -1 else int(x) for i, x in enumerate(hi)]
  else:
    if hi[0] and hi[0][0] == '#' or hi[1] and hi[1][0] == '#' or hi[2] and hi[2][0] == '#':
      hi = [default[0], default[1]] + [int(a[1:], 16) if a else default[i+2] for i,a in enumerate(hi)]
    else:
      hi = [int(a) if a else default[i] for i,a in enumerate(hi[0:2])] + [default[2], default[3], default[4]]
  return hi

def tint(tint, bg24, bg256):
  result = {}
  bg = tint.get('bg')
  fg = tint.get('fg')
  sp = tint.get('sp')
  ctermbg = COLOR_UTIL.to24b(bg256, True)

  result['bg'] = _tint24b(bg, bg24) if bg else None
  result['ctermbg'] = _tint256(bg, bg24) if bg else None
  result['fg'] = _tint24b(fg, bg24) if fg else result['bg']
  result['ctermfg'] = _tint256(fg, ctermbg) if fg else result['ctermbg']
  result['sp'] = _tint24b(sp, bg24) if sp else result['fg']

  return result

def interpolate24b(source, target, fade):
  return '#' + ''.join(
    map(lambda c: c[2:].zfill(2), map(hex, map(int,(
      M.interpolateLinear((source & 0XFF0000) >> 16, (target & 0xFF0000) >> 16, fade),
      M.interpolateLinear((source & 0X00FF00) >> 8, (target & 0x00FF00) >> 8, fade),
      M.interpolateLinear((source & 0X0000FF), (target & 0x0000FF), fade))))))

def interpolateLinear(source, target, fade):
  return math.floor(target + (source - target) * fade)

def interpolate256(source, target, fade, prefer_color = False):
  source = source if type(source) == list else COLOR_UTIL.RGB_256[source]
  to = target if type(target) == list else COLOR_UTIL.RGB_256[target]
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
      while j < len(COLOR_UTIL.RGB_THRESHOLDS):
        if v > COLOR_UTIL.RGB_THRESHOLDS[j]:
          j = j + 1
        else:
          if v <= (COLOR_UTIL.RGB_THRESHOLDS[j]/2.5 + COLOR_UTIL.RGB_THRESHOLDS[j-1]/2):
            rgb_result[i] = j - 1 
          else:
            rgb_result[i] = j
          break
      j = 1
      while j < len(COLOR_UTIL.GREY_THRESHOLDS):
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
    r0 = target[0]
    g0 = target[1]
    b0 = target[2]
    thres = 25
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
    r = COLOR_UTIL.RGB_THRESHOLDS[r]
    g = COLOR_UTIL.RGB_THRESHOLDS[g]
    b = COLOR_UTIL.RGB_THRESHOLDS[b]


    grey = max(grey_result[0], grey_result[1], grey_result[2])
    grey = min(max(grey, 1), len(COLOR_UTIL.GREY_THRESHOLDS)-2)
    grey = COLOR_UTIL.GREY_THRESHOLDS[grey]

    if abs(grey-r0) + abs(grey - g0) + abs(grey - b0) \
      < (abs(r-r0) + abs(g - g0) + abs(b - b0)) / (100 if prefer_color == True else 1.2):
      r = grey
      g = grey
      b = grey
  return COLOR_UTIL.LOOKUP_256_RGB['%d-%d-%d' % (r, g, b)]

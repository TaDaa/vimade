import math
import vim
from vimade.legacy.term_256 import RGB_256, LOOKUP_256_RGB
from vimade.legacy import util
(is_nvim, normal_id) = util.eval_and_return('[has("nvim"), hlID("Normal")]')
is_nvim = int(is_nvim)

def fromHexStringToRGB(source):
  return [int(source[1:3], 16), int(source[3:5], 16), int(source[5:7], 16)]
def fromRGBToHexString(source):
  return '#' + ''.join([(x if len(x) > 1 else ('0' + x)) for x in [(hex(int(x))[2:]) for x in source]])
def from256ToRGB(source):
  return RGB_256[source]
def from256RGBToHexString(source):
  return fromRGBToHexString(from256ToRGB(source))
def fromAnyToRGB(source):
    if isinstance(source, list):
      source = [int(x) for x in source]
    elif (isinstance(source, int) or source.isdigit()) and int(source) < len(RGB_256):
      source = from256ToRGB(int(source))
    elif len(source) == 7:
      source = fromHexStringToRGB(source)
    return source

def getHi(id):
  if is_nvim:
    if id == '0' or not id:
      id = normal_id
    hi = list(map(lambda x: '' if x == '-1' else int(x), util.eval_and_return('vimade#GetNvimHi('+id+')')))
    if hi[2] != '':
      hi[2] = '#' +hex(hi[2])[2:].zfill(6)
    if hi[3] != '':
      hi[3] = '#' +hex(hi[3])[2:].zfill(6)
    if hi[4] != '':
      hi[4] = '#' +hex(hi[4])[2:].zfill(6)
  else:
    hi = util.eval_and_return('vimade#GetHi('+id+')')
    if hi[0] and hi[0][0] == '#' or hi[1] and hi[1][0] == '#':
      hi = ['', ''] + hi
    else:
      hi = hi + ['', '', '']
  return hi

def interpolate24b(source, to, fade_level):
    if not isinstance(source, list):
      source = [int(source[1:3], 16), int(source[3:5], 16), int(source[5:7], 16)]
    if not isinstance(to, list):
      to = [int(to[1:3], 16), int(to[3:5], 16), int(to[5:7], 16)]
    if source != to:
      r = hex(int(math.floor(to[0]+(source[0]-to[0])*fade_level)))[2:]
      g = hex(int(math.floor(to[1]+(source[1]-to[1])*fade_level)))[2:]
      b = hex(int(math.floor(to[2]+(source[2]-to[2])*fade_level)))[2:]
    else:
      r = hex(to[0])[2:]
      g = hex(to[1])[2:]
      b = hex(to[2])[2:]

    if len(r) < 2:
      r = '0' + r
    if len(g) < 2:
      g = '0' + g
    if len(b) < 2:
      b = '0' + b

    return '#' + r + g + b

#this algorithm is better at preserving color
#TODO we need to handle grays better
rgb_thresholds = [-1,0, 95, 135, 175, 215, 255, 256]
grey_thresholds = [-1, 8, 18, 28, 38, 48, 58, 68, 78, 88, 98, 108, 118, 128, 138, 148, 158, 168, 178, 188, 198, 208, 218, 228, 238, 258]
grey_thresholds_target_ln = len(grey_thresholds) - 2
def interpolate256(source, to, fade_level):
  if not isinstance(source, list):
    source = RGB_256[int(source)]
  if not isinstance(to, list):
    to = RGB_256[int(to)]
  if source != to:
    rgb = [int(math.floor(to[0]+(source[0]-to[0])*fade_level)), int(math.floor(to[1]+(source[1]-to[1])*fade_level)), int(math.floor(to[2]+(source[2]-to[2])*fade_level))]
    dir = (to[0]+to[1]+to[2]) / 3 - (source[0]+source[1]+source[2]) / 3

    i = -1
    rgb_result = [0,0,0]
    grey_result = [0,0,0]
    for v in rgb: 
      i += 1
      j = 1
      while j < len(rgb_thresholds) - 1:
        if v > rgb_thresholds[j]:
          j += 1
          continue
        if v < (rgb_thresholds[j]/2.5 + rgb_thresholds[j-1]/2):
          rgb_result[i] = j - 1
        else:
          rgb_result[i] = j
        break
      j = 1
      while j < len(grey_thresholds) - 1:
        if v > grey_thresholds[j]:
          j += 1
          continue
        if v < (grey_thresholds[j]/2.5 + grey_thresholds[j-1]/2):
          grey_result[i] = j - 1
        else:
          grey_result[i] = j
        break

    r = rgb_result[0]
    g = rgb_result[1]
    b = rgb_result[2]
    r0 = rgb[0]
    g0 = rgb[1]
    b0 = rgb[2]
    thres = 25
    dir = -1 if dir > thres  else 1
    if dir < 0:
      r += dir
      g += dir
      b += dir

    #color fix
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

    r = rgb_thresholds[r]
    g = rgb_thresholds[g]
    b = rgb_thresholds[b]
    grey = max(grey_result[0], grey_result[1], grey_result[2])
    grey = min(max(grey, 1), grey_thresholds_target_ln)
    grey = grey_thresholds[grey]
    if abs(grey-r0) + abs(grey - g0) + abs(grey - b0) < (abs(r-r0) + abs(g - g0) + abs(b - b0)) / 1.2:
      r = grey
      g = grey
      b = grey
  else:
    r = source[0]
    g = source[1]
    b = source[2]

  key = str(r) + '-' + str(g) + '-' + str(b)
  return str(LOOKUP_256_RGB[key])

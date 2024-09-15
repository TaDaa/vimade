import sys
M = sys.modules[__name__]

M.RGB_256 = [[0,0,0],[128,0,0],[0,128,0],[128,128,0],[0,0,128],[128,0,128],[0,128,128],[192,192,192],[128,128,128],[255,0,0],[0,255,0],[255,255,0],[0,0,255],[255,0,255],[0,255,255],[255,255,255],[0,0,0],[0,0,95],[0,0,135],[0,0,175],[0,0,215],[0,0,255],[0,95,0],[0,95,95],[0,95,135],[0,95,175],[0,95,215],[0,95,255],[0,135,0],[0,135,95],[0,135,135],[0,135,175],[0,135,215],[0,135,255],[0,175,0],[0,175,95],[0,175,135],[0,175,175],[0,175,215],[0,175,255],[0,215,0],[0,215,95],[0,215,135],[0,215,175],[0,215,215],[0,215,255],[0,255,0],[0,255,95],[0,255,135],[0,255,175],[0,255,215],[0,255,255],[95,0,0],[95,0,95],[95,0,135],[95,0,175],[95,0,215],[95,0,255],[95,95,0],[95,95,95],[95,95,135],[95,95,175],[95,95,215],[95,95,255],[95,135,0],[95,135,95],[95,135,135],[95,135,175],[95,135,215],[95,135,255],[95,175,0],[95,175,95],[95,175,135],[95,175,175],[95,175,215],[95,175,255],[95,215,0],[95,215,95],[95,215,135],[95,215,175],[95,215,215],[95,215,255],[95,255,0],[95,255,95],[95,255,135],[95,255,175],[95,255,215],[95,255,255],[135,0,0],[135,0,95],[135,0,135],[135,0,175],[135,0,215],[135,0,255],[135,95,0],[135,95,95],[135,95,135],[135,95,175],[135,95,215],[135,95,255],[135,135,0],[135,135,95],[135,135,135],[135,135,175],[135,135,215],[135,135,255],[135,175,0],[135,175,95],[135,175,135],[135,175,175],[135,175,215],[135,175,255],[135,215,0],[135,215,95],[135,215,135],[135,215,175],[135,215,215],[135,215,255],[135,255,0],[135,255,95],[135,255,135],[135,255,175],[135,255,215],[135,255,255],[175,0,0],[175,0,95],[175,0,135],[175,0,175],[175,0,215],[175,0,255],[175,95,0],[175,95,95],[175,95,135],[175,95,175],[175,95,215],[175,95,255],[175,135,0],[175,135,95],[175,135,135],[175,135,175],[175,135,215],[175,135,255],[175,175,0],[175,175,95],[175,175,135],[175,175,175],[175,175,215],[175,175,255],[175,215,0],[175,215,95],[175,215,135],[175,215,175],[175,215,215],[175,215,255],[175,255,0],[175,255,95],[175,255,135],[175,255,175],[175,255,215],[175,255,255],[215,0,0],[215,0,95],[215,0,135],[215,0,175],[215,0,215],[215,0,255],[215,95,0],[215,95,95],[215,95,135],[215,95,175],[215,95,215],[215,95,255],[215,135,0],[215,135,95],[215,135,135],[215,135,175],[215,135,215],[215,135,255],[215,175,0],[215,175,95],[215,175,135],[215,175,175],[215,175,215],[215,175,255],[215,215,0],[215,215,95],[215,215,135],[215,215,175],[215,215,215],[215,215,255],[215,255,0],[215,255,95],[215,255,135],[215,255,175],[215,255,215],[215,255,255],[255,0,0],[255,0,95],[255,0,135],[255,0,175],[255,0,215],[255,0,255],[255,95,0],[255,95,95],[255,95,135],[255,95,175],[255,95,215],[255,95,255],[255,135,0],[255,135,95],[255,135,135],[255,135,175],[255,135,215],[255,135,255],[255,175,0],[255,175,95],[255,175,135],[255,175,175],[255,175,215],[255,175,255],[255,215,0],[255,215,95],[255,215,135],[255,215,175],[255,215,215],[255,215,255],[255,255,0],[255,255,95],[255,255,135],[255,255,175],[255,255,215],[255,255,255],[8,8,8],[18,18,18],[28,28,28],[38,38,38],[48,48,48],[58,58,58],[68,68,68],[78,78,78],[88,88,88],[98,98,98],[108,108,108],[118,118,118],[128,128,128],[138,138,138],[148,148,148],[158,158,158],[168,168,168],[178,178,178],[188,188,188],[198,198,198],[208,208,208],[218,218,218],[228,228,228],[238,238,238]]
M.RGB_THRESHOLDS = [-1, 0, 95, 135, 175, 215, 255, 256]
M.GREY_THRESHOLDS = [-1, 8, 18, 28, 38, 48, 58, 68, 78, 88, 98, 108, 118, 128, 138, 148, 158, 168, 178, 188, 198, 208, 218, 228, 238, 258]
M.LOOKUP_256_RGB = {}
for i,rgb in enumerate(M.RGB_256):
  M.LOOKUP_256_RGB['%d-%d-%d' % (rgb[0], rgb[1], rgb[2])] = i

def to24b(color, is256 = False):
  r = 0
  g = 0
  b = 0

  if is256 and type(color) == int:
    color = M.RGB_256[color] or M.RGB_256[0]

  if type(color) == list:
    r = int(color[0]) or 0
    g = int(color[1]) or 0
    b = int(color[2]) or 0
    result = '0x' + hex(r)[2:].zfill(2) + '' + hex(g)[2:].zfill(2) + '' + hex(b)[2:].zfill(2)
    return int(result, 16) or 0
  elif type(color) == str and color[0] == '#':
    color = '0x' + color[1:]
    return int(color, 16) or 0
  else:
    return int(color or 0)

def toRgb(color, is256 = False):
  r = 0
  g = 0
  b = 0

  if type(color) == str and color[0] == '#':
    color = int('0x'+color[1:], 16) or 0
  if type(color) == int:
    if is256:
     color = M.RGB_256[color] or M.RGB_256[0]
    else:
      r = (color & 0xFF0000) >> 16
      g = (color & 0x00FF00) >> 8
      b = (color & 0x0000FF)
  if type(color) == list:
    r = color[0]
    g = color[1]
    b = color[2]
  return [r,g,b]

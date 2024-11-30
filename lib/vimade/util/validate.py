from vimade.util import color as COLOR_UTIL

def range(value, min_value, max_value, default = 0):
  if type(value) not in (int, float):
    try:
      value = float(value)
    except:
      return default
  return min(max(value, min_value), max_value)

def fade(value):
  result = range(value, 0, 1, 0.4)
  return result

def intensity(value):
  return range(value, 0, 1, 1)

def rgb(value):
  if type(value) not in (list, tuple) or len(value) < 3:
    return None
  return [
    range(value[0], 0, 255, 0),
    range(value[1], 0, 255, 0),
    range(value[2], 0, 255, 0)]

def color(value, is256 = False):
  if type(value) in (list, tuple):
    return rgb(value)
  if type(value) == str:
    value = COLOR_UTIL.to24b(value)
  if is256:
    return range(value, 0, 255, 0)
  else:
    return range(value, 0, 0xFFFFFF, 0)

def tint_attr(value):
  if type(value) != dict:
    return None
  rgb = value.get('rgb')
  intensity_value = value.get('intensity')
  if rgb != None:
    value['rgb'] = rgb = color(rgb)
    if type(rgb) != list:
      value['rgb'] = COLOR_UTIL.toRgb(rgb)
    value['intensity'] = intensity(intensity_value)
  elif intensity_value != None:
    value['intensity'] = intensity(intensity_value)
  return value

def tint(value):
  if type(value) != dict:
    return None
  for (k, v) in list(value.items()):
    if k not in ('fg', 'bg', 'sp'):
      del value[k]
    else:
      attr = tint_attr(v)
      if attr == None:
        del value[k]
      else:
        value[k] = attr
  return value
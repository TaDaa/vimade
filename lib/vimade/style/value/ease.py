import math

def LINEAR(t):
  return t
def IN_SINE(t):
  return 1 - math.cos((t * math.pi) / 2.0)
def OUT_SINE(t):
  return math.sin((t * math.pi) / 2.0)
def IN_OUT_SINE(t):
  return -(math.cos(math.pi*t) - 1) / 2.0
def IN_QUAD(t):
  return t * t
def OUT_QUAD(t):
  return 1 - (1 - t) * (1 - t)
def IN_OUT_QUAD(t):
  if t < 0.5:
    return 2 * t * t 
  else:
    return 1 - math.pow((-2 * t + 2), 2) / 2.0
def IN_CUBIC(t):
  return t * t * t
def OUT_CUBIC(t):
  return 1 - math.pow(1 - t, 3)
def IN_OUT_CUBIC(t):
  if t < 0.5:
    return 4 * t * t * t
  else:
    return 1 - math.pow(-2 * t + 2, 3) / 3.0
def IN_QUART(t):
  return t * t * t * t
def OUT_QUART(t):
  return 1 - math.pow(1 - t, 4)
def IN_OUT_QUART(t):
  if t < 0.5:
    return 8 * t * t * t * t
  else:
    return 1 - math.pow(-2 * t + 2, 4) / 2.0
def IN_EXPO(t):
  if t == 0:
    return 0
  else:
    return math.pow(2, 10 * t - 10)
def OUT_EXPO(t):
  if t == 1:
    return 1
  else:
    return 1 - math.pow(2, -10 * t)
def IN_OUT_EXPO(t):
  if t == 0 or t == 1:
    return t
  elif t < 0.5:
    return math.pow(2, 20 * t - 10) / 2.0
  else:
    return (2 - math.pow(2, -20 * t + 10)) / 2.0
def IN_CIRC(t):
  return 1 - math.sqrt(1 - t * t)
def OUT_CIRC(t):
  return math.sqrt(1 - math.pow(t - 1, 2))
def IN_OUT_CIRC(t):
  if t < 0.5:
    return (1 - math.sqrt(1 - math.pow(2 * t, 2))) / 2.0
  else:
    return (math.sqrt(1 - math.pow(-2 * t + 2, 2)) + 1) / 2.0
def IN_BACK(t):
  return 2.70158 * t * t * t - 1.70158 * t * t
def OUT_BACK(t):
  return 1 + 2.70158 * math.pow(t - 1, 3) + 1.70158 * math.pow(t - 1, 2)
def IN_OUT_BACK(t):
  c1 = 1.70158;
  c2 = c1 * 1.525;
  if t < 0.5:
    return (math.pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2.0
  else:
    return (math.pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2.0;
def OUT_BOUNCE(t):
  if t < 1 / 2.75:
    return 7.5625 * t * t
  elif t < 2 / 2.75:
    t = t - 1.5 / 2.75
    return 7.5625 * t * t + 0.75
  elif t < 2.5 / 2.75:
    t = t - 2.25 / 2.75
    return 7.5625 * t * t + 0.9375
  else:
    t = t - 2.625 / 2.75
    return 7.5625 * t * t + 0.984375
def IN_BOUNCE(t):
  return 1 - OUT_BOUNCE(1 - t)
def IN_OUT_BOUNCE(t):
  if t < 0.5:
    return (1 - M.OUT_BOUNCE(1 - 2 * t)) / 2.0
  else:
    return (1 + M.OUT_BOUNCE(2 * t - 1)) / 2.0

local M = {}
M.LINEAR = function (t)
  return t
end
M.IN_SINE = function (t)
  return 1 - math.cos((t * math.pi) / 2)
end
M.OUT_SINE = function (t)
  return math.sin((t * math.pi) / 2)
end
M.IN_OUT_SINE = function (t)
  return -(math.cos(math.pi*t) - 1) / 2
end
M.IN_QUAD = function (t)
  return t * t
end
M.OUT_QUAD = function (t)
  return 1 - (1 - t) * (1 - t)
end
M.IN_OUT_QUAD = function (t)
  if t < 0.5 then
    return 2 * t * t 
  else
    return 1 - ((-2 * t + 2) ^ 2) / 2
  end
end
M.IN_CUBIC = function (t)
  return t * t * t
end
M.OUT_CUBIC = function (t)
  return 1 - (1 - t) ^ 3
end
M.IN_OUT_CUBIC = function (t)
  if t < 0.5 then
    return 4 * t * t * t
  else
    return 1 - ((-2 * t + 2) ^ 3) / 3
  end
end
M.IN_QUART = function (t)
  return t * t * t * t
end
M.OUT_QUART = function (t)
  return 1 - (1 - t) ^ 4
end
M.IN_OUT_QUART = function (t)
  if t < 0.5 then
    return 8 * t * t * t * t
  else
    return 1 - ((-2 * t + 2) ^ 4) / 2
  end
end
M.IN_EXPO = function (t)
  if t == 0 then
    return 0
  else
    return (2 ^ (10 * t - 10))
  end
end
M.OUT_EXPO = function (t)
  if t == 1 then
    return 1
  else
    return 1 - (2 ^ (-10 * t))
  end
end
M.IN_OUT_EXPO = function (t)
  if t == 0 or t == 1 then
    return t
  elseif t < 0.5 then
    return (2 ^ (20 * t - 10)) / 2
  else
    return (2 - (2 ^ (-20 * t + 10))) / 2
  end
end
M.IN_CIRC = function (t)
  return 1 - math.sqrt(1 - t ^ 2)
end
M.OUT_CIRC = function (t)
  return math.sqrt(1 - (t - 1) ^ 2)
end
M.IN_OUT_CIRC = function (t)
  if t < 0.5 then
    return (1 - math.sqrt(1 - (2 * t) ^ 2)) / 2
  else
    return (math.sqrt(1 - (-2 * t + 2) ^ 2) + 1) / 2
  end
end
M.IN_BACK = function (t)
  return 2.70158 * t * t * t - 1.70158 * t * t
end
M.OUT_BACK = function (t)
  return 1 + 2.70158 * ((t - 1) ^ 3) + 1.70158 * ((t - 1) ^ 2)
end
M.IN_OUT_BACK = function (t)
  local c1 = 1.70158;
  local c2 = c1 * 1.525;
  if t < 0.5 then
    return (((2 * t) ^ 2) * ((c2 + 1) * 2 * t - c2)) / 2
  else
    return (((2 * t - 2) ^ 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2;
  end
end
M.OUT_BOUNCE = function(t)
  if t < 1 / 2.75 then
    return 7.5625 * t * t
  elseif t < 2 / 2.75 then
    t = t - 1.5 / 2.75
    return 7.5625 * t * t + 0.75
  elseif t < 2.5 / 2.75 then
    t = t - 2.25 / 2.75
    return 7.5625 * t * t + 0.9375
  else
    t = t - 2.625 / 2.75
    return 7.5625 * t * t + 0.984375
  end
end
M.IN_BOUNCE = function(t)
  return 1 - M.OUT_BOUNCE(1 - t)
end
M.IN_OUT_BOUNCE = function(t)
  if t < 0.5 then
    return (1 - M.OUT_BOUNCE(1 - 2 * t)) / 2
  else
    return (1 + M.OUT_BOUNCE(2 * t - 1)) / 2
  end
end

return M

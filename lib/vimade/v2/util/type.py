def deep_copy(obj):
  # disallow tuple
  if type(obj) in (list, tuple):
    return [deep_copy(v) for v in obj]
  elif type(obj) == dict:
    result = {}
    for key, value in obj.items():
      result[key] = deep_copy(value)
    return result
  else:
    return obj

def shallow_extend(base, target):
  if type(target) == dict: 
    for key, value in target.items():
      base[key] = value
  return base

def deep_extend(base, target):
  base = deep_copy(base)
  target = deep_copy(target)
  return shallow_extend(base, target)

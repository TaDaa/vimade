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

def shallow_copy(obj):
  return shallow_extend({}, obj)

def shallow_extend(base, *args):
  for target in args:
    if type(target) == dict: 
      for key, value in target.items():
        base[key] = value
  return base
extend = shallow_extend

def deep_extend(base, *args):
  base = deep_copy(base)
  for target in args:
    target = deep_copy(target)
    shallow_extend(base, target)
  return base

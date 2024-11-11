def get(obj, key):
  if type(obj) == dict:
    return obj.get(key)
  elif type(obj) == list:
    if key < len(obj):
      return obj(key)
  return None

def pairs(obj):
  if type(obj) == dict:
    return obj.items()
  elif type(obj) in (list, tuple):
    return enumerate(obj)
  return enumerate([])

def shallow_compare(left, right):
  if left == None or right == None:
    return left == right
  for k, v in pairs(left):
    if get(right, k) != v:
      return False
  for k, v in pairs(right):
    if get(left, k) != v:
      return False
  return True

def deep_compare(left, right):
  if left == None or right == None:
    return left == right
  copy ={}
  for key, value in pairs(left):
    copy[key] = value
  for key, value in pairs(right):
    copy_value = get(copy, key)
    if copy_value == None:
      return False
    elif type(copy_value) != type(value):
      return False
    elif type(value) in (dict, list, tuple):
      if deep_compare(copy_value, value) == True:
        del copy[key]
      else:
        return False
    elif copy_value == value:
      del copy[key]
    else:
      return False
  if len(copy.keys()) > 0:
    return False
  return True

  for k, v in pairs(left):
    if get(right, k) != v:
      return False
  for k, v in pairs(right):
    if get(left, k) != v:
      return False
    

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

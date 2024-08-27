import sys
M = sys.modules[__name__]

def _pairs(input):
  if type(input) == list:
    return enumerate(list)
  elif type(input) == dict:
    return input.items()

def match_contains_any(target, value):
  if type(target) in (list, dict) and type(value) in (list, dict):
    return M.match_table_any(target, value)
  elif type(target) in (list, dict):
    for i, v in _pairs(target):
      if M.match_contains_any(v, value):
        return True
  else:
    return M.match_primitive(target, value)

def match_table_any(target, value):
  for target_key, target_value in _pairs(target):
    if type(target_key) == int:
      for real_key, real_value in _pairs(value):
        if M.match_contains_any(target_value, real_value):
          return True
    else:
      if M.match_contains_any(target_value, value.get(target_key), M.match_table_any):
        return True
  return False
  

def each_match_contains_any(target, values):
  count_ln = len(values)
  counts = {}
  for i, value in _pairs(values):
    if M._each_match_contains_any(target, value, counts, count_ln, i) == True:
      return True

def _each_match_contains_any(target, value, counts, counts_ln, i):
  for key, t in _pairs(target):
    counts[key] = counts.get(key, {'count': 0})
    found = False
    if type(key) == int:
      if callable(t) and type(value) in (list, dict):
        for j, v in _pairs(value):
          if t(v) == True:
            found = True
      elif type(t) in (list, dict) and type(value) in (list, dict):
        for j, v in _pairs(value):
          if M._each_match_contains_any(t, v, counts[key], counts_ln, i):
            return True
      elif type(value) in (list, dict):
        for j, v in _pairs(value):
          if M.match_primitive(t, v):
            found = True
      elif M.match_primitive(t, value):
        found = True
    else:
      if callable(t) and type(value) in (list, dict):
        if t(value[key]) == True:
          found = True
      elif type(t) in list_dict and type(value) in (list, dict):
        if M._each_match_contains_any(t, value.get(key), counts[key], counts_ln, i):
          found = True
      elif type(value) in (list, dict):
        if M.match_primitive(t, value.get(key)):
          found = True
      elif M.match_primitive(t, value):
        found = True
    if found and counts[key].count == i - 1:
      counts[key].count = i
    if counts[key].count == counts_ln:
      return True
  return False


def match_contains_all(target, value):
  return M.each_match_contains_all(target, [value])

def match_table_all(target, value):
  for target_key, target_value in _pairs(target):
    found = False
    if type(target_key) == int:
      # numbers are skipped as this is listy
      # we assume things can be out of order here, so every
      # item must be checked
      for real_key, real_value in _pairs(value):
        if callable(target_value):
          found = target_value(real_value)
        elif type(target_value) in (list, dict) and type(real_value) in (list, dict):
          found = M.match_table_all(target_value, real_value)
        else:
          found = M.match_contains_any(target_value, real_value)
     else:
       if callable(target_value):
          found = target_value(value.get(target_key))
        elif type(target_value) in (list, dict) and type(value.get(target_key)) in (list, dict):
          found = M.match_table_all(target_value, value.get(target_key))
        else:
          # outer compare
          found = M.match_contains(target_value, value.get(target_key))
     # we don't care if the value has other keys, this is left match
     if not found:
       return False
  return True

def each_match_contains_all(target, values):
  # every target must contain every value
  for i, value in _pairs(values):
    found = None
    # second is the target and value a table?
    # If yes, continue the recursion step
    if type(target) in (list, dict) and type(value) in (list, dict):
      found = M.match_table_all(target, value)
    # otherwise outer compare the target to a real value
    # from here on out
    elif type(target) in (list, dict):
      for i, v in _pairs(target):
        if not M.match_contains_all(v, value):
          found = false
          break
    else:
      found = M.match_primitive(target, value)
    if found == False:
      return False

def match_primitive(target, value):
  if callable(target):
    return target(value)
  elif type(target) == bool:
    if target:
      return M.match_truthy(value)
    else
      return M.match_falsy(value)
  elif (type(target) in (int, float, str))
    and (type(value) in (int, float, str)):
      return target + '' == value + ''
  else:
    return target == value

def match_truthy(value):
  return (value != None and value != '' and value != False and value != 0) and True or False

def match_falsy(value):
  return value != None and (value == '' or value == False or value == 0) and True or False

def match_contains_string(target, value):
  if target == None:
    return False
  # custom function
  elif callable(target):
    return target(value)
  # target is a string, we do the comparison
  elif type(target) == str:
    return M.match_string(target, value)
  # target is a table, we need to see if value is within the table
  elif type(target) == list or type(target) == dict:
    for i,v in _pairs(target):
      if M.match_contains_string(v, value):
        return True
   return False

def match_string(target, value):
  return (value+'').lower() in (target+'').lower()

def ContainsString(target):
  if type(target) == dict:
    def _ContainsString(value):
      return M.match_contains_string(target, value)
    return _ContainsString
  else:
    def _ContainsString(value):
      return M.match_string(target, value)
    return _ContainsString

def ContainsAll(target):
  def _ContainsAll(value):
    return M.match_contains_all(target, value)
  return _ContainsAll

def EachContainsAll(target):
  def _EachContainsAll(value):
    return M.each_match_contains_all(target, value)
  return _EachContainsAll

def ContainsAny(target):
  def _ContainsAny(value):
    return M.match_contains_any(target, value)
  return _ContainsAny

def EachContainsAny(target):
  def _EachContainsAny(values):
    return M.each_match_contains_any(target, values)
  return _EachContainsAny

def IsFalsy(target):
  def _IsFalsy(value):
    return M.match_falsy(value)
  return _IsFalsy

def IsTruthy(target):
  def _IsTruthy(value):
    return M.match_truthy(value)
  return _IsTruthy

def StringMatcher(target):
  def _StringMatcher(value):
    if type(target) in (list, dict):
      return M.match_contains_string(target, value)
    elif type(target) == str:
      return M.match_string(target, value)
    return False
  return _StringMatcher

import sys
import vim
M = sys.modules[__name__]

TYPE_VARS = type(vim.vars) # handle vim and nvim remote objects
TYPE_OPTS = type(vim.options) # handle vim and nvim remote objects
DICTIONARY_LIKE_TYPES = (list, dict, TYPE_VARS, TYPE_OPTS)

def _safe_get(value, key):
  if type(value) == list:
    if type(key) == int and key < len(value):
      return value[key]
  elif type(value) == dict:
    return value.get(key)
  elif type(value) == TYPE_VARS:
    return value.get(key)
  elif type(value) == TYPE_OPTS:
    if key in value:
      return value[key]
  return None

def _pairs(input):
  if type(input) == list:
    return enumerate(input)
  elif type(input) == dict:
    return input.items()

def match_contains_any(target, value):
  if type(target) in DICTIONARY_LIKE_TYPES and (type(value) in DICTIONARY_LIKE_TYPES):
    return M.match_table_any(target, value)
  elif type(target) in DICTIONARY_LIKE_TYPES:
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
      if M.match_contains_any(target_value, _safe_get(value, target_key)):
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
      if callable(t) and type(value) in DICTIONARY_LIKE_TYPES:
        for j, v in _pairs(value):
          if t(v) == True:
            found = True
      elif type(t) in DICTIONARY_LIKE_TYPES and type(value) in DICTIONARY_LIKE_TYPES:
        for j, v in _pairs(value):
          if M._each_match_contains_any(t, v, counts[key], counts_ln, i):
            return True
      elif type(value) in DICTIONARY_LIKE_TYPES:
        for j, v in _pairs(value):
          if M.match_primitive(t, v):
            found = True
      elif M.match_primitive(t, value):
        found = True
    else:
      if callable(t) and type(value) in DICTIONARY_LIKE_TYPES:
        if t(value[key]) == True:
          found = True
      elif type(t) in DICTIONARY_LIKE_TYPES and type(value) in DICTIONARY_LIKE_TYPES:
        if M._each_match_contains_any(t, _safe_get(value, key), counts[key], counts_ln, i):
          found = True
      elif type(value) in DICTIONARY_LIKE_TYPES:
        if M.match_primitive(t, _safe_get(value, key)):
          found = True
      elif M.match_primitive(t, value):
        found = True
    if found and counts[key]['count'] == i:
      counts[key]['count'] = i + 1
    if counts[key]['count'] == counts_ln:
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
        elif type(target_value) in DICTIONARY_LIKE_TYPES and type(real_value) in DICTIONARY_LIKE_TYPES:
          found = M.match_table_all(target_value, real_value)
        else:
          found = M.match_contains_any(target_value, real_value)
    else:
      if callable(target_value):
        found = target_value(_safe_get(value, target_key))
      elif type(target_value) in DICTIONARY_LIKE_TYPES and type(_safe_get(value, target_key)) in DICTIONARY_LIKE_TYPES:
        found = M.match_table_all(target_value, _safe_get(value, target_key))
      else:
        # outer compare
        found = M.match_contains(target_value, _safe_get(value, target_key))
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
    if type(target) in DICTIONARY_LIKE_TYPES and type(value) in DICTIONARY_LIKE_TYPES:
      found = M.match_table_all(target, value)
    # otherwise outer compare the target to a real value
    # from here on out
    elif type(target) in DICTIONARY_LIKE_TYPES:
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
    else:
      return M.match_falsy(value)
  elif (type(target) in (int, float, str)) and (type(value) in (int, float, str)):
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
    if type(target) in DICTIONARY_LIKE_TYPES:
      return M.match_contains_string(target, value)
    elif type(target) == str:
      return M.match_string(target, value)
    return False
  return _StringMatcher

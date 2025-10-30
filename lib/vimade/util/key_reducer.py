import math

FLOOR = math.floor
KEYS = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z']
TOTAL_KEYS = len(KEYS)

class KeyReducer():
  def __init__(self):
    self._id = 1
    self._cache = {}
  def reduce(self, _input):
    key = self._cache.get(_input)
    if key != None:
      return key
    key = ''
    i = self._id
    r = 0
    while i > 0:
      r = i % TOTAL_KEYS
      i = FLOOR(i / TOTAL_KEYS)
      key = KEYS[r] + key
    self._cache[_input] = key
    self._id +=  1
    return key
  def reduce_list(self, _input):
    keys = [self.reduce(value) for value in _input]
    return ','.join(keys)
  def reduce_dict_key(self, _input):
    keys = []
    for key, value in _input.items():
      keys.append(key)
    keys.sort()
    return self.reduce_list(keys)

# Simple Promise helpers to assist with batching IPC

def all(promises):
  cnt = [len(promises)]
  result = Promise()
  values = [None] * cnt[0]
  def scope_reduce(i, promise):
    def reduce(value):
      values[i] = value
      cnt[0] -= 1
      if cnt[0] == 0:
        result.resolve(values)
    promise.then(reduce)
  for i, promise in enumerate(promises):
    scope_reduce(i, promise)
  return result


class Promise:
  def __init__(self):
    self._has_value = False
    self._value = None
    self._callbacks = None
  def resolve(self, value):
    self._has_value = True
    self._value = value
    if self._callbacks:
      for callback in self._callbacks:
        if callable(callback):
          callback(value)
        else:
          callback.resolve(value)
      self._callbacks = None
    return self
  def then(self, callback):
    if self._has_value:
      if callable(callback):
        callback(self._value)
      else:
        callback.resolve(self._value)
    elif not self._callbacks:
      self._callbacks = [callback]
    else:
      self._callbacks.append(callback)
    return self

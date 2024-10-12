import sys
M = sys.modules[__name__]

from vimade.v2 import animator as ANIMATOR
from vimade.v2.style.animate import ease as EASE

DEFAULT_DURATION = 300
DEFAULT_DELAY = 0
DEFAULT_EASE = EASE.OUT_QUART

def __init(globals):
  global GLOBALS
  GLOBALS = globals
M.__init = __init

# @param config {
#  'duration': number | function(win) -> number
#  'ease': EASE | function(time) -> number
#  'delay': number | function(win) -> number
#  'from': start_value | function(win) -> start_value
#  'style': style # a single style (array not supported yet)
#}
class Animate():
  def __init__(self, config):
    self.config = config
  def attach(self, win):
    style = self.config.get('style')
    state = {
      'duration': self.config.get('duration', DEFAULT_DURATION),
      'ease': self.config.get('ease', DEFAULT_EASE),
      'delay': self.config.get('delay', DEFAULT_DELAY),
      'style': style,
      'from_value': self.config.get('from'),
      'to_value': style.value() if style else None,
    }
    def value(win):
      delay = state['delay']
      if callable(delay):
        delay = delay(win)
      duration = state['duration']
      if callable(duration):
        duration = duration(win)
      to_value = state['to_value']
      if callable(to_value):
        to_value = to_value(win)
      from_value = state['from_value']
      if callable(from_value):
        from_value = from_value(win)
      time = GLOBALS.now * 1000 - (win.faded_time * 1000 + delay)
      if time < 0 or not win.faded or not win.faded_time:
        return from_value
      if time >= duration or from_value == None or to_value == None:
        return to_value
      elapsed = time / duration
      elapsed = state['ease'](min(max(elapsed, 0), 1))
      ANIMATOR.schedule(win)
      result = from_value + (to_value - from_value) * elapsed
      return result
    return state['style'].value(value).attach(win)

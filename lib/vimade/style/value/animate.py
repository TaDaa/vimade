import sys
M = sys.modules[__name__]

from vimade import animator as ANIMATOR
from vimade.style.value import ease as EASE
from vimade.style.value import condition as CONDITION
from vimade.style.value import direction as DIRECTION
from vimade.style import invert as INVERT
from vimade.util import type as TYPE
from vimade.util import color as COLOR_UTIL

DEFAULT_DURATION = 300
DEFAULT_DELAY = 0
DEFAULT_EASE = EASE.OUT_QUART
DEFAULT_DIRECTION = DIRECTION.OUT

def __init(args):
  global GLOBALS
  GLOBALS = args['GLOBALS']
M.__init = __init

ids = 0
def get_next_id():
  global ids
  ids = ids + 1
  return ids

M.EASE = EASE
M.DIRECTION = DIRECTION 

def _compare_eq(value, last):
  return value == last

def Number(**kwargs):
  def interpolate(to, start, pct_time, style, state):
    return COLOR_UTIL.interpolateFloat(to, start, pct_time)
  kwargs['interpolate'] = interpolate
  kwargs['compare'] = _compare_eq
  return M.Animate(**kwargs)

def Rgb(**kwargs):
  def interpolate(to, start, pct_time, style, state):
    return COLOR_UTIL.interpolateRgb(to, start, pct_time)
  kwargs['interpolate'] = interpolate
  kwargs['compare'] = TYPE.shallow_compare
  return M.Animate(**kwargs)

def Invert(**kwargs):
  def interpolate(to, start, pct_time, style, state):
    result = {}
    to = to or {}
    start = start or {}
    result['fg'] = COLOR_UTIL.interpolateFloat(to.get('fg', 0), start.get('fg', 0), pct_time)
    result['bg'] = COLOR_UTIL.interpolateFloat(to.get('bg', 0), start.get('bg', 0), pct_time)
    result['sp'] = COLOR_UTIL.interpolateFloat(to.get('sp', 0), start.get('sp', 0), pct_time)
    return result
  kwargs['interpolate'] = interpolate
  kwargs['compare'] = TYPE.deep_compare
  return M.Animate(**kwargs)

def Tint(**kwargs):
  def interpolate(to, start, pct_time, style, state):
    if not start and not to:
      return None
    to = to or {}
    start = start or {}
    result = {}
    for key, value in to.items():
      if not key in start:
        start[key] = {'rgb': value['rgb'], 'intensity': 0}
    for key, value in start.items():
      if not key in to:
        to[key] = {'rgb': value['rgb'], 'intensity': 0}
    for key, value in to.items():
      result[key] = {
        'rgb': COLOR_UTIL.interpolateRgb(value['rgb'], start[key]['rgb'],  pct_time),
        'intensity': COLOR_UTIL.interpolateFloat(value['intensity'], start[key]['intensity'], pct_time),
      }
    return result
  kwargs['interpolate'] = interpolate
  kwargs['compare'] = TYPE.deep_compare
  return M.Animate(**kwargs)

# @param kwargs {
#  @required to = number | function -> number
#  @required interpolate = function(pct_time, start_value, to_value) -> value
#  @optional id: string | number | function -> string = 0 -- used to share state between values that might cross over between filters, exclusions, and other rules
#  @optional start: number | function -> number = 0
#  @optional duration: number | function -> number = 300
#  @optional delay: number | function -> number = 0
#  @optional ease: EASE | function -> EASE = EASE.OUT_QUART
#  @optional direction: DIRECTION | function -> DIRECTION 
#}
def Animate(**kwargs):
  _custom_id = kwargs.get('id')
  _id = _custom_id if _custom_id != None else get_next_id()
  _interpolate = kwargs.get('interpolate')
  _start = kwargs.get('start')
  _to = kwargs.get('to')
  _duration = kwargs.get('duration')
  _duration = _duration if _duration != None else DEFAULT_DURATION
  _delay = kwargs.get('delay')
  _delay = _delay if _delay != None else DEFAULT_DELAY
  _ease = kwargs.get('ease')
  _ease = _ease if _ease != None else DEFAULT_EASE
  _direction = kwargs.get('direction')
  _direction = _direction if _direction != None else DEFAULT_DIRECTION
  _reset = kwargs.get('reset')
  _reset = _reset if _reset != None else (_direction != DIRECTION.IN_OUT)
  _compare = kwargs.get('compare')
  def animate(style, state):
    id = None
    win = style.win
    if _custom_id != None:
      state = state['custom']
      id = _custom_id(win_state) if callable(_custom_id) else _custom_id
    else:
      state = state['animations']
      id = _id
    if not id in state:
      state[id] = {'value': None}
    state = state[id]
    to = style.resolve(_to, state)
    start = style.resolve(_start, state)
    compare = _compare(to, state.get('last_to')) if callable(_compare) else _compare
    delay = _delay(style, state) if callable(_delay) else _delay
    duration = _duration(style, state) if callable(_duration) else _duration
    direction = _direction(style, state) if callable(_direction) else _direction
    reset = _reset(style, state) if callable(_reset) else _reset
    if compare == False:
      state['change_timestamp'] = GLOBALS.now
    state['last_to'] = to
    time = (GLOBALS.now - (max(win.timestamps['nc'], state.get('change_timestamp') or 0))) * 1000 - (delay or 0)
    # direction in and active means go towards 'to' value from start value
    # direction out and active means go towards start value when the window becomes inactive
    # otherwise the window should be on 'to' value
    # TODO abstract this into a behavior template
    if (direction == DIRECTION.OUT and style._condition == CONDITION.ACTIVE and not style.win.nc) \
      or (direction == DIRECTION.IN and style._condition == CONDITION.INACTIVE and style.win.nc):
        state['value'] = to
        state['start'] = to
        style._animating = False
        return to
    elif (direction == DIRECTION.OUT and style._condition == CONDITION.ACTIVE and style.win.nc) \
      or (direction == DIRECTION.IN and style._condition == CONDITION.INACTIVE and not style.win.nc):
        swp = start
        start = to
        to = swp
    elif (direction == DIRECTION.OUT and style._condition == CONDITION.INACTIVE and not style.win.nc) \
      or (direction == DIRECTION.IN and style._condition == CONDITION.ACTIVE and style.win.nc):
        state['value'] = start
        state['start'] = start
        style._animating = False
        return start
    elif (direction == DIRECTION.OUT and style._condition == CONDITION.INACTIVE and style.win.nc) \
      or (direction == DIRECTION.IN and style._condition == CONDITION.ACTIVE and not style.win.nc):
        pass
    value = state.get('value')
    if value == None:
      state['value'] = start
      state['start'] = start
    if time <= 0:
      if reset == True:
        state['start'] = start
        state['value'] = start
      else:
        state['start'] = state['value']
      style._animating = True
      ANIMATOR.schedule(win)
      return state['start']
    if time >= duration:
      state['value'] = to
      style._animating = False
      return to

    elapsed = time / float(duration)
    elapsed = min(max(_ease(elapsed), 0), 1)
    state['value'] = _interpolate(to, state['start'], elapsed, style, state)
    ANIMATOR.schedule(win)
    style._animating = True
    return state['value']
  return animate

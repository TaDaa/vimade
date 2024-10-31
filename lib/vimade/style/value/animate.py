import sys
M = sys.modules[__name__]

from vimade import animator as ANIMATOR
from vimade.style.value import ease as EASE
from vimade.style.value import condition as CONDITION
from vimade.style.value import direction as DIRECTION
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

def Number(**kwargs):
  kwargs['interpolate'] = COLOR_UTIL.interpolateFloat
  return M.Animate(**kwargs)

def Rgb(**kwargs):
  kwargs['interpolate'] = COLOR_UTIL.interpolateRgb
  return M.Animate(**kwargs)

def Tint(**kwargs):
  def interpolate(to, start, pct_time):
    to = to or {}
    start = start or {}
    result = {}
    start_fg = start.get('fg', {})
    start_bg = start.get('bg', {})
    start_sp = start.get('sp', {})
    to_fg = to.get('fg', {})
    to_bg = to.get('bg', {})
    to_sp = to.get('sp', {})
    start_fg_rgb = start_fg.get('rgb', to_fg.get('rgb'))
    start_bg_rgb = start_bg.get('rgb', to_bg.get('rgb'))
    start_sp_rgb = start_sp.get('rgb', to_sp.get('rgb'))
    to_fg_rgb = to_fg.get('rgb', start_fg.get('rgb'))
    to_bg_rgb = to_bg.get('rgb', start_bg.get('rgb'))
    to_sp_rgb = to_sp.get('rgb', start_sp.get('rgb'))
    start_fg_intensity = start_fg.get('intensity', 0)
    start_bg_intensity = start_bg.get('intensity', 0)
    start_sp_intensity = start_sp.get('intensity', 0)
    to_fg_intensity = to_fg.get('intensity', 0)
    to_bg_intensity = to_bg.get('intensity', 0)
    to_sp_intensity = to_sp.get('intensity', 0)

    if to_fg_rgb != None:
      result['fg'] = {}
      result['fg']['rgb'] = COLOR_UTIL.interpolateRgb(to_fg_rgb, start_fg_rgb, pct_time)
      result['fg']['intensity'] = COLOR_UTIL.interpolateFloat(to_fg_intensity, start_fg_intensity, pct_time)
    if to_bg_rgb != None:
      result['bg'] = {}
      result['bg']['rgb'] = COLOR_UTIL.interpolateRgb(to_bg_rgb, start_bg_rgb, pct_time)
      result['bg']['intensity'] = COLOR_UTIL.interpolateFloat(to_bg_intensity, start_bg_intensity, pct_time)
    if to_sp_rgb != None:
      result['sp'] = {}
      result['sp']['rgb'] = COLOR_UTIL.interpolateRgb(to_sp_rgb, start_sp_rgb, pct_time)
      result['sp']['intensity'] = COLOR_UTIL.interpolateFloat(to_sp_intensity, start_sp_intensity, pct_time)
    return result

  kwargs['interpolate'] = interpolate
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
  _reset = False
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
    to = _to(style, state) if callable(_to) else _to
    start = _start(style, state) if callable(_start) else _start
    delay = _delay(style, state) if callable(_delay) else _delay
    duration = _duration(style, state) if callable(_duration) else _duration
    direction = _direction(style, state) if callable(_direction) else _direction
    reset = _reset(style, state) if callable(_reset) else _reset
    time = (GLOBALS.now - (win.timestamps['nc'] + delay)) * 1000
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

    if time == 0:
      state['start'] = start if reset == True else state['value']
    elif time < 0:
      state['value'] = start
      style._animating = False
      return start
    if time >= duration:
      state['value'] = to
      style._animating = False
      return to

    elapsed = time / duration
    elapsed = min(max(_ease(elapsed), 0), 1)
    state['value'] = _interpolate(to, state['start'], elapsed)
    ANIMATOR.schedule(win)
    style._animating = True
    return state['value']
  return animate

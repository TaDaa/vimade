import sys
import math
M = sys.modules[__name__]

from vimade.style.value import animate as ANIMATE
from vimade.style.value import condition as CONDITION
from vimade.style.value import direction as DIRECTION
from vimade.state import globals as GLOBALS
from vimade.style import fade as FADE
from vimade.style import tint as TINT
from vimade.util import type as TYPE
from vimade.util import ipc as IPC

def _get_win_infos():
  def distance(a1, a2, b1, b2):
    return math.sqrt(math.pow(a1-b1, 2) + math.pow(a2-b2, 2))
  def distance_between(info_a, info_b):
    left_a = info_a['wincol']
    left_b = info_b['wincol']
    right_a = left_a + info_a['width']
    right_b = left_b + info_b['width']
    top_a = info_a['winrow']
    top_b = info_b['winrow']
    bottom_a = top_a + info_a['height']
    bottom_b = top_b + info_b['height']
    if (bottom_a < top_b) and (right_b < left_a):
      return distance(left_a, bottom_a, right_b, top_b)
    elif (right_b < left_a) and (bottom_b < top_a):
      return distance(left_a, top_a, right_b, bottom_b)
    elif (bottom_b < top_a) and  (right_a < left_b):
      return distance(right_a, top_a, left_b, bottom_b)
    elif (right_a < left_b) and (bottom_a < top_b):
      return distance(right_a, bottom_a, left_b, top_b)
    elif (right_b < left_a):
      return left_a - right_b
    elif (right_a < left_b):
      return left_b - right_a
    elif (bottom_b < top_a):
      return top_a - bottom_b
    elif (bottom_a < top_b):
      return top_b - bottom_a
    else:
      return 0
  wininfo = IPC.eval_and_return('getwininfo()')
  current_win = GLOBALS.current['winid']
  found_cur = None
  for info in wininfo:
    if int(info['winid']) == current_win:
      found_cur = info
      info['wincol'] = int(info['wincol'])
      info['winrow'] = int(info['winrow'])
      info['width'] = int(info['width'])
      info['height'] = int(info['height'])
      break
  result = {}
  for info in wininfo:
    if GLOBALS.current['tabnr'] == int(info['tabnr']):
      info['wincol'] = int(info['wincol'])
      info['winrow'] = int(info['winrow'])
      info['width'] = int(info['width'])
      info['height'] = int(info['height'])
      result[int(info['winid'])] = {
        'info': info,
        'dist': distance_between(info, found_cur),
        'area': info['width'] * info['height'],
      }
  return result

M._win_infos = None
M._max_distance = None
M._max_area = None
def _ripple_tick():
  M._win_infos = _get_win_infos()
  M._max_distance = 0
  M._max_area = 0
  for winid, info in M._win_infos.items():
    M._max_distance = max(info['dist'], M._max_distance)
    M._max_area = max(info['area'], M._max_area)
def _ripple_to_tint(style, state):
  to = TINT.Default().value()(style, state)
  if not style.win.winid in M._win_infos:
    return to
  if to:
    for color in to.values():
      if color.get('rgb'):
        if color.get('intensity') == None:
          color['intensity'] = 1
        color['intensity'] = color['intensity'] * 0.5 + (M._win_infos[style.win.winid]['dist'] / (M._max_distance or 1)) * (color['intensity'] * 0.5)
  return to
def _ripple_to_fade(style, state):
  to = FADE.Default().value()(style, state)
  if not style.win.winid in M._win_infos:
    return to
  return (to * 0.5) + (1 - M._win_infos[style.win.winid]['dist'] / (M._max_distance or 1)) * (to * 0.5)
def _ripple_start_tint(style, state):
  start = TINT.Default().value()(style, state)
  if start:
    for color in start.values():
      color['intensity'] = 0
  return start
def _ripple_duration(style, state):
  if M._max_area == 0:
    return 300
  area = M._win_infos.get(style.win.winid, {'area': 0})['area']
  return (area / (M._max_area or 1) + 1) * 300
def _ripple_delay(style, state):
  if M._max_distance == 0:
    return 0
  dist = M._win_infos.get(style.win.winid, {'dist': 0})['dist']
  return dist / (M._max_distance or 1) * 25

def animate_ripple(**kwargs):
  return [
    TINT.Tint(
      tick = _ripple_tick,
      condition = kwargs.get('condition'),
      value = ANIMATE.Tint(
        start = _ripple_start_tint,
        to = _ripple_to_tint,
        direction = DIRECTION.IN_OUT,
        duration = _ripple_duration,
        delay = _ripple_delay,
        ease = kwargs.get('ease'),
      )
    ),
    FADE.Fade(
      condition = kwargs.get('condition'),
      value = ANIMATE.Number(
        to = _ripple_to_fade,
        start = 1,
        direction = DIRECTION.IN_OUT,
        duration = _ripple_duration,
        delay = _ripple_delay,
        ease = kwargs.get('ease'),
      ),
    )]

def ripple(**kwargs):
  return [
      TINT.Tint(
        tick = _ripple_tick,
        condition = kwargs.get('condition'),
        value = _ripple_to_tint,
      ),
      FADE.Fade(
        condition = kwargs.get('condition'),
        value = _ripple_to_fade,
      ),
  ]

# @param **kwargs {
  # @optional animate: boolean = false
# }
def Ripple(**kwargs):
  return {
    'style': animate_ripple(**kwargs) if kwargs.get('animate') else ripple(**kwargs),
    'ncmode': 'windows'
  }

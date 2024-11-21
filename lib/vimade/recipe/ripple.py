import vim
import sys
import math
M = sys.modules[__name__]

from vimade.style.value import animate as ANIMATE
from vimade.style.value import condition as CONDITION
from vimade.style.value import direction as DIRECTION
from vimade.style.value import ease as EASE
from vimade.state import globals as GLOBALS
from vimade.style import fade as FADE
from vimade.style import tint as TINT
from vimade.util import type as TYPE
from vimade.util import ipc as IPC

def _get_win_infos():
  def distance(a1, a2, b1, b2):
    return math.sqrt(math.pow(a1-b1, 2) + math.pow(a2-b2, 2))
  def distance_between(info_a, info_b):
    left_a = float(info_a['wincol']) * 0.35
    left_b = float(info_b['wincol']) * 0.35
    right_a = left_a + float(info_a['width']) * 0.35
    right_b = left_b + float(info_b['width']) * 0.35
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
        color['intensity'] = float(color['intensity'])
        color['intensity'] = (float(M._win_infos[style.win.winid]['dist']) / float(M._max_distance or 1)) * color['intensity']
  return to
def _ripple_to_fade(style, state):
  to = FADE.Default().value()(style, state)
  if not style.win.winid in M._win_infos:
    return to
  to = float(to)
  return to + (1 - float(M._win_infos[style.win.winid]['dist']) / float(M._max_distance or 1)) * ((1-to) * 0.5)
def _ripple_start_tint(style, state):
  start = TINT.Default().value()(style, state)
  if start:
    for color in start.values():
      color['intensity'] = 0
  return start

def animate_ripple(config):
  return [
    TINT.Tint(
      tick = _ripple_tick,
      condition = config.get('condition'),
      value = ANIMATE.Tint(
        to = _ripple_to_tint,
        start = _ripple_start_tint,
        delay = config.get('delay'),
        direction = config.get('direction'),
        duration = config.get('duration'),
        ease = config.get('ease'),
      )
    ),
    FADE.Fade(
      condition = config.get('condition'),
      value = ANIMATE.Number(
        to = _ripple_to_fade,
        start = 1,
        delay = config.get('delay'),
        direction = config.get('direction'),
        duration = config.get('duration'),
        ease = config.get('ease'),
      ),
    )]

def ripple(config):
  return [
      TINT.Tint(
        tick = _ripple_tick,
        condition = config.get('condition'),
        value = _ripple_to_tint,
      ),
      FADE.Fade(
        condition = config.get('condition'),
        value = _ripple_to_fade,
      ),
  ]

#@param kwargs {
  # @optional animate: boolean = false
  # @optional condition: CONDITION = CONDITION.INACTIVE
  # @optional delay: number = ANIMATE.DEFAULT_DELAY
  # @optional direction: DIRECTION = ANIMATE.DEFAULT_DIRECTION
  # @optional duration: number = ANIMATE.DEFAULT_DURATION
  # @optional ease: EASE = ANIMATE.DEFAULT_EASE
#}
def Ripple(**kwargs):
  config = TYPE.shallow_copy(kwargs)
  config['direction'] = config['direction'] if config.get('direction') else DIRECTION.IN_OUT
  config['delay'] = config['delay'] if config.get('delay') else 0
  config['duration'] = config['duration'] if config.get('duration') else 300
  config['ease'] = config['ease'] if config.get('ease') else EASE.LINEAR
  config['ncmode'] = config['ncmode'] if config.get('ncmode') else 'windows'
  return {
    'style': animate_ripple(config) if config.get('animate') else ripple(config),
    'ncmode': config.get('ncmode')
  }

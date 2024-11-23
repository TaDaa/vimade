import sys
import vim
M = sys.modules[__name__]

from vimade.state import globals as GLOBALS
from vimade.style.value import animate as ANIMATE
from vimade.style.value import condition as CONDITION
from vimade.style import fade as FADE
from vimade.style import tint as TINT
from vimade.util import type as TYPE

def _duo_tint_start(style, state):
  start = TINT.Default().value()(style, state)
  if start:
    for color in start.values():
      color['intensity'] = 0
  return start

def _duo_tint_to(style, state):
  to = TINT.Default().value()(style, state)
  if to and style.win.tabnr == GLOBALS.current['tabnr'] and style.win.bufnr == GLOBALS.current['bufnr']:
    for color in to.values():
      if 'rgb' in color:
        if color.get('intensity') == None:
          color['intensity'] = 1
        color['intensity'] = color['intensity'] * 0.5
  return to
def _duo_fade_to(style, state):
  to = FADE.Default().value()(style, state)
  if to and style.win.tabnr == GLOBALS.current['tabnr'] and style.win.bufnr == GLOBALS.current['bufnr']:
    return (1 + to) * 0.5
  return to
def animate_duo(config):
  condition = config.get('condition') 
  animation = {
    'duration': config.get('duration'),
    'delay': config.get('delay'),
    'ease': config.get('ease'),
    'direction': config.get('direction'),
  }
  return [
    TINT.Tint(
      condition = condition,
      value = ANIMATE.Tint(**TYPE.extend({}, animation, {
        'start': _duo_tint_start,
        'to': _duo_tint_to,
      })
    )),
    FADE.Fade(
      condition = condition,
      value = ANIMATE.Number(**TYPE.extend({}, animation, {
        'start': 1,
        'to': _duo_fade_to,
      })
    )),
  ]

def duo(config):
  condition = config.get('condition') 
  return [
    TINT.Default(**TYPE.extend(config, {
      'value': _duo_tint_to,
    })),
    FADE.Default(**TYPE.extend(config, {
      'value': _duo_fade_to,
    })),
  ]

# @param **kwargs {
  # @optional animate: boolean = false
  # @optional ease: EASE = ANIMATE.DEFAULT_EASE
  # @optional delay: number = ANIMATE.DEFAULT_DELAY
  # @optional duration: number = ANIMATE.DEFAULT_DURATION
  # @optional direction: DIRECTION = ANIMATE.DEFAULT_DIRECTION
  # @optional ncmode: 'windows'|'buffers' = 'windows'
# }
def Duo(**kwargs):
  config = TYPE.shallow_copy(kwargs)
  config['ncmode'] = config['ncmode'] if config.get('ncmode') != None else 'windows'
  return {
    'style': animate_duo(config) if config.get('animate') else duo(config),
    'ncmode': config['ncmode'],
  }

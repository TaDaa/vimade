import sys
import vim
M = sys.modules[__name__]

from vimade.state import globals as GLOBALS
from vimade.style.value import animate as ANIMATE
from vimade.style.value import direction as DIRECTION
from vimade.style import fade as FADE
from vimade.style import tint as TINT
from vimade.util import type as TYPE

def _duo_tint_to(config):
  buffer_pct = config.get('buffer_pct')
  window_pct = config.get('window_pct')
  def _duo_tint_result(style, state):
    to = style.resolve(TINT.Default().value(), state)
    if to and style.win.tabnr == GLOBALS.current['tabnr']:
      pct = window_pct
      if style.win.bufnr == GLOBALS.current['bufnr']:
        pct = buffer_pct
      for color in to.values():
        if 'rgb' in color:
          if color.get('intensity') == None:
            color['intensity'] = 1
          color['intensity'] = color['intensity'] * pct
    return to
  return _duo_tint_result
def _duo_fade_to(config):
  buffer_pct = config.get('buffer_pct')
  window_pct = config.get('window_pct')
  def _duo_fade_result(style, state):
    to = style.resolve(FADE.Default().value(), state)
    pct = window_pct
    if to != None and style.win.tabnr == GLOBALS.current['tabnr'] and style.win.bufnr == GLOBALS.current['bufnr']:
      pct = buffer_pct
    return to + (1 - to) * (1 - pct)
  return _duo_fade_result
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
        'to': _duo_tint_to(config),
      })
    )),
    FADE.Fade(
      condition = condition,
      value = ANIMATE.Number(**TYPE.extend({}, animation, {
        'start': 1,
        'to': _duo_fade_to(config),
      })
    )),
  ]

def duo(config):
  return [
    TINT.Default(
      condition = config.get('condition'),
      value = _duo_tint_to(config),
    ),
    FADE.Default(
      condition = config.get('condition'),
      value = _duo_fade_to(config),
    ),
  ]

# @param **kwargs {
  # @optional buffer_pct: number[0-1] = 0.382
  # @optional window_pct: number[0-1] = 1
  # @optional animate: boolean = false
  # @optional ease: EASE = ANIMATE.DEFAULT_EASE
  # @optional delay: number = ANIMATE.DEFAULT_DELAY
  # @optional duration: number = ANIMATE.DEFAULT_DURATION
  # @optional direction: DIRECTION = DIRECTION.IN_OUT
  # @optional ncmode: 'windows'|'buffers' = 'windows'
# }
def Duo(**kwargs):
  config = TYPE.shallow_copy(kwargs)
  config['ncmode'] = config['ncmode'] if config.get('ncmode') != None else 'windows'
  config['buffer_pct'] = config['buffer_pct'] if config.get('buffer_pct') != None else 0.382
  config['window_pct'] = config['window_pct'] if config.get('window_pct') != None else 1
  config['direction'] = config['direction'] if config.get('direction') != None else DIRECTION.IN_OUT
  return {
    'style': animate_duo(config) if config.get('animate') else duo(config),
    'ncmode': config['ncmode'],
  }

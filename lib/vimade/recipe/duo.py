from vimade.state import globals as GLOBALS
from vimade.style.value import animate as ANIMATE
from vimade.style.value import condition as CONDITION
from vimade.style.value import direction as DIRECTION
from vimade.style.component import Component
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
      if not style.win.nc:
        pct = 0
      elif style.win.bufnr == GLOBALS.current['bufnr']:
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
    if not style.win.nc:
      return 1
    to = style.resolve(FADE.Default().value(), state)
    pct = window_pct
    if to != None and style.win.tabnr == GLOBALS.current['tabnr'] and style.win.bufnr == GLOBALS.current['bufnr']:
      pct = buffer_pct
    return to + (1 - to) * (1 - pct)
  return _duo_fade_result
def duo(config):
  condition = config.get('condition') 
  animation = {
    'duration': config.get('duration'),
    'delay': config.get('delay'),
    'ease': config.get('ease'),
    'direction': config.get('direction'),
  } if config.get('animate') else None
  def _tint_start(style, state):
    return state.get('start')
  def _fade_start(style, state):
    return state.get('start', 1)
  return [
    Component('Pane', 
      condition = CONDITION.IS_PANE,
      style = [
        TINT.Tint(
          condition = condition,
          value = ANIMATE.Tint(**TYPE.extend({}, animation, {
            'id': 'pane-tint',
            'start': _tint_start,
            'to': _duo_tint_to(config),
          })) if animation else _duo_tint_to(config)
        ),
        FADE.Fade(
          condition = condition,
          value = ANIMATE.Number(**TYPE.extend({}, animation, {
            'id': 'pane-fade',
            'start': _fade_start,
            'to': _duo_fade_to(config),
          })) if animation else _duo_fade_to(config)
        )
      ]
    )
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
  config['ncmode'] = config.get('ncmode', 'windows')
  config['buffer_pct'] = config.get('buffer_pct', 0.382)
  config['window_pct'] = config.get('window_pct', 1)
  config['direction'] = config.get('direction', DIRECTION.IN_OUT)
  return {
    'style': duo(config),
    'ncmode': config['ncmode'],
  }

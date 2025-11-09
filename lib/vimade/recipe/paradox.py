import vim

from vimade.util import type as TYPE
from vimade.style.component import Component
from vimade.style import fade as FADE
from vimade.style import tint as TINT
from vimade.style.invert import Invert
from vimade.style.value import animate as ANIMATE
from vimade.style.value import condition as CONDITION
from vimade.style.value import direction as DIRECTION

_default_fade = FADE.Default().value()
_default_tint = TINT.Default().value()

def paradox(config):
  def invert_condition(style, state):
    win = style.win
    if config['invert']['active'] and (not win.terminal and not win.nc):
      return True
    elif not config['invert']['active'] and win.nc:
      return True
    return False

  animation = {
    'duration': config.get('duration'),
    'delay': config.get('delay'),
    'ease': config.get('ease'),
    'direction': config.get('direction'),
  } if config.get('animate') else None

  return [
    Component('Pane',
      condition = CONDITION.IS_PANE,
      style = [
        TINT.Tint(
          condition = CONDITION.INACTIVE,
          value = ANIMATE.Tint(**TYPE.extend({}, animation, {
            'to': _default_tint,
            })) if animation else _default_tint
        ),
        FADE.Fade(
          condition = CONDITION.INACTIVE,
          value = ANIMATE.Number(**TYPE.extend({}, animation, {
            'to': FADE.Default().value(),
            'start': 1,
            })) if animation else _default_fade
        ),
        Invert(
          condition = invert_condition,
          value = ANIMATE.Invert(**TYPE.extend({}, animation, {
            'to': config['invert']['to'],
            'start': config['invert']['start'],
            'duration': config['invert']['duration'],
            'direction': config['invert']['direction'],
            })) if animation else config['invert']['to']
        ),
      ]
    )
  ]

# @param config {
#   @optional invert = {
#     @optional start = 0.15
#     @optional to = 0.08
#     @optional focus_to = 0.08
#     @optional direction = DIRECTION.IN
#     @optional duration = DEFAULT_DURATION
#     @optional active = true (inverts the active window)
#   }
#   @optional condition: CONDITION = CONDITION.INACTIVE
#   @optional animate: boolean = false
#   @optional ease: EASE = ANIMATE.DEFAULT_EASE
#   @optional delay: number = ANIMATE.DEFAULT_DELAY
#   @optional duration: number = ANIMATE.DEFAULT_DURATION
#   @optional direction: DIRECTION = ANIMATE.DEFAULT_DIRECTION
#}
def Paradox(**kwargs):
  config = TYPE.shallow_copy(kwargs)
  config['invert'] = config.get('invert', {})
  config['invert']['start'] = config['invert'].get('start', 0.15)
  config['invert']['to'] = config['invert'].get('to', 0.08)
  config['invert']['focus_to'] = config['invert'].get('focus_to', 0.08)
  config['invert']['active'] = config['invert'].get('active', True)
  config['invert']['direction'] = config['invert'].get('direction', DIRECTION.IN if config['invert']['active'] else DIRECTION.OUT)
  config['invert']['duration'] = config['invert'].get('duration', ANIMATE.DEFAULT_DURATION)
  def on_start():
    vim.command('function! VimadeSetupParadox()\n augroup vimade_paradox\n au!\n au TextChanged,TextChangedI * call vimade#DeferredCheckWindows()\n augroup END\n endfunction | call VimadeSetupParadox()')
  def on_finish():
    vim.command('function! VimadeTeardownParadox()\n augroup vimade_paradox\n au!\n augroup END\n endfunction | call VimadeTeardownParadox()')
  return {
    'style': paradox(config),
    'ncmode': 'windows',
    'on': {
      'setup': on_start,
      'teardown': on_finish,
    }
  }

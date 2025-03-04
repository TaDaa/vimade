import sys
M = sys.modules[__name__]

from vimade.style.value import animate as ANIMATE
from vimade.style.value import condition as CONDITION
from vimade.style import fade as FADE
from vimade.style import tint as TINT
from vimade.util import type as TYPE

def animate_default(**kwargs):
  condition = kwargs.get('condition')
  animation = {
    'duration': kwargs.get('duration'),
    'delay': kwargs.get('delay'),
    'ease': kwargs.get('ease'),
    'direction': kwargs.get('direction'),
  }
  return [
    TINT.Tint(
      condition = condition,
      value = ANIMATE.Tint(**TYPE.extend({}, animation, {
        'to': TINT.Default().value()
      }))
    ),
    FADE.Fade(
      condition = condition,
      value = ANIMATE.Number(**TYPE.extend({}, animation, {
        'to': FADE.Default().value(),
        'start': 1,
      }))
    )]

def default(**kwargs):
  return [TINT.Default(**kwargs), FADE.Default(**kwargs)]

# @param **kwargs {
  # @optional animate: boolean = false
  # @optional ease: EASE = ANIMATE.DEFAULT_EASE
  # @optional delay: number = ANIMATE.DEFAULT_DELAY
  # @optional duration: number = ANIMATE.DEFAULT_DURATION
  # @optional direction: DIRECTION = ANIMATE.DEFAULT_DIRECTION
# }
def Default(**kwargs):
  return {
    'style': animate_default(**kwargs) if kwargs.get('animate') else default(**kwargs),
  }

import sys
import vim
M = sys.modules[__name__]

from vimade.state import globals as GLOBALS
from vimade.style.value import animate as ANIMATE
from vimade.style.value import condition as CONDITION
from vimade.style import fade as FADE
from vimade.style import tint as TINT
from vimade.style.exclude import Exclude
from vimade.style.include import Include
from vimade.util import type as TYPE

EXCLUDE_NAMES = ['LineNr', 'LineNrBelow', 'LineNrAbove', 'WinSeparator', 'EndOfBuffer', 'NonText', 'VimadeWC']
NO_VISIBILITY_NAMES = ['LineNr', 'LineNrBelow', 'LineNrAbove', 'EndOfBuffer', 'NonText', 'VimadeWC']
LOW_VISIBILITY_NAMES = ['WinSeparator']

def animate_minimalist(config):
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
        'to': TINT.Default().value()
      }))
    ),
    Exclude(
      condition = condition,
      names = config.get('exclude_names'),
      style = [
        FADE.Fade(
          value = ANIMATE.Number(**TYPE.extend({}, animation, {
            'to': FADE.Default().value(),
            'start': 1
          }))
        )
      ]
    ),
    Include(
      condition = condition,
      names = config.get('no_visibility_names'),
      style = [
        FADE.Fade(
          value = ANIMATE.Number(**TYPE.extend({}, animation, {
            'to': 0,
            'start': 1
          }))
        )
      ]
    ),
    Include(
      condition = condition,
      names = config.get('low_visibility_names'),
      style = [
        FADE.Fade(
          value = ANIMATE.Number(**TYPE.extend({}, animation, {
            'to': config.get('low_visibility_fadelevel'),
            'start': 1
          }))
        )
      ]
    ),
  ]

def minimalist(config):
  condition = config.get('condition') 
  return [
      TINT.Default(**config),
      Exclude(
        condition = condition,
        names = config.get('exclude_names'),
        style = [FADE.Default()]
      ),
      Include(
        condition = condition,
        names = config.get('no_visibility_names'),
        style = [FADE.Fade(value = 0)]
      ),
      Include(
        condition = condition,
        names = config.get('low_visibility_names'),
        style = [FADE.Fade(value = config.get('low_visibility_fadelevel'))]
      ),
    ]

# @param **kwargs {
  # @optional animate: boolean = false
  # @optional ease: EASE = ANIMATE.DEFAULT_EASE
  # @optional delay: number = ANIMATE.DEFAULT_DELAY
  # @optional duration: number = ANIMATE.DEFAULT_DURATION
  # @optional direction: DIRECTION = ANIMATE.DEFAULT_DIRECTION
# }
def Minimalist(**kwargs):
  config = TYPE.shallow_copy(kwargs)
  config['exclude_names'] = config['exclude_names'] if config.get('exclude_names') != None else EXCLUDE_NAMES
  config['no_visibility_names'] = config['no_visibility_names'] if config.get('no_visibility_names') != None else NO_VISIBILITY_NAMES
  config['low_visibility_names'] = config['low_visibility_names'] if config.get('low_visibility_names') != None else LOW_VISIBILITY_NAMES
  config['low_visibility_fadelevel'] = config['low_visibility_fadelevel'] if config.get('low_visibility_fadelevel') != None else 0.2
  return {
    'style': animate_minimalist(config) if config.get('animate') else minimalist(config),
    'linkwincolor': [] if GLOBALS.is_nvim else [x for x in config['no_visibility_names'] if x != 'VimadeWC'],
  }

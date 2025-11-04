from vimade.state import globals as GLOBALS
from vimade.style.value import animate as ANIMATE
from vimade.style.value import condition as CONDITION
from vimade.style import fade as FADE
from vimade.style import tint as TINT
from vimade.style.component import Component
from vimade.style.exclude import Exclude
from vimade.style.include import Include
from vimade.util import type as TYPE

EXCLUDE_NAMES = ['LineNr', 'LineNrBelow', 'LineNrAbove', 'WinSeparator', 'EndOfBuffer', 'NonText', 'VimadeWC']
NO_VISIBILITY_NAMES = ['LineNr', 'LineNrBelow', 'LineNrAbove', 'EndOfBuffer', 'NonText', 'VimadeWC']
LOW_VISIBILITY_NAMES = ['WinSeparator']

def minimalist(config):
  condition = config.get('condition') 
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
          condition = condition,
          value = ANIMATE.Tint(**TYPE.extend({}, animation, {
            'to': TINT.Default().value()
          }))
        ) if animation else TINT.Default(**config),
        Exclude(
          condition = condition,
          value = config.get('exclude_names'),
          style = [
            FADE.Fade(
              value = ANIMATE.Number(**TYPE.extend({}, animation, {
                'id': 'fade',
                'to': FADE.Default().value(),
                'start': 1
              }))
            ) if animation else FADE.Default()
          ]
        ),
        Include(
          condition = condition,
          value = config.get('no_visibility_names'),
          style = [
            FADE.Fade(
              value = ANIMATE.Number(**TYPE.extend({}, animation, {
                'id': 'no-vis-fade',
                'to': 0,
                'start': 1
              })) if animation else 0
            )
          ]
        ),
        Include(
          condition = condition,
          value = config.get('low_visibility_names'),
          style = [
            FADE.Fade(
              value = ANIMATE.Number(**TYPE.extend({}, animation, {
                'id': 'low-vis-fade',
                'to': config.get('low_visibility_fadelevel'),
                'start': 1
              })) if animation else config.get('low_visibility_fadelevel')
            )
          ]
        )
      ]
    )
  ]

# @param **kwargs {
  # @optional animate: boolean = false
  # @optional exclude_names: string[] = ['LineNr', 'LineNrBelow', 'LineNrAbove', 'WinSeparator', 'EndOfBuffer']
  # @optional no_visibility_names: string[] = ['LineNr', 'LineNrBelow', 'LineNrAbove', 'EndOfBuffer']
  # @optional low_visibility_names: string[] = ['WinSeparator']
  # @optional low_visibility_fadelevel: number = 0.1
  # @optional ease: EASE = ANIMATE.DEFAULT_EASE
  # @optional delay: number = ANIMATE.DEFAULT_DELAY
  # @optional duration: number = ANIMATE.DEFAULT_DURATION
  # @optional direction: DIRECTION = ANIMATE.DEFAULT_DIRECTION
# }
def Minimalist(**kwargs):
  config = TYPE.shallow_copy(kwargs)
  config['condition'] = config.get('condition', CONDITION.INACTIVE)
  config['exclude_names'] = config.get('exclude_names', EXCLUDE_NAMES)
  config['no_visibility_names'] = config.get('no_visibility_names', NO_VISIBILITY_NAMES)
  config['low_visibility_names'] = config.get('low_visibility_names', LOW_VISIBILITY_NAMES)
  config['low_visibility_fadelevel'] = config.get('low_visibility_fadelevel', 0.1)
  return {
    'style': minimalist(config),
    'linkwincolor': [] if GLOBALS.is_nvim else [x for x in config['no_visibility_names'] if x != 'VimadeWC'],
  }

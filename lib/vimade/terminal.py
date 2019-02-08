import subprocess
import re
import os
from vimade import global_state as GLOBALS

DIR = os.path.dirname(__file__)
COLORS_SH = ['bash' , os.path.realpath(os.path.join(DIR, '..', '..', 'colors.sh'))]

def detectColors():
  params = ([''], ['7'], ['tmux'], ['tmux', '7'])
  fg = ''
  bg = ''
  def match(input):
    result = re.findall("[a-zA-Z0-9]{2,4}/[a-zA-Z0-9]{2,4}/[a-zA-Z0-9]{2,4}", input)
    if len(result):
      result = result[0]
    result = result if len(result) else ''
    result = re.findall("[0-9a-zA-Z]{2,}", result)
    return result

  if GLOBALS.is_term and not GLOBALS.is_nvim:
    for p in params:
      if not fg:
        try:
          fg = str(subprocess.check_output(COLORS_SH + ['10'] + p)).strip()
        except:
          pass
      if not bg:
        try:
          bg = str(subprocess.check_output(COLORS_SH + ['11'] + p)).strip()
        except:
          pass
      if fg and bg:
        break

    fg = match(fg)
    bg = match(bg)

    output = (fg, bg)

    if output[0] and len(output[0]):
      GLOBALS.term_fg = list(map(lambda x: int(x[0:2], 16), output[0]))
      GLOBALS.term_response = True
    if output[1] and len(output[1]):
      GLOBALS.term_bg = list(map(lambda x: int(x[0:2], 16), output[1]))
      GLOBALS.term_response = True

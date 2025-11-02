from vimade.style.value import condition as CONDITION
from vimade.util.key_reducer import KeyReducer
from vimade import highlighter as HIGHLIGHTER

link_key_reducer = KeyReducer()

class Link():
  def __init__(parent, **kwargs):
    _condition = kwargs.get('condition', CONDITION.INACTIVE)
    _value = kwargs.get('value')
    parent.tick = kwargs.get('tick')
    class __Link():
      def __init__(self, win, state):
        self.win = win
        self._condition = _condition
        self._animating = False
        self._link = []
        self._link_key = ''
      def before(self, win, state):
        self.condition = _condition(self, state) if callable(_condition) else _condition
        if self.condition == False:
          return
        inputs = _value(win) if callable(_value) else _value
        self._link = []
        key_input = []
        for v in inputs:
          key_input.append(v.get('from','') + v.get('to', ''))
          self._link.append(v)
        self._link_key = link_key_reducer.reduce_list(key_input)
      def key(self, win, state):
        if self.condition == False:
          return ''
        return 'L-' + self._link_key
      def modify(self, highlights, to_hl):
        if self.condition == False:
          return
        missing = {}

        for li in self._link:
          from_hl = highlights.get(li.get('from'))
          to_name = li.get('to')
          if not to_name in highlights:
            missing[to_name] = True
          if from_hl:
            from_hl['link'] = to_name

        def then_process_missing(result):
          (_, missing_highlights) = result
          for (name, hi) in missing_highlights.items():
            highlights[name] = hi

        HIGHLIGHTER.get_highlights(self.win, list(missing.keys()), True).then(then_process_missing)
    parent.attach = __Link


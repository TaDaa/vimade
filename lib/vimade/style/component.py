from vimade.style.value import condition as CONDITION

class Component():
  def __init__(parent, name, **kwargs):
    _condition = kwargs.get('condition', CONDITION.INACTIVE)
    parent.tick = kwargs.get('tick')
    parent.name = name
    class __Component():
      def __init__(self, win, state):
        self.win = win
        self._condition = _condition
        self._animating = False
        self.style = [s.attach(win, state) for s in kwargs.get('style', [])]
      def before(self, win, state):
        self.condition = _condition(self, state) if callable(_condition) else _condition
        if self.condition == False:
          return
        for s in self.style:
          s.before(win, state)
      def key(self, win, state):
        # components don't need their own keys since they are just proxies to their children
        if self.condition == False:
          return ''
        style_keys = [s.key(win, state) for s in self.style]
        return ','.join([s for s in style_keys if s])
      def modify(self, highlights, to_hl):
        if self.condition == False:
          return
        for s in self.style:
          s.modify(highlights, to_hl)
    parent.attach = __Component

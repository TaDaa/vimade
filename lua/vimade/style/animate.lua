local math = require('math')
local EASE = require('vimade.style.animate.ease')
local ANIMATOR = require('vimade.animator')
local M = {}

local DEFAULT_DURATION = 300
local DEFAULT_EASE = EASE.OUT_QUART
local DEFAULT_DELAY = 0

-- TODO we need a more complex verison to handle the tint object
-- this is a simple number version
-- style_with_value needs to be a style that was set with a value (the value preset is the to value)
-- this allows Animate to combine with DEFAULTS and other cool stuff
-- @param config {
--   duration = number | function(win) -> number
--   ease = EASE | function(time) -> number
--   delay = number | function(win) -> number
--   from = start_value | function(win) -> start_value
--   style = style # a single style (array not supported yet)
--}
M.Animate = function(config)
  local _style = config.style
  local _duration = config.duration or DEFAULT_DURATION
  local _ease = config.ease or DEFAULT_EASE
  local _delay = config.delay or DEFAULT_DELAY
  local _from = config.from
  local _to = _style.value()
  local result = {}
  result.attach =  function (win)
    local value = function(win)
      -- window is not faded return the default
       --TODO consider bumping out of value scope
      local delay = _delay
      if type(delay) == 'function' then
        delay = delay(win)
      end
      local duration = _duration
      if type(duration) == 'function' then
        duration = duration(win)
      end
      local to = _to
      if type(to) == 'function' then
        to = to(win)
      end
      local from = _from
      if type(from) == 'function' then
        from = from(win)
      end
      local time = GLOBALS.now - (win.faded_time + delay)
      if time < 0 or not win.faded or win.faded_time == nil then
        return from
      end
      if time > duration or from == nil or to == nil then
        return to
      end
      local elapsed = time / duration
      elapsed = math.min(math.max(_ease(elapsed), 0), 1)
      ANIMATOR.schedule(win)
      return from + (to - from) * elapsed
    end
    return _style.value(value).attach(win)
  end
  return result
end

return M

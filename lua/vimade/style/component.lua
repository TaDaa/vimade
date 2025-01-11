local M = {}

local CONDITION = require('vimade.style.value.condition')

-- components do nothing except act as a named condition allowing users to override things based on concept
-- @param componentName: string
-- @param config = {
--  style = {Fade(0.4)} # style to run on all names that aren included
--}
M.Component = function(name, config)
  local result = {}
  local _condition = config.condition or CONDITION.INACTIVE
  result.name = name
  result.tick = config.tick
  result.attach = function (win)
    local condition = _condition
    local children = {}
    for i, s in ipairs(config.style) do
      table.insert(children, s.attach(win))
    end
    local style = {}
    style.win = win
    style._condition = _condition
    style._animating = false
    style.before = function (win, state)
      if type(_condition) == 'function' then
        condition = _condition(style, state)
      end
      if condition == false then
        return
      end
      for i, s in ipairs(children) do
        s.before(win, state)
      end
    end
    style.key = function (win, state)
      -- components don't need their own keys since they are just proxies to their children
      if condition == false then
        return ''
      end
      local key = ''
      local s_active = 0
      for j, s in ipairs(children) do
        if j ~= 0 then
          key = key .. ','
        end
        local s_key = s.key(win, state)
        key = key .. s_key
        if string.len(s_key) > 0 then
          s_active = s_active + 1
        end
      end
      if s_active == 0 then
        return ''
      end
      return key
    end
    style.modify = function (highlights, to_hl)
      if condition == false then
        return
      end
      for i, s in ipairs(children) do
        s.modify(highlights, to_hl)
      end
    end
    return style
  end
  -- value is not exposed here, no use-case currently
  return result
end
return M

local M = {}

local events = require('vimade.util.events')()

M.on = events.on

local scheduled = nil
local animating = nil

M.__init = function (args)
  args.FADER.on('tick:before', function()
    if scheduled then
      animating = scheduled
      scheduled = nil
    end
  end)
  args.FADER.on('tick:after', function ()
    if animating then
      -- TODO this isn't explicitly needed, but we should add something similar to this
      -- animations should be set back to false if the window condition is no longer active
      -- for winid, styles in pairs(animating) do
      --   local scheduled_styles = (scheduled or {})[winid] or {}
      --   for _, style in ipairs(styles) do
      --     local found = false
      --     for __, style2 in ipairs(scheduled_styles) do
      --       if style == style2 then
      --         found = true
      --         break
      --       end
      --     end
      --     -- ensure we unset animating for anything that didn't re-schedule
      --     if not found and style._animating then
      --       style._animating = false
      --     end
      --   end
      -- end
      animating = nil
    end
    if scheduled then
      vim.schedule(vim.fn['vimade#StartAnimationTimer'])
    end
    events.notify('animator:after')
  end)
end

M.schedule = function (style)
  -- this is also doable via lua code and then scheduling a vim-safe callback
  -- but there appears to be no benefit. Sharing the code across all supported
  -- versions seems much more maintainable currently AND
  -- there also seems to be much less flickering with this approach when compared
  -- to the lua alternative.
  if not scheduled then
    scheduled = {}
  end
  if not scheduled[style.win.winid] then
    scheduled[style.win.winid] = {}
  end
  table.insert(scheduled[style.win.winid], style)
end

M.is_animating = function(winid)
  return (scheduled and scheduled[winid]) or (animating and animating[winid]) or false
end

return M

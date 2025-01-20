local M = {}

local CORE = require('vimade.focus.core')

local events = require('vimade.util.events')()

M.__init = CORE.__init

M.on = events.on

M.get = CORE.get

M.update = CORE.update

M.cleanup = CORE.cleanup

M.setup = CORE.setup

M.global_focus_enabled = function()
  return CORE.global_focus_enabled
end

M.toggle_on = function()
  if vim.g.vimade_running == 0 then
    return
  end
  CORE.activate_focus()
  events.notify('focus:on')
end

M.toggle_off = function()
  CORE.deactivate_focus()
  events.notify('focus:off')
end

M.toggle = function()
  if CORE.global_focus_enabled then
    M.toggle_off()
  else
    M.toggle_on()
  end
end

-- If no range is provided, any marks under the cursor will be removed.
-- If a range is provided, a new mark will be placed. Any marks overlapping the selection will be replaced.
-- config = {@optional range={start, end}}
M.mark_toggle = function(config)
  CORE.mark_toggle(config)
  events.notify('focus:mark')
end

-- Places a mark between the range of lines in the window.
-- config = {
  -- @optional range={start, end} [default = cursor_location],
  -- @optional winid: number [default = vim.api.nvim_get_current_win()]
-- }
M.mark_set = function(config)
  CORE.mark_set(config)
  events.notify('focus:mark')
end

-- removes all marks meeting the criteria. If no criteria is included,
-- all marks are removed.
-- config = {
  -- @optional range: {start, end} -- NOTE: If range is provided without winid, the current window is assumed.
  -- @optional winid: number
  -- @optional bufnr: number
  -- @optional tabnr: number
-- }
M.mark_remove = function(config)
  CORE.mark_remove(config)
  events.notify('focus:mark')
end

M.disable = function()
  M.toggle_off()
  CORE.cleanup({})
end

return M

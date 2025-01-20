local TYPE = require('vimade.util.type')
local API = require('vimade.focus.api')

local root_options = {
  {'VimadeMark', {
      {'', function(cmds, arg) API.mark_toggle({range={arg.line1, arg.line2}}) end},
      {'set', function(cmds, arg) API.mark_set({range={arg.line1, arg.line2}}) end},
      {'remove', function(cmds, arg) API.mark_remove({range={arg.line1, arg.line2}}) end},
      {'remove-win', function(cmds, arg) API.mark_remove({winid=vim.api.nvim_get_current_win()}) end},
      {'remove-buf', function(cmds, arg) API.mark_remove({bufnr=vim.api.nvim_get_current_buf()}) end},
      {'remove-tab', function(cmds, arg) API.mark_remove({tabnr=vim.api.nvim_get_current_tabpage()}) end},
      {'remove-all', function(cmds, arg) API.mark_remove({}) end},
  }},
  {'VimadeFocus', {
      {'', API.toggle},
      {'toggle', API.toggle},
      {'toggle-on', API.toggle_on},
      {'toggle-off', API.toggle_off},
  }}
}

local options_of = function(input)
  local result = {}
  for i, value in ipairs(input) do
    if value[1] ~= '' then
      table.insert(result, value[1])
    end
  end
  return result
end

local process_input = function(input, exact)
  local inputs = input:gmatch('([^\\ ]+)')
  local options = TYPE.deep_copy(root_options)
  local result_options = {}
  local remaining = {}
  local run = true
  local input_size = 0
  local ends_sp = input:sub(-1) == ' '
  local process = {}
  for input in inputs do
    input = input:lower()
    input_size = input_size + 1
    table.insert(process, input)
  end
  for i, key in ipairs(process) do
    local found = false
    for _, option in ipairs(options) do
      if key == option[1]:lower() then
        found = true
        if type(option[2]) == 'function' then
          table.insert(result_options, option)
        elseif i < input_size or ends_sp or exact then
          options = option[2]
        else
          table.insert(remaining, key)
        end
        break
      end
    end
    if not exact and not found then
      table.insert(remaining, key)
    end
  end
  if #remaining > 1 then
    return {}
  end
  if exact and #result_options > 0 then
    options = result_options
  end
  remaining = remaining[1]
  local r_ln = remaining and remaining:len() or 0
  local indices = {}
  for i, option in ipairs(options) do
    indices[option[1]] = i
  end
  table.sort(options, function(a, b)
    local a_is_remaining = a[1]:sub(1, r_ln) == remaining 
    local b_is_remaining = b[1]:sub(1, r_ln) == remaining 
    if (a_is_remaining and b_is_remaining) or (not a_is_remaining and not b_is_remaining) then
      return indices[a[1]] < indices[b[1]]
    elseif a_is_remaining then
      return true
    elseif b_is_remaining then
      return false
    end
  end)
  return options
end

for _, cmd in ipairs(root_options) do
  vim.api.nvim_create_user_command(cmd[1], function(args)
    local selection = process_input(args.name .. ' ' .. (args.fargs[1] or ''), true)
    local same_level_commands = {}
    for _, option in ipairs(selection) do
      table.insert(same_level_commands, option[1])
    end
    -- only the first is THE selection
    if selection[1] and type(selection[1][2]) == 'function' then
      selection[1][2](same_level_commands, args)
    end
  end, {
    nargs = '?',
    range = true,
    complete = function(last_cmd, input)
      input = input or ''
      input = input:gsub('^\'<,\'>','')
      return options_of(process_input(input))
    end
  })
end

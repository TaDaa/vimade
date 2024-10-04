local M = {}
local TINT = require('vimade.config_helpers.tint')
local TYPE = require('vimade.util.type')
local MATCHERS = require('vimade.util.matchers')
local NAMESPACE = require('vimade.state.namespace')

-- arbitrary high number for us to regulate what has been processed in a single tick
local MAX_TICK_ID = 1000000
local next_tick_id = function ()
  local tick_id = M.tick_id + 1
  if tick_id > MAX_TICK_ID then
    tick_id = 1
  end
  return tick_id
end

NAMESPACE.__init(M)
TINT.__init(M)

M.READY = 0
M.ERROR = 1
M.CHANGED = 2
M.RECALCULATE = 4

M.tick_id = 0
M.tick_state = M.READY
M.global_ns = nil-- used to cache namespace 0 at the global level
M.vimade_fade_active = false
M.basebg = nil
M.normalid = 0
M.normalncid = 0
M.fademode = 'buffers'
M.fade_windows = false
M.fade_buffers = false
M.tint = nil
M.fadelevel = 0
M.fademinimap = false
M.groupdiff = true
M.groupscrollbind = false
M.nohlcheck = false
M.colorscheme = nil
M.is_dark = false
M.current = {
  winid = -1,
  bufnr = -1,
  tabnr = -1,
}
M.fadeconditions = nil
M.link = {}
M.blocklist = {}
M.global_highlights = {}

local CURRENT = {
  winid = -1,
  bufnr = -1,
  tabnr = -1,
}
local OTHER = {
  vimade_fade_active = false,
  is_dark = false,
}
local DEFAULTS = {
  basebg = nil,
  fademode = 'buffers',
  -- todo what should the default be?
  nohlcheck = true,
  tint = TINT.DEFAULT,
  --tint = function()
    --return {
      --bg = {
        --rgb = {math.random(0,255), math.random(0,255), math.random(0,255)},
        --intensity = math.random()
      --}
    --}
  --end,
  fadelevel = 0.4,
  --fadelevel = function ()
    --return math.random()
  --end,
  fademinimap = nil,
  groupdiff = true,
  groupscrollbind = false,
  fadeconditions = nil, -- function return true should fade or table of functions
  link = {
    -- runs the default_matcher with this config
    -- any value that is a config goes to the
    -- default matcher
    --
    -- this is set to an empty object to enforce the default condition
    -- for legacy conditions
    default = {
      buf_names = nil,
      buf_opts = nil,
      buf_vars = nil,
      win_opts = nil,
      win_vars = nil,
      win_config = nil,
    },
    -- include_alternative matchers if desired
    -- function(win, activeWin) end
  },
  blocklist = {
    -- runs the default_matcher with this config
    -- any value that is a config goes to the
    -- default matcher
    --
    -- this is set to an empty object to enforce the default condition
    -- for legacy conditions
    default = {
      buf_names = nil,
      buf_opts = nil,
      buf_vars = nil,
      win_opts = nil,
      win_vars = nil,
      win_config = {
        relative = true
      },
    },
    -- include_alternative matchers if desired
    -- function(win) end
  }
}

local check_fields = function (fields, next, current, defaults, return_state)
  local modified = false
  for i, field in pairs(fields) do
    local value = next[field] 
    if value == nil then
      value = defaults[field]
    end
    if current[field] ~= value then
      current[field] = value
      modified = true
    end
  end
  return modified and return_state or M.READY
end

M.getInfo = function ()
  result = {renderer = 'lua', [vim.type_idx]=vim.types.dictionary}
  for key, value in pairs(M) do
    if type(value) ~= 'function'
      and key ~= 'global_ns'
      and key ~= 'global_highlights' then
      result[key] = value
    end
  end
  return result
end

M.refresh_global_ns = function ()
  if M.global_ns == nil then
    M.global_ns = NAMESPACE.get_replacement({winid= 'g'}, 0)
  end
    NAMESPACE.check_ns_modified(M.global_ns)
  if M.global_ns.modified == true then
    M.global_highlights = M.global_ns.real_highlights
  end
end

M.refresh = function ()
  M.tick_id = next_tick_id()
  M.tick_state = M.READY
  local vimade = vim.g.vimade
  local current = {
    winid = tonumber(vim.api.nvim_get_current_win()),
    bufnr = tonumber(vim.api.nvim_get_current_buf()),
    tabnr = tonumber(vim.fn.tabpagenr()),
  }

  if vimade.nohlcheck ~= nil then
    M.nohlcheck = TYPE.num_to_bool(vimade.nohlcheck)
  else
    M.nohlcheck = DEFAULTS.nohlcheck
  end

  M.tick_state = bit.bor(M.tick_state, check_fields({
    'normalid',
    'normalncid',
  }, vimade, M, DEFAULTS, M.RECALCULATE))
  M.tick_state = bit.bor(M.tick_state, check_fields({
    'is_dark',
    'colorscheme',
  }, {
    is_dark = vim.go.background == 'dark',
    colorscheme = vim.g.colors_name,
  }, M, OTHER, M.RECALCULATE))
  M.tick_state = bit.bor(M.tick_state, check_fields({
    'vimade_fade_active',
  }, {
    vimade_fade_active = vim.g.vimade_fade_active == 1,
  }, M, OTHER, M.CHANGED))
  M.tick_state = bit.bor(M.tick_state, check_fields({
    'fademode',
  }, vimade, M, DEFAULTS, M.CHANGED))
  M.tick_state = bit.bor(M.tick_state, check_fields({
    'winid',
    'bufnr',
    'tabnr',
  }, current, M.current, CURRENT, M.CHANGED))

  if not M.global_ns or not M.nohlcheck or bit.band(M.RECALCULATE, M.tick_state) > 0 then
    M.refresh_global_ns()
    if M.nohlcheck and M.global_ns.modified == true then
      -- RECALCULATE only for nohlcheck
      M.tick_state = bit.bor(M.RECALCULATE, M.tick_state)
    end
  end


  -- will be handled in win_state --
  M.link = vimade.link or DEFAULTS.link --TODO this be a one-key merge/replace
  M.basebg = vimade.basebg ~= '' and vimade.basebg or DEFAULTS.basebg
  M.blocklist = vimade.blocklist or DEFAULTS.blocklist --TODO this be a one-key merge/replace
  M.groupdiff = TYPE.num_to_bool(vimade.groupdiff, DEFAULTS.groupdiff)
  M.groupscrollbind = TYPE.num_to_bool(vimade.groupscrollbind, DEFAULTS.groupscrollbind)
  M.fademinimap = TYPE.num_to_bool(vimade.fademinimap, DEFAULTS.fademinimap)
  M.tint = vimade.tint or DEFAULTS.tint
  M.fadelevel = vimade.fadelevel or DEFAULTS.fadelevel
  if type(vimade.fadeconditions) == 'table' then
    M.fadeconditions = vimade.fadeconditions
  elseif type(vimade.fadeconditions) == 'function' then
    M.fadeconditions = {vimade.fadeconditions}
  else
    M.fadeconditions = DEFAULTS.fadecondition
  end

  -- already checked --
  M.fade_windows = M.fademode == 'windows'
  M.fade_buffers = M.fademode == 'buffers'
end

return M

local M = {}

local DIRECTION = require('vimade.style.value.direction')
local EXCLUDE = require('vimade.style.exclude')
local TYPE = require('vimade.util.type')
local REAL_NAMESPACE = require('vimade.state.real_namespace')
local DEFAULT_RECIPE = require('vimade.recipe.default')

-- arbitrary high number for us to regulate what has been processed in a single tick
local MAX_TICK_ID = 400000
local next_tick_id = function ()
  local tick_id = M.tick_id + 1
  if tick_id > MAX_TICK_ID then
    tick_id = 1
  end
  return tick_id
end

M.READY = 0
M.ERROR = 1
M.CHANGED = 2
M.RECALCULATE = 4
-- some plugins (e.g. Neotree) add the highlights on window/buffer change. When nohlcheck,
-- which prevents rechecking the namespaces for no reason, is enabled we tell the downstream
-- logic to check namespaces on buf/win/tab change.
M.HLCHECK = 8

M.vimade_lua = {}

M.tick_id = 0
M.tick_state = M.READY
M.now = vim.loop.now()
M.global_ns = nil-- used to cache namespace 0 at the global level
M.vimade_fade_active = false
M.basebg = nil
M.normalid = 0
M.normalncid = 0
M.ncmode = 'buffers'
M.nc_windows = false
M.nc_buffers = false
M.fadelevel = 0
M.fademinimap = false
M.groupdiff = true
M.groupscrollbind = false
M.nohlcheck = true
M.colorscheme = nil
M.termguicolors = nil
M.is_dark = false
M.current = {
  winid = -1,
  bufnr = -1,
  tabnr = -1,
}
M.link = {}
M.blocklist = {}
M.disabled_highlights = {}
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
local DEFAULTS = TYPE.extend(DEFAULT_RECIPE.Default(), {
  basebg = nil,
  ncmode = 'buffers',
  -- disabled for absolute peformance
  -- can be enabled to re-check highlights each tick
  nohlcheck = true,
  -- TODO update this doc
  -- tint must be an object where the values tinting functions ()
  -- object is also accepted and passed to the DEFAULT tinter
  -- tinters are executed in order (from index=0 first), the previous value is passed as highlight
  -- to the next tinter
  --
  -- example:
  -- {
    -- id = function() end -- not required by default your function will use the object key as the id.  However if you want your tint to be recalculated based on an external change the id needs to return a different value (think of it as a cache_key)
    -- interpolate = function (name, highlight, target, optional_win) end
    --   retur
    -- }
  --
  -- 
  --tint = {TINT.DEFAULT},
  --tint = {function(win)
    --return {
      --bg = {
        --rgb = {math.random(0,255), math.random(0,255), math.random(0,255)},
        --intensity = math.random()
      --}
    --}}
  --end,
  fadelevel = 0.4, --or function(win) -> value
  fademinimap = nil,
  groupdiff = true,
  groupscrollbind = false,
  link = {
    -- runs the default_matcher with this config
    -- any value that is a config goes to the
    -- default matcher
    --
    -- this is set to an empty object to enforce the default condition
    -- for legacy conditions
    default = {
      buf_name = nil,
      buf_opts = nil,
      buf_vars = nil,
      win_opts = nil,
      win_vars = nil,
      win_config = nil,
    },
    -- include_alternative matchers if desired
    -- function(win, activeWin) end
  },
  disabled_highlights = {
    default = {
      function(hi_name)
        -- see #85 prevent global statusline from flickering due to multiple windows impacting
        -- StatusLine. laststatus=3 also causes some misalignment on WinSeparator, if you see
        -- issues consider either also excluding 'WinSeparator' or tweaking the WinSeparator
        -- guibg until you find a value that looks good.
        return hi_name == 'StatusLine' and vim.go.laststatus == 3
      end
    },
  },
  blocklist = {
    -- runs the default_matcher with this config
    -- any value that is a config goes to the
    -- default matcher
    --
    -- this is set to an empty object to enforce the default condition
    -- for legacy conditions
    default = {
      buf_name = nil,
      -- terminal is temporarily disabled until proper fading is added
      buf_opts = {buftype = {'prompt', 'terminal'}},
      buf_vars = nil,
      win_opts = nil,
      win_vars = nil,
      win_type = true,
      win_config = {
        relative = true
      },
    },
  },
})

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

M.setup = function (config)
  local overlay = {}
  local recipe = config and config.recipe
  if recipe and #recipe > 0 then
    if type(recipe[1]) == 'string' then
      local required = {}
      for part in string.gmatch(recipe[1], '[^:]*') do
        table.insert(required, part)
      end
      local file = string.lower(required[1]) 
      local name = (required[2] and required[2] ~= '') and required[2] or file
      if not file and name then
        file = string.lower(name)
      end
      name = string.upper(string.sub(name,1,1)) .. string.lower(string.sub(name, 2))
      local module = require('vimade.recipe.' .. file)
      module = module[name]
      recipe = module(recipe[2] or {})
      overlay = TYPE.extend(overlay, recipe)
    end
  end
  config.recipe = nil
  overlay = TYPE.extend(overlay, TYPE.deep_copy(config))
  local external_overlay = {}
  for i, field in ipairs({'usecursorhold', 'checkinterval', 'enablefocusfading', 'normalid', 'normalncid'}) do
    if config[field] ~= nil then
      external_overlay[field] = config[field]
    end
  end
  M.vimade_lua = overlay
  vim.g.vimade_overlay = external_overlay
end

M.getInfo = function ()
  result = {renderer = 'lua', [vim.type_idx]=vim.types.dictionary}
  for key, value in pairs(M) do
    if type(value) ~= 'function'
      and key ~= 'style'
      and key ~= 'global_ns'
      and key ~= 'global_highlights' then
      result[key] = value
    end
  end
  return result
end

M.refresh_global_ns = function ()
  M.global_ns = REAL_NAMESPACE.refresh(0)
  if M.global_ns.modified == true then
    M.global_highlights = M.global_ns.highlights
  end
end

M.callbacks = {}

M.refresh = function (override_tick_state)
  M.now = vim.loop.now()
  M.tick_id = next_tick_id()
  M.tick_state = override_tick_state or M.READY
  -- no reason to re-copy vimade_lua we aren't going to change it
  local vimade = TYPE.shallow_extend(TYPE.deep_copy(vim.g.vimade), M.vimade_lua)
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
    'termguicolors',
  }, {
    is_dark = vim.go.background == 'dark',
    colorscheme = vim.g.colors_name,
    termguicolors = vim.go.termguicolors,
  }, M, OTHER, bit.bor(M.RECALCULATE, M.CHANGED)))
  M.tick_state = bit.bor(M.tick_state, check_fields({
    'vimade_fade_active',
  }, {
    vimade_fade_active = vim.g.vimade_fade_active == 1,
  }, M, OTHER, M.CHANGED))
  M.tick_state = bit.bor(M.tick_state, check_fields({
    'ncmode',
  }, vimade, M, DEFAULTS, M.CHANGED))
  M.tick_state = bit.bor(M.tick_state, check_fields({
    'winid',
    'bufnr',
    'tabnr',
  }, current, M.current, CURRENT, bit.bor(M.RECALCULATE, M.CHANGED)))

  -- will be handled in win_state --
  -- link and blocklist are merged at the name level (user overlay has priority)
  M.link = TYPE.extend({}, DEFAULTS.link, vimade.link)
  M.blocklist = TYPE.extend({}, DEFAULTS.blocklist, vimade.blocklist)
  M.disabled_highlights = TYPE.extend({}, DEFAULTS.disabled_highlights, vimade.disabled_highlights)

  M.basebg = vimade.basebg ~= '' and vimade.basebg or DEFAULTS.basebg
  M.groupdiff = TYPE.num_to_bool(vimade.groupdiff, DEFAULTS.groupdiff)
  M.groupscrollbind = TYPE.num_to_bool(vimade.groupscrollbind, DEFAULTS.groupscrollbind)
  M.fademinimap = TYPE.num_to_bool(vimade.fademinimap, DEFAULTS.fademinimap)
  M.tint = vimade.tint or DEFAULTS.tint
  M.fadelevel = vimade.fadelevel or DEFAULTS.fadelevel
  M.style = vimade.style or DEFAULTS.style

  -- already checked --
  M.nc_windows = M.ncmode == 'windows'
  M.nc_buffers = not M.nc_windows
  -- if you don't choose one of the above, everything is highlighted

  if not M.global_ns or not M.nohlcheck
    or bit.band(M.RECALCULATE, M.tick_state) > 0 then
    M.refresh_global_ns()
    if M.global_ns.modified == true then
      M.tick_state = bit.bor(M.RECALCULATE, M.tick_state)
    end
  end

end

return M

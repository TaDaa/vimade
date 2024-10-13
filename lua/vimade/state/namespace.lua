local M = {}
local TYPE = require('vimade.util.type')
local COMPAT = require('vimade.util.compat')
local GLOBALS

M.__init = function (globals)
  GLOBALS = globals
end

M.key_lookup = {}
M.real_ns_lookup = {}
M.vimade_active_ns_lookup = {}
M.winid_lookup = {}
M.used_ns = {}
M.free_ns = {}

local ids = 0
local get_next_id = function ()
  ids = ids + 1
  return ids
end

local resolve_all_links = function (real_ns, real_highlights)
  local output = TYPE.deep_copy(GLOBALS.global_highlights)

  if real_ns ~= 0 then
    local overrides = TYPE.deep_copy(real_highlights)
    for name, override in pairs(overrides) do
      if output[name] == nil then
        output[name] = override
      else
        local global_highlight = output[name]
        for key, value in pairs(override) do
          global_highlight[key] = value
        end
      end
    end
  end

  local linked = {}
  -- this should be a fairly quick link resolver. It works by connecting links and shorting any
  -- links that were already connected. This lets us store the correct color information for each
  -- link node while also including the 'link'. This will let us do some cool stuff via selections (ie Include style).
  local resolve_link_chain = function (name, hi)
    local chain = {}
    local visited = {}
    local base_hi = hi
    local base_name = name
    -- whatever is the remaining base_hi contains the colors we want to use
    -- and apply to everything up the chain
    while base_hi.link do
      -- make sure we aren't in an infinite loop...yes this is a real case
      if not visited[base_hi.link] then
        visited[base_hi.link] = true
        -- this node is already linked
        if linked[base_hi.link] then
          -- we want to apply already linked to this node, add to chain
          -- set the correct base
          chain[base_name] = base_hi
          base_name = base_hi.link
          base_hi = output[base_name]
          break
        elseif not output[base_hi.link] then
          -- the last known good node is the current one. in this case this is the user visible node
          break
        end
        chain[base_name] = base_hi
        base_name = base_hi.link
        base_hi = output[base_name]
      else
        -- circular ref found base_hi is our last good one
        -- undefined behavior here, so consult api for a real highlight and hopefully its right
        -- this does not seem to occur < 0.10.0, so not using COMPAT here
        circular_hi = vim.api.nvim_get_hl(real_ns, {name = base_name, link = false})
        base_hi.ctermfg = circular_hi.ctermfg
        base_hi.ctermbg = circular_hi.ctermbg
        base_hi.fg = circular_hi.fg
        base_hi.bg = circular_hi.bg
        base_hi.sp = circular_hi.sp
        base_hi.blend = circular_hi.blend
        -- unlink these immediately. Not only are the output highlights inconsistent from nvim api functions,
        -- but they render inconsistently too! TODO: revisit one day and hopefully delete this.
        base_hi.link = nil
        break
      end
    end
    -- take the values from base_hi and apply to each item in its chain
    for name, linked_hi in pairs(chain) do
      linked[name] = linked_hi
      linked_hi.ctermfg = base_hi.ctermfg
      linked_hi.ctermbg = base_hi.ctermbg
      linked_hi.fg = base_hi.fg
      linked_hi.bg = base_hi.bg
      linked_hi.sp = base_hi.sp
      linked_hi.blend = base_hi.blend
    end
  end
  for name, hi in pairs(output) do
    if hi.link then
      resolve_link_chain(name, hi)
    end
  end
  return output
end

M.get_replacement = function (win, real_ns, hi_key, skip_create)
  local key = real_ns .. ':' .. hi_key

  local ns = M.key_lookup[key]
  if ns == nil then
    if skip_create then
      return nil
    end
    ns = {
      key = key,
      real_ns = real_ns,
      vimade_ns = table.remove(M.free_ns) or vim.api.nvim_create_namespace('vimade_' .. get_next_id()),
      windows = {},
    }
    M.key_lookup[key] = ns
    M.vimade_active_ns_lookup[ns.vimade_ns] = ns
    M.used_ns[ns.vimade_ns] = true
  end

  local current_win_ns = M.winid_lookup[win.winid]
  if current_win_ns and current_win_ns ~= ns then
    M.clear_winid(win.winid)
  end

  ns.windows[win.winid] = win
  M.winid_lookup[win.winid] = ns

  -- refresh highlights and changed state --
  M.check_ns_modified(ns)

  return ns
end

M.check_ns_modified = function(ns)
  if ns.tick_id ~= GLOBALS.tick_id then
    ns.tick_id = GLOBALS.tick_id
    local highlights = COMPAT.nvim_get_hl(ns.real_ns, {})
    if TYPE.deep_compare(ns.real_highlights, highlights) == false then
      ns.modified = true
      -- only resolve links again if the ns was actually modified
      ns.complete_highlights = resolve_all_links(ns.real_ns, highlights)
    else
      ns.modified = false
    end
    ns.real_highlights = highlights
  end
end

M.is_vimade_ns = function (vimade_ns)
  return M.used_ns[vimade_ns] ~= nil
end

M.from_winid = function (winid)
  local result = M.winid_lookup[winid]
  return result and result.vimade_ns
end

M.clear_winid = function (winid)
  local current_win_ns = M.winid_lookup[winid] 
  if current_win_ns ~= nil then
    current_win_ns.windows[winid] = nil
    if not next(current_win_ns.windows) then
      M.key_lookup[current_win_ns.key] = nil
      M.vimade_active_ns_lookup[current_win_ns.vimade_ns] = nil
      table.insert(M.free_ns, current_win_ns.vimade_ns)
    end
  end
end

return M

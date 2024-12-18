local M = {}

local TYPE = require('vimade.util.type')
local COMPAT = require('vimade.util.compat')
local HIGHLIGHTER = require('vimade.highlighter')
local ANIMATOR = require('vimade.animator')
local GLOBALS
local FADER
local TABLE_INSERT = table.insert

local NVIM_GET_HL = COMPAT.nvim_get_hl
local global_sync_id = 1

M.__init = function (args)
  GLOBALS = args.GLOBALS
  FADER = args.FADER

  FADER.on('tick:before', function ()
    -- logic below defers invalidations during an animation. If the namespace source
    -- changes, we'll recompute afterwards.
    if next(M.cache) ~= nil and not ANIMATOR.animating then
      M.pending_removal = M.cache
      M.cache = {}
    end
  end)
end

M.resolve_all_links = function (real_ns, real_highlights, is_global)
  local copy_ns
  if GLOBALS.termguicolors then
    copy_ns = TYPE.copy_hl_ns_gui
  else
    copy_ns = TYPE.copy_hl_ns_cterm
  end
  local globals = copy_ns(is_global and real_highlights or GLOBALS.global_highlights)
  local overrides = real_ns ~= 0 and copy_ns(real_highlights) or {}
  local output = {}
  local visited = {}

  local walk_links = function (start_name, start_hi, start_ns)
    local hi = start_hi
    local name = start_name
    local ns = start_ns
    local real_walked = {}
    local global_walked = {}

    local chain = {}
    -- functions to try and get fake_ns, fallback to global in a number of conditions
    -- this unfortunately works in scenarios where Neovim breaks, so its not an exact match.
    -- Neovim seems to break in many circular scenarios and just shows colors that are derived
    -- somewhere on the link tree but for no apparent visible reason.
    local mark_and_next = function (name)
      if ns == 0 then
        if global_walked[name] then
          return nil
        else
          global_walked[name] = true
          return globals[name]
        end
      else
        if real_walked[name] then
          if global_walked[name] then
            return nil
          else
            global_walked[name] = true
            return globals[name]
          end
        elseif overrides[name] then
          real_walked[name] = true
          return overrides[name]
        else
          real_walked[name] = true
          global_walked[name] = true
          return globals[name]
        end
      end
    end

    hi = mark_and_next(name)
    local circular = false
    while hi do
      TABLE_INSERT(chain, {hi= hi, name = name})
      if not hi.link then
        break
      end
      local maybe_next_name = hi.link
      local maybe_next = mark_and_next(maybe_next_name)
      if maybe_next == nil then
        -- break early if we encounter a circular chain so that
        -- we have the last good highlight
        circular = true
        break
      end
      hi = maybe_next
      name = maybe_next_name
      -- if we've already visited this node we are done, break early
      -- and use the already processed hi
      local visited_hi = visited[name]
      if visited_hi then
        hi = visited_hi 
        break
      end
    end

    if circular == true then
      -- for circular handling we try our "best".  Get the "actual" color
      -- which is often wrong, fallback to global, and break the link
      local hi_conf = {name = name, link = false}
      hi = NVIM_GET_HL(real_ns, hi_conf)
      if hi.link or next(hi) == nil then
        hi = NVIM_GET_HL(0, hi_conf)
      end
      hi.link = nil
    end

    -- apply the final highlights to each of the linked nodes
    for i, linked in ipairs(chain) do
      -- replace the link chain with the end highlight
      -- if it was circular, its now disconnected
      -- (see hi.link = nil above)
      -- TODO its likely we can re-enable the logic to keep links
      -- without requiring the whole tree.  This method is mostly
      -- to fix animated fademode='windows'
      linked.hi = hi
      visited[linked.name] = hi
      hi.link = nil
    end
    return chain
  end

  local output = {}

  for name, override in pairs(overrides) do
    if override.link  then
      local chain = walk_links(name, override, real_ns)
      for i, linked in pairs(chain) do
        local linked_hi = linked.hi
        if linked_hi.fg or linked_hi.bg or linked_hi.sp or linked_hi.ctermfg or linked_hi.ctermbg or linked_hi.blend then
          output[linked.name] = linked_hi
        end
      end
      -- TODO cleanup, this is ugly
    elseif override.fg or override.bg or override.sp or override.ctermfg or override.ctermbg or override.blend then
      output[name] = override
    end
  end

  for name, override in pairs(globals) do
    -- repeat for globals, but ensure we don't overwrite anything existing
    if override.link  then
      local chain = walk_links(name, override, 0)
      for i, linked in pairs(chain) do
        local linked_name = linked.name
        local linked_hi = linked.hi
      -- TODO cleanup, this is ugly
        if not output[name] and (linked_hi.fg or linked_hi.bg or linked_hi.sp or linked_hi.ctermfg or linked_hi.ctermbg or linked_hi.blend) then
          output[linked_name] = linked_hi
        end
      end
    elseif not output[name] and (override.fg or override.bg or override.sp or override.ctermfg or override.ctermbg or override.blend) then
      output[name] = override
    end
  end
  if output.Normal then
    -- do not try and grab NormalNC -> Neovim will fail to lookup the correct colors for circular highlights
    -- only use link resolving logic above
    output.Normal.link = nil
    output.Normal.foreground = nil
    output.Normal.background = nil
  end
  if output.NormalNC then
    -- do not try and grab NormalNC -> Neovim will fail to lookup the correct colors for circular highlights
    -- only use link resolving logic above
    output.NormalNC.link = nil
    output.NormalNC.foreground = nil
    output.NormalNC.background = nil
  end
  return output
end

M.is_desync = function(ns)
  local global_ns = M.cache[0] or M.pending_removal[0]
  return ns.id ~= 0 and global_ns and ns.sync_id ~= global_ns.sync_id
end

M.pending_removal = {}
M.cache = {}
M.refresh = function (real_ns, is_global)
  local ns = M.cache[real_ns]
  local filter_ns
  local equal_ns
  if GLOBALS.termguicolors then
    filter_ns = TYPE.filter_ns_gui
    equal_ns = TYPE.equal_ns_gui
  else
    filter_ns = TYPE.filter_ns_cterm
    equal_ns = TYPE.equal_ns_cterm
  end
  if not ns then
    ns = {}
    local global_ns = M.cache[0]
    local last = M.pending_removal[real_ns]
    M.cache[real_ns] = ns
    ns.id = real_ns
    ns.sync_id = last and last.sync_id
    ns.highlights = NVIM_GET_HL(real_ns, {link = true})
    filter_ns(ns.highlights)
    if bit.band(GLOBALS.tick_state, GLOBALS.RECALCULATE) > 0 then
      ns.modified = true 
    elseif real_ns ~= 0 and 
      (global_ns and (global_ns.modified or ns.sync_id ~= global_ns.sync_id)) then
      ns.modified = true
    elseif last == nil then
      ns.modified = true
    elseif last ~= nil then
      if equal_ns(last.highlights, ns.highlights) == false then
        ns.modified = true
      end
    end
    if (not last or not last.complete_highlights) or ns.modified then
      ns.complete_highlights = M.resolve_all_links(real_ns, ns.highlights, is_global)
      -- lets us know when to resync non-global namespaces
      -- this is atypical behavior but can occur if the global namespace
      -- changes on a different tab, gets synchronized and then user
      -- switches to a tab with separate namespaces
      if is_global then
        global_sync_id = global_sync_id + 1
      end
      ns.sync_id = global_sync_id
    else
      ns.complete_highlights = last.complete_highlights
    end
  end
  return ns
end

return M

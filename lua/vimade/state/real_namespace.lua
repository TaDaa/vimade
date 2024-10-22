local M = {}
local TYPE = require('vimade.util.type')
local COMPAT = require('vimade.util.compat')
local HIGHLIGHTER = require('vimade.highlighter')
local GLOBALS
local FADER

M.__init = function (args)
  GLOBALS = args.GLOBALS
  FADER = args.FADER

  FADER.on('tick:before', function ()
    if next(M.cache) ~= nil then
      M.pending_removal = M.cache
      M.cache = {}
    end
  end)
end

local REQUIRED_GUI_HI_KEYS = {
  fg = true,
  bg = true,
  sp = true,
  blend = true,
  --link = true,
}
local REQUIRED_CTERM_HI_KEYS = {
  ctermfg = true,
  ctermbg = true,
  --- sp is required in 256 mode to render correctly
  sp = true,
  --link = true,
}
local VALID_CTERM_KEYS = {
  cterm = true,
  --link = true
}
local VALID_SP = {
  bold = true,
  standout = true,
  underline = true,
  undercurl = true,
  underdouble = true,
  underdotted = true,
  underdashed = true,
  strikethrough = true,
  italic = true,
  reverse = true,
  nocombine = true,
  cterm = true,
}

local filter_hi = function (hi)
  local has_required = false
  local valid_keys
  local required_keys
  if GLOBALS.termguicolors == true then
    required_keys = REQUIRED_GUI_HI_KEYS
    hi.cterm = {}
  else
    required_keys = REQUIRED_CTERM_HI_KEYS
  end
  for key, v in pairs(hi) do
    if required_keys[key] ~= nil then
      has_required = true
    elseif GLOBALS.termguicolors == false then
      if key == 'cterm' then
        for k, c in pairs(v) do
          if not VALID_SP[k] == nil then
            v[k] = nil
          end
        end
      else
        hi[key] =nil
      end
    elseif VALID_SP[key] == nil then
      hi[key] = nil
    end
  end
  if has_required == false then
    return nil
  end
  return hi
end


local resolve_all_links = function (real_ns, real_highlights)
  local globals = TYPE.deep_copy(GLOBALS.global_highlights)
  local overrides = real_ns ~= 0 and TYPE.deep_copy(real_highlights) or {}
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
      table.insert(chain, {hi= hi, name=name})
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
      if visited[name] then
        hi = visited[name]
        break
      end
    end

    if circular == true then
      -- for circular handling we try our "best".  Get the "actual" color
      -- which is often wrong, fallback to global, and break the link
      hi = COMPAT.nvim_get_hl(real_ns, {name = name, link=false})
      if hi.link or next(hi) == nil then
        hi = COMPAT.nvim_get_hl(0, {name = name, link=false})
      end
      hi.link = nil
    end

    -- apply the final highlights to each of the linked nodes
    for i, linked in pairs(chain) do
      local linked_hi = linked.hi
      -- replace the link chain with the end highlight
      -- if it was circular, its now disconnected
      -- (see hi.link = nil above)
      -- TODO its likely we can re-enable the logic to keep links
      -- without requiring the whole tree.  This method is mostly
      -- to fix animated fademode='windows'
      chain[i].hi = hi
      visited[linked.name] = hi
      hi.link = nil
    end
    return chain
  end

  local output = {}

  for name, override in pairs(overrides) do
    if override.link  then
      -- walk each link in the override ns and incude them in the output
      local chain = walk_links(name, override, real_ns)
      for i, linked in pairs(chain) do
        output[linked.name] = filter_hi(linked.hi)
      end
    else
      output[name] = filter_hi(override)
    end
  end

  for name, override in pairs(globals) do
    -- repeat for globals, but ensure we don't overwrite anything existing
    if override.link  then
      local chain = walk_links(name, override, 0)
      for i, linked in pairs(chain) do
        if not output[linked.name] then
          output[linked.name] = filter_hi(linked.hi)
        end
      end
    elseif not output[name] then
      output[name] = filter_hi(override)
    end
  end
  if output.Normal then
    -- do not try and grab NormalNC -> Neovim will fail to lookup the correct colors for circular highlights
    -- only use link resolving logic above
    output.Normal.link = nil
  end
  if output.NormalNC then
    -- do not try and grab NormalNC -> Neovim will fail to lookup the correct colors for circular highlights
    -- only use link resolving logic above
    output.NormalNC.link = nil
  end
  return output
end

M.pending_removal = {}
M.cache = {}
M.refresh = function (real_ns)
  if not M.cache[real_ns] then
    local ns = {}
    local last = M.pending_removal[real_ns]
    M.cache[real_ns] = ns
    ns.highlights = COMPAT.nvim_get_hl(real_ns, {link=true})
    ns.complete_highlights = resolve_all_links(real_ns, ns.highlights)

    local modified = true
    if bit.band(GLOBALS.tick_state, GLOBALS.RECALCULATE) > 0 then
      -- pass
    elseif last ~= nil then
      modified = TYPE.deep_compare(last.complete_highlights, ns.complete_highlights) == false
    end
    ns.modified = modified
  end
  return M.cache[real_ns]
end

return M

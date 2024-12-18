local M = {}

local DEEP_COMPARE
local DEEP_COPY
local SHALLOW_EXTEND
local RESOLVE_ALL_FN

local truthyness = function(maybe_num, value)
  return maybe_num == value
    or ((maybe_num == 1 or maybe_num == true) and (value == 1 or value == true))
    or ((maybe_num == 0 or maybe_num == false) and (value == 0 or value == false))
end

M.num_to_bool = function (maybe_num, default)
  if maybe_num == nil then
    return default
  elseif maybe_num == 0 then
    return false
  else
    return true
  end
end

M.shallow_compare = function (left, right)
  if (left == nil or right == nil) then
    return left == right
  end
  for k, v in pairs(left) do
    if right[k] ~= v then
      return false
    end
  end
  for k, v in pairs(right) do
    if left[k] ~= v then
      return false
    end
  end
  return true
end

M.deep_compare = function (left, right)
  if (left == nil or right == nil) then
    return left == right
  end
  local copy = {}
  for key, value in pairs(left) do
    copy[key] = value
  end
  for key, value in pairs(right) do
    local copy_value = copy[key]
    if copy_value == nil then
      return false
    elseif type(copy_value) ~= type(value) then
      return false
    elseif type(value) == 'table' then
      if DEEP_COMPARE(copy_value, value) == true then
        copy[key] = nil
      else
        return false
      end
    elseif copy_value == value then
      copy[key] = nil
    else
      return false
    end
  end
  if next(copy) ~= nil then
    return false
  end
  return true
end
DEEP_COMPARE = M.deep_compare

M.deep_copy = function (value)
  if value == nil then
    return value
  end
  local result = {}
  for k, v in pairs(value) do
    if type(v) == 'table' then
      result[k] = DEEP_COPY(v)
    else
      result[k] = v
    end
  end
  return result
end
DEEP_COPY = M.deep_copy

M.shallow_copy = function (value)
  return SHALLOW_EXTEND({}, value)
end

M.shallow_extend = function (base, ...)
  for i, target in ipairs({...}) do
    if target ~= nil then
      for key, value in pairs(target) do
        base[key] = value
      end
    end
  end
  return base
end
SHALLOW_EXTEND = M.shallow_extend
M.extend = SHALLOW_EXTEND

M.deep_extend = function (base, ...)
  base = DEEP_COPY(base)
  for i, target in ipairs({...}) do
    target = DEEP_COPY(target)
    SHALLOW_EXTEND(base, target)
  end
  return base
end

M.resolve_all_fn = function (obj, ...)
  if type(obj) == 'function' then
    obj = obj(...)
  end
  if type(obj) == 'table' then
    local copy = {}
    for i, v in pairs(obj) do
      copy[i] = RESOLVE_ALL_FN(v, ...)
    end
    return copy
  end
  return obj
end
RESOLVE_ALL_FN = M.resolve_all_fn


-- Functions below are intended to be more efficient, they are for internal use only
-- more efficient version of copy, filtering, and equality behaviors for higlights and
-- namespaces
M.copy_hl = function(obj)
  local hl = {}
  for k, value in pairs(obj) do
    hl[k] = value
  end
  if hl.cterm then
    local cterm = {}
    hl.cterm = cterm
    for k, value in pairs(obj.cterm) do
      cterm[k] = value
    end
  end
  return hl
end

M.copy_hl_ns_gui = function(obj, gui)
  local ns = {}
  for hl_name, obj_hl in pairs(obj) do
    local hl = {}
    ns[hl_name] = hl
    for k, value in pairs(obj_hl) do
      hl[k] = value
    end
  end
  return ns
end

M.copy_hl_ns_cterm = function(obj, gui)
  local ns = {}
  for hl_name, obj_hl in pairs(obj) do
    local hl = {}
    ns[hl_name] = hl
    for k, value in pairs(obj_hl) do
      hl[k] = value
    end
    if obj.cterm then
      local cterm = {}
      hl.cterm = cterm
      for k, value in obj.cterm do
        cterm[k] = value
      end
    end
  end
  return ns
end

M.filter_ns_gui = function (obj)
  for name, hl in pairs(obj) do
    if hl.cterm then
      hl.cterm = nil
    end
    if hl.ctermfg then
      hl.ctermfg = nil
    end
    if hl.ctermbg then
      hl.ctermbg = nil
    end
  end
  return obj
end
M.filter_ns_cterm = function (obj)
  for name, hl in pairs(obj) do
    for k, v in pairs(hl) do
      if k ~= 'sp' and k ~= 'link' and k:sub(1,5) ~= 'cterm' then
        hl[k] = nil
      end
    end
  end
  return obj
end

-- expects pre-filtered ns
M.equal_ns_gui = function (ns_a, ns_b)
  for name, hi in pairs(ns_a) do
    local target = ns_b[name]
    if not target then
      return false
    end
    for k, v in pairs(hi) do
      if target[k] ~= v then
        return false
      end
    end
    for k, v in pairs(target) do
      if not hi[k] then
        return false
      end
    end
  end
  for name, hi in pairs(ns_b) do
    if not ns_a[name] then
      return false
    end
  end
  return true
end

M.equal_ns_cterm = function (ns_a, ns_b)
  for name, hi in pairs(ns_a) do
    local target = ns_b[name]
    if not target
      or target.ctermfg ~= hi.ctermfg
      or target.ctermbg ~= hi.ctermbg
      or target.sp ~= hi.sp then
      return false
    end
    local cterm = hi.cterm
    local target_cterm = target.cterm
    if (cterm and not target_cterm)
      or (not cterm and target_cterm) then
        return false
    elseif cterm and target_cterm then
      for k, v in pairs(cterm) do
        if target_cterm[k] ~= v then
          return false
        end
      end
      for k, v in pairs(target_cterm) do
        if not cterm[k] then
          return false
        end
      end
    end
  end
  return true
end

return M

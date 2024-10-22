local M = {}

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
  if (left == nil or right == nil) and left ~= right then
    return false
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
  if (left == nil or right == nil) and left ~= right then
    return false
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
      if M.deep_compare(copy_value, value) == true then
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

M.deep_copy = function (value)
  if value == nil then
    return value
  end
  local result = {}
  for key, v in pairs(value) do
    if type(v) == 'table' then
      result[key] = M.deep_copy(v)
    else
      result[key] = v
    end
  end
  return result
end

M.shallow_copy = function (value)
  return M.shallow_extend({}, value)
end

M.shallow_extend = function (base, target)
  if target ~= nil then
    for key, value in pairs(target) do
      base[key] = value
    end
  end
  return base
end

M.deep_extend = function (base, target)
  base = M.deep_copy(base)
  target = M.deep_copy(target)
  return M.shallow_extend(base, target)
end

return M

local M = {}

M.match_contains_any = function(target, value)
  -- second is the target and value a table?
  -- If yes, continue the recursion step
  if type(target) == 'table' and type(value) == 'table' then
    return M.match_table_any(target, value)
  -- otherwise outer compare the target to a real value
  -- from here on out
  elseif type(target) == 'table' then
    for i, v in pairs(target) do
      if M.match_contains_any(v, value) then
        return true
      end
    end
  else
    return M.match_primitive(target, value)
  end
end

M.match_table_any = function(target, value)
  for target_key, target_value in pairs(target) do
    if type(target_key) == 'number' then
      -- numbers are skipped as this is listy
      -- we assume things can be out of order here, so every
      -- item must be checked
      for real_key, real_value in pairs(value) do
        if M.match_contains_any(target_value, real_value) then
          return true
        end
      end
    else
      if M.match_contains_any(target_value, value[target_key], M.match_table_any) then
        return true
      end
    end
  end
  return false
end

M.each_match_contains_any = function(target, values)
 local count_ln = table.getn(values)
 local counts = {}
 for i, value in pairs(values) do
   if M._each_match_contains_any(target, value, counts, count_ln, i) == true then
     return true
   end
 end
end

M._each_match_contains_any = function(target, value, counts, counts_ln, i)
  for key, t in pairs(target) do
    --print(key, t)
    counts[key] = counts[key] or {count=0}
    local found = false
    if type(key) == 'number' then
      if type(t) == 'function' and type(value) == 'table' then
        for j, v in pairs(value) do
          if t(v) == true then
            found = true
          end
        end
      -- in this scenario every value key needs to be checked
      -- this is because we don't necessarily care about the order
      -- of a list and should accept any value present as a possible match
      -- consider target={{1}} and value={{2,1} f.  Even though 2 is index=0,
      -- this should still return true
      elseif type(t) == 'table' and type(value) == 'table' then
        for j, v in pairs(value) do
          if M._each_match_contains_any(t, v, counts[key], counts_ln, i) then
            -- finding a nested match means we are just done
            return true
          end
        end
      -- consider target={1} value={1}
      -- key=1, t=1, value is a table
      -- we need to see if t is present in value
      elseif type(value) == 'table' then
       for j, v in pairs(value) do
         if M.match_primitive(t, v) then
           found = true
         end
       end
      -- consider target={1} value=1
      -- key=1, t=1, t == 1
      elseif M.match_primitive(t, value) then
        found = true
      end
    else
      if type(t) == 'function' and type(value) == 'table' then
        if t(value[key]) == true then
          found = true
        end
      -- consider target={wtf={abc=1}} value={{wtf={abc=1}}}
      -- key=wtf, value={abc=1}  compare value[wtf]
      elseif type(t) == 'table' and type(value) == 'table' then
        if M._each_match_contains_any(t, value[key], counts[key], counts_ln, i) then
          return true
        end
      -- consider target={wtf=1} value={wtf=1}
      -- key=wtf, t=1, value={wtf=1}
      elseif type(value) == 'table' then
        --print('here', value[key], value)
        if M.match_primitive(t, value[key]) then
          found = true
        end
      elseif M.match_primitive(t, value) then
        found = true
      end
    end
    if found and counts[key].count == i - 1 then
      counts[key].count = i
    end
    if counts[key].count == counts_ln then
      return true
    end
  end
  return false
end

M.match_contains_all = function(target, value)
  return M.each_match_contains_all(target, {value})
end

M.match_table_all = function(target, value)
  for target_key, target_value in pairs(target) do
    local found = false
    if type(target_key) == 'number' then
      -- numbers are skipped as this is listy
      -- we assume things can be out of order here, so every
      -- item must be checked
      for real_key, real_value in pairs(value) do
        if type(target_value) == 'function' then
          found = target_value(real_value)
        elseif type(target_value) == 'table' and type(real_value) == 'table' then
          found = M.match_table_all(target_value, real_value)
        else
          -- outer compare
          found = M.match_contains_any(target_value, real_value)
        end
      end
    else
      if type(target_value) == 'function' then
        found = target_value(value[target_key])
      elseif type(target_value) == 'table' and type(value[target_key]) == 'table' then
        found = M.match_table_all(target_value, value[target_key])
      else
        found = M.match_contains(target_value, value[target_key])
      end
    end
    -- we don't care if the value has other keys, this is left match
    if not found then
      return false
    end
  end
  return true
end

M.each_match_contains_all = function(target, values)
  -- every target must contain every value
  for i, value in pairs(values) do
    local found
    -- second is the target and value a table?
    -- If yes, continue the recursion step
    if type(target) == 'table' and type(value) == 'table' then
      found = M.match_table_all(target, value)
    -- otherwise outer compare the target to a real value
    -- from here on out
    elseif type(target) == 'table' then
      for i, v in pairs(target) do
        if not M.match_contains_all(v, value) then
          found = false
          break
        end
      end
    else
      found = M.match_primitive(target, value)
    end
    if found == false then
      return false
    end
  end
end

M.match_primitive = function(target, value)
  if type(target) == 'function' then
    return target(value)
  elseif type(target) == 'boolean' then
    if target then
      return M.match_truthy(value)
    else
      return M.match_falsy(value)
    end
  elseif (type(target) == 'number' or type(target) == 'string')
    and (type(value) == 'number' or type(value) == 'string') then
    return target .. '' == value .. ''
  else
    return target == value
  end
end

M.match_truthy = function(value)
  return (value ~= nil and value ~= '' and value ~= false and value ~= 0) and true or false
end

M.match_falsy = function(value)
  return value ~= nil and (value == '' or value == false or value == 0) and true or false
end


M.match_contains_string = function(target, value)
  if target == nil then
    return false
  -- same as above function takes+riority
  elseif type(target) == 'function' then
    return target(value)
  -- target is a string, we do the comparison
  elseif type(target) == 'string'  then
    return M.match_string(target, value)
  -- target is a table, we need to see if value is within the table
  elseif type(target) == 'table' then
    for i, v in pairs(target) do
      if M.match_contains_string(v, value) then
        return true
      end
    end
  end
  return false
end

M.match_string = function(target, value)
  return string.find(string.lower(value), string.lower(target)) ~= nil
end

M.ContainsString = function(target)
  if type(target) == 'table' then
    return function(value)
      return M.match_contains_string(target, value)
    end
  else
    return function(value)
      return M.match_string(target, value)
    end
  end
end

M.ContainsAll = function(target)
  return function(value)
    return M.match_contains_all(target, value)
  end
end

M.EachContainsAll = function(target)
  return function(value)
    return M.each_match_contains_all(target, value)
  end
end

M.ContainsAny = function(target)
  return function(value)
    return M.match_contains_any(target, value)
  end
end

M.EachContainsAny = function(target)
  return function(values)
    return M.each_match_contains_any(target, values)
  end
end

M.IsFalsy = function ()
  return function (value)
    return M.match_falsy(value)
  end
end

M.IsTruthy = function ()
  return function (value)
    return M.match_truthy(value)
  end
end

M.StringMatcher = function (target)
  return function (value)
    if type(target) == 'table' then
      return M.match_contains_string(target, value)
    elseif type(target) == 'string' then
      return M.match_string(target, value)
    end
    return false
  end
end

return M

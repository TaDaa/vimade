local MATH_FLOOR = math.floor

-- generates keys at base 62
local KEYS = {0,1,2,3,4,5,6,7,8,9,'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'}
local TOTAL_KEYS = #KEYS
local TABLE_INSERT = table.insert
local TABLE_SORT = table.sort

return function()
  local id = 1
  local cache = {}
  local key_reducer = {}

  key_reducer.reduce = function(input)
    local key = cache[input]
    if key then
      return key
    end
    key = ''
    local i = id
    local r = 0
    while i > 0 do
      r = i % TOTAL_KEYS
      i = MATH_FLOOR(i / TOTAL_KEYS)
      key = KEYS[r + 1] .. key
    end
    cache[input] = key
    id = id + 1
    return key
  end
  key_reducer.reduce_ipairs = function(input)
    local output = ''
    for _, value in ipairs(input) do
      output = output .. key_reducer.reduce(value) .. ','
    end
    return output:sub(1,-2)
  end
  key_reducer.reduce_pairs_key = function(input)
    local keys = {}
    for key, value in pairs(input) do
      TABLE_INSERT(keys, key)
    end
    TABLE_SORT(keys)
    return key_reducer.reduce_ipairs(keys)
  end

  return key_reducer
end

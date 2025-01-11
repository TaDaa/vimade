return function()
  local callbacks = {}
  local events = {}
  events.on = function (name, callback)
    if not callbacks[name] then
      callbacks[name] = {}
    end
    table.insert(callbacks[name], callback)
  end

  events.notify = function (name)
    local callbacks = callbacks[name]
    if callbacks then
      for k, callback in ipairs(callbacks) do
        callback()
      end
    end
  end
  return events
end

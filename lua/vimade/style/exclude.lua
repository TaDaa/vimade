local M = {}

M.__init = function (args)
  GLOBALS = args.GLOBALS
end

M.exclude_names = {}
M.exclude_id = 1

-- @param config = {
--  names= {'Folded', 'VertSplit', 'Normal', ...}, # list of names that should be skipped on the style array
--  style = {Fade(0.4)} # styles to run on all names that aren't excluded
--}
M.Exclude = function(config)
  local result = {}
  result.attach = function (win)
    local names = config.names
    local style = {}
    for i, s in ipairs(config.style) do
      table.insert(style, s.attach(win))
    end
    local exclude = {}
    local exclude_ids = {}
    return {
      before = function ()
        exclude = {}
        exclude_ids = {}
        local input

        if type(names) == 'function' then
          input = names(win)
        else
          input = names
        end
        if type(input) == 'string' then
          input = {input}
        end
        -- order required to prevent invalidation
        for i, name in ipairs(input) do
          local name_id = M.exclude_names[name]
          if name_id == nil then
            name_id = M.exclude_id
            M.exclude_names[name] = name_id
            M.exclude_id = M.exclude_id + 1
          end
          if exclude[name] == nil then
            exclude[name] = name_id
            table.insert(exclude_ids, name_id)
          end
        end
        for i, s in ipairs(style) do
          s.before()
        end
      end,
      key = function (i)
        local key ='E-' .. table.concat(exclude_ids, ',') .. '('
        for j, s in ipairs(style) do
          if j ~= 0 then
            key = key .. ','
          end
          key = key .. s.key(j)
        end
        key = key .. ')'
        return key
      end,
      modify = function (hl, to_hl)
        if exclude[hl.name] then
          return
        end
        for i, s in ipairs(style) do
          s.modify(hl, to_hl)
        end
      end,
    }
  end
  -- value is not exposed here, no use-case currently
  return result
end
return M

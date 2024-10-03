local M = {}
if vim == nil or vim.api == nil or vim.treesitter == nil or vim.treesitter.highlighter == nil then
    return
end

--local parsers = {}
--local queries = require'nvim-treesitter.query'
--local parsers = require'nvim-treesitter.parsers'
--local hl_map = vim.treesitter.highlighter.hl_map
local lang_map = {}
local seen={}
local hl_is_string = nil

function dump(t,i)
    seen[t]=true
    local s={}
    local n=0
    for k in pairs(t) do
        n=n+1 s[n]=k
    end
    table.sort(s)
    for k,v in ipairs(s) do
        print(i,v)
        v=t[v]
        if type(v)=="table" and not seen[v] then
            dump(v,k.."\t")
        end
    end
end

function M.get_to_eval (bufnr, to_eval)
    if vim.treesitter.highlighter.active[bufnr] == nil then
        return
    end
    if lang_map[bufnr] == nil then
        for l in pairs(vim.treesitter.highlighter.active[bufnr]._queries) do
            lang_map[bufnr] = l
        end
    end
    local lang = lang_map[bufnr]
    if lang == nil then
      return nil
    end
    local query = vim.treesitter.highlighter.active[bufnr]:get_query(lang):query()
    local highlighter = vim.treesitter.highlighter.active[bufnr]

    local result = {}
    local rows = {}
    local startRow = nil
    local endRow = -1 
    for i, eval in pairs(to_eval) do
        local row = tonumber(eval[1])
        local col = tonumber(eval[2])
        local end_col = tonumber(eval[3])
        if startRow == nil or row < startRow then
            startRow = row
        end
        if row > endRow then
            endRow = row
        end
        rows[row] = {col,end_col}
    end
    endRow = endRow + 1

    highlighter.tree:for_each_tree(function (tstree, tree)
        if not tstree then return end
        local root_node = tstree:root()
        local root_start_row, _, root_end_row, _ = root_node:range()

        if root_start_row > startRow or root_end_row < startRow then return end

        local highlighter_query = highlighter:get_query(tree:lang())

        local q = highlighter_query:query():iter_captures(root_node, bufnr, startRow, endRow)
        local matches = q
        local next_row = 0
        for capture, node in matches do
            if capture == nil then
                -- pass
            end
                local capture_name = query.captures[capture]
                local hl = highlighter_query.hl_cache[capture]
                local rgb= nil
                if hl ~= 0 then
                    if hl_is_string == nil then
                        hl_is_string = type(hl) == 'string'
                    end
                    if hl_is_string == true then
                        hl = vim.api.nvim_get_hl_id_by_name(hl)
                    end
                    if type(hl) == 'number' then
                      rgb = vim.api.nvim_get_hl_by_id(hl, 1)
                    end
                end
                if rgb == nil then
                    rgb = {}
                end
                if hl and capture ~= 0 and (rgb['background'] ~= nil or rgb['foreground'] ~= nil) then
                    local sr,sc,er,ec = node:range()
                    local r
                    for r=sr,er do
                        if rows[r] ~= nil then
                            local columns = result[r..'']
                            if columns == nil then
                                columns = {}
                                result[r..''] = columns
                            end
                            local startCol = rows[r][1]
                            local endCol = rows[r][2]
                            local _sc = sc
                            local _ec = ec
                            local i
                            for i=_sc,_ec-1 do
                                if i >= startCol and i <= endCol then
                                    columns[i..''] = hl
                                end
                            end
                        end
                    end
                end
                ::next::
        end
    end)
    return result
end

function M.get_highlights (bufnr, startRow, endRow, startCol, endCol) 
    bufnr = tonumber(bufnr)
    startRow = tonumber(startRow)
    endRow = tonumber(endRow)
    startCol = tonumber(startCol)
    endCol = tonumber(endCol)
    if vim.treesitter.highlighter.active[bufnr] == nil then
        return
    end
    if lang_map[bufnr] == nil then
        for l in pairs(vim.treesitter.highlighter.active[bufnr]._queries) do
            lang_map[bufnr] = l
        end
    end
    local lang = lang_map[bufnr]
    local result = {}
    local query = vim.treesitter.highlighter.active[bufnr]:get_query(lang):query()

    local highlighter = vim.treesitter.highlighter.active[bufnr]
    highlighter.tree:for_each_tree(function (tstree, tree)
        if not tstree then return end
        local root_node = tstree:root()
        local root_start_row, _, root_end_row, _ = root_node:range()

        if root_start_row > startRow or root_end_row < startRow then return end

        local highlighter_query = highlighter:get_query(tree:lang())

        local q = highlighter_query:query():iter_captures(root_node, bufnr, startRow, endRow)
        local matches = q
        local next_row = 0
        for capture, node in matches do
            if capture == nil then
                break
            end
                local capture_name = query.captures[capture]
                --dump(capture)
                local hl = highlighter_query.hl_cache[capture]
                local rgb= nil
                if hl ~= 0 then
                    if hl_is_string == nil then
                        hl_is_string = type(hl) == 'string'
                    end
                    if hl_is_string == true then
                        hl = vim.api.nvim_get_hl_id_by_name(hl)
                    end
                    rgb = vim.api.nvim_get_hl_by_id(hl, 1)
                else
                    rgb = {}
                end
                if hl and capture ~= 0 and (rgb['background'] ~= nil or rgb['foreground'] ~= nil) then
                    local sr,sc,er,ec = node:range()
                    local r
                    local _sc = sc
                    local _ec = endCol

                    for r=sr,er do
                        if r > sr then
                            _sc = 0
                        end
                        if r == er then
                            _ec = ec - 1
                        end
                        if r >= startRow and r < endRow then
                            local i
                            for i=_sc,_ec do
                                if i >= startCol and i < endCol then
                                    result[i..''] = hl
                                end
                            end
                        end
                    end
                end
                ::next::
        end
    end)

    return result 
end
return M

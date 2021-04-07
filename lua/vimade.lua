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
            dump(v,i.."\t")
        end
    end
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

                    if sr > startRow or sc > endCol then
                        goto next
                    end

                    if sc < startCol then
                        sc = startCol
                    end

                    if ec > endCol then
                        ec = endCol
                    end

                    if sr < startRow then
                        sr = startRow
                        sc = startCol 
                    end

                    if er > startRow then
                        er = startRow
                        ec = endCol
                    end

                    ec = ec - 1

                    local i
                    for i=sc,ec do
                        result[i..''] = hl
                    end
                end
                ::next::
        end
    end)

    return result 
end

return M


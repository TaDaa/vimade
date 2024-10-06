local M = {}

-- nvim_get_hl
M.nvim_get_hl =
  -- default implementation + full support
  vim.api.nvim_get_hl
  -- fill previous implementations with missing attributes
  -- most notably bad attributes must be removed and
  -- 256 colors need to be filled.
  or (vim.api.nvim__get_hl_defs and
    function (ns, m)
      local result = vim.api.nvim__get_hl_defs(0)
      for name, highlight in pairs(result) do
        for key, attr in pairs(highlight) do
          if key == true or key == 'true' then
            highlight[key] = nil
          elseif key == 'foreground' then
            highlight['fg'] = attr
          elseif key == 'background' then
            highlight['bg'] = attr
          end
        end
        local term = vim.api.nvim_get_hl_by_name(name, false)
        for key, attr in pairs(term) do
          if key == 'foreground' then
            highlight['ctermfg'] = attr
          elseif key == 'background' then
            highlight['ctermbg'] = attr
          end
        end
      end
      return result
    end)

-- nvim_get_hl_ns may not exist in some versions, we can try
-- and track the last set ns peformed via vimade.  This may
-- break behaviors if other plugins set the ns.
if vim.api.nvim_get_hl_ns == nil then
  M.nvim_get_hl_ns = function (config)
    return vim.w[config.winid]._vimade_fallback_ns or 0
  end
  M.nvim_win_set_hl_ns = function (win, ns)
    vim.w[win]._vimade_fallback_ns = ns
    return vim.api.nvim_win_set_hl_ns(win, ns)
  end
else
-- versions with nvim_get_hl_ns should all behave as expected
  M.nvim_get_hl_ns = vim.api.nvim_get_hl_ns
  M.nvim_win_set_hl_ns = vim.api.nvim_win_set_hl_ns
end

return M

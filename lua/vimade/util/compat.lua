local M = {}

local FADER
local nvim__needs_redraw = false
-- best effort filled nvim__redraw (see tick:after below)
M.nvim__redraw = vim.api.nvim__redraw or function ()
  nvim__needs_redraw = true
end

M.__init = function(args)
  FADER = args.FADER
  if not vim.api.nvim__redraw then
    FADER.on('tick:after', function()
      nvim__needs_redraw = false
      vim.cmd('redraw')
    end)
  end
end

-- nvim_get_hl
M.nvim_get_hl =
  -- default implementation + full support
  vim.api.nvim_get_hl
  -- fill previous implementations with missing attributes
  -- most notably bad attributes must be removed and
  -- 256 colors need to be filled.
  or (vim.api.nvim__get_hl_defs and
    function (ns, m)
      if m.id == nil and m.name == nil then
        -- missing id and name, then we should return all highlights
        local result = vim.api.nvim__get_hl_defs(0)
        for name, highlight in pairs(result) do
          for key, attr in pairs(highlight) do
            if key == true or key == 'true' then
              highlight[key] = nil
            elseif key == 'foreground' then
              highlight.fg = attr
            elseif key == 'background' then
              highlight.bg = attr
            end
          end
          local term = vim.api.nvim_get_hl_by_name(name, false)
          -- cterm colors are missing using get_hl_defs
          for key, attr in pairs(term) do
            if key == 'foreground' then
              highlight.ctermfg = attr
            elseif key == 'background' then
              highlight.ctermbg = attr
            end
          end
        end
        return result
      else
        local term
        local gui
        if m.id ~= nil then
          term = vim.api.nvim_get_hl_by_id(m.id, false)
          gui = vim.api.nvim_get_hl_by_id(m.id, true)
        else
          term = vim.api.nvim_get_hl_by_name(m.name, false)
          gui = vim.api.nvim_get_hl_by_name(m.name, true)
        end
        return {
          ctermfg = term.foreground,
          ctermbg = term.background,
          fg = gui.foreground,
          bg = gui.background,
          sp = gui.special,
        }
      end
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

local TYPE = require('vimade.util.type')

local DEFAULTS = {
  providers = {
    filetypes = {
      default = {
        -- If you use mini.indentscope, snacks.indent, or hlchunk, you can also highlight the indent scope!
        -- {'snacks', {}},
        -- {'mini', {}},
        -- {'hlchunk', {}},
        {'treesitter', {
          min_node_size = 2, 
          min_size = 1,
          max_size = 0,
          -- exclude types either too large and/or mundane
          exclude = {
            'script_file',
            'stream',
            'document',
            'source_file',
            'translation_unit',
            'chunk',
            'module',
            'stylesheet',
            'statement_block',
            'block',
            'pair',
            'program',
            'switch_case',
            'catch_clause',
            'finally_clause',
            'property_signature',
            'dictionary',
            'assignment',
            'expression_statement',
            'compound_statement',
          }
        }},
        -- if treesitter fails or there isn't a good match, fallback to blanks (similar to limelight)
        {'blanks', {
          min_size = 1,
          max_size = '35%'
        }},
        -- if blanks fails to find a good match, fallback to static 35%
        {'static', {
          size = '35%'
        }},
      },
      -- You can make custom configurations for any filetype.  Here are some examples.
      -- markdown = {{'blanks', {min_size=0, max_size='50%'}}, {'static', {max_size='50%'}}},
      -- javascript = {
        -- -- only use treesitter (no fallbacks)
      --   {'treesitter', { min_node_size = 2, include = {'if_statement', ...}}},
      -- },
      -- typescript = {
      --   {'treesitter', { min_node_size = 2, exclude = {'if_statement'}}}, -- TODO valid & exclue
      --   {'static', {size = '35%'}}
      -- },
      -- java = {
        -- -- mini with a fallback to blanks
        -- {'mini', {min_size = 1, max_size = 20}},
        -- {'blanks', {min_size = 1, max_size = '100%' }}, 
      -- },
    },
  }
}

local get_providers = function(providers)
  local result = {}
  for i, provider in ipairs(providers) do
    if provider[1] and type(provider[1]) == 'string' then
      local name = provider[1]:lower()
      local module = require('vimade.focus.providers.' .. name)
      table.insert(result, module(provider[2] or {}))
    else
      table.insert(result, provider)
    end
  end
  return result
end

return function(config)
  config = TYPE.deep_copy(config or {}) or {}
  config.providers = config.providers or {}
  config.providers.filetypes = config.providers.filetypes or {}

  local filetype_config = config.providers.filetypes

  for ft, ftconfig in pairs(filetype_config) do
    filetype_config[ft] = get_providers(ftconfig)
  end
  for ft, ftconfig in pairs(DEFAULTS.providers.filetypes) do
    if not filetype_config[ft] then
      filetype_config[ft] = get_providers(ftconfig)
    end
  end

  return config
end




<table>
<tbody>
  <tr><td align="center">
 
<picture>
  <source media="(prefers-color-scheme: light)" srcset="https://tadaa.github.io/images/logo-transformed%20(1).png">
  <source media="(prefers-color-scheme: dark)" srcset="https://tadaa.github.io/images/logo-transformed-inv.png#gh-dark-mode-only">
  <img width="400" alt="" src="https://tadaa.github.io/images/logo-transformed%20(1).png#gh-light-mode-only">
</picture>


  </td></tr>
<tr>
  <td align="center">
    
**Dim, Fade, Tint, and Customize (Neo)vim**
  </td>
</tr>
<tr>
  <td>
    <img src="https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/minimalist_full.gif"></img>      
  </td>
</tr>
</tbody>
</table>




## What is this?

**Vimade** helps you maintain focus on the active part of the screen, especially when working with many
open windows. It let's you dim, fade, tint, animate, and customize colors in your windows and
buffers.


## What is required?

**Neovim 0.8.0+**: This plugin supports a lua-only code path, you are all set!

**Vim7.4+** and **Neovim < 0.8.0**: Python or Python3 support is required. If using these older versions of Neovim, you'll need to install `pynvim`.

## Features
- [X] Fade or highlight windows or buffers.
- [X] Link windows so they change together (e.g. diffsplit)
- [X] Blocklist specific windows or buffers from customization.
- [X] Set Custom tints for a unique visual experience.
- [X] Prebuilt recipes for quick and easy customization.
- [X] Fully customizable (styles, recipes, and more).
- [X] Animated transitions for a smooth visual experience.
- [X] Automatically adjust to configuration changes.
- [X] Helpers to make inactive built-in highlights look better
- [X] Supports 256 color terminals and termguicolors.
- [X] Sub-milliscond Lua performance and highly optimized Python logic for Vim.
- [X] Preconfigured commands (VimadeEnable, VimadeDisable, VimadeRedraw, etc)
- [X] Supports all versions of Neovim and Vim 7.4+
- [X] Vim Documentation/Help

#### Whats coming?
- [ ] More awesome features and improvements! (details to be added later)




## Getting started:

<details open>
<summary>
<a><ins>Installation</ins></a>
<br>
</summary>

<br>

- Any plugin manager will work.
  You can also call `vimade.setup({...})` at any time to change any value without restarting (Neo)vim:

  <details open>
  <summary>
    <ins>For Lua users:</ins>
    </summary
 
  
  *<sub>::lua::lazy.nvim::</sub>*
  ```lua
    {{
      'tadaa/vimade',
      -- default opts (you can partially set these or configure them however you like)
      opts = {
        -- Recipe can be any of 'default', 'minimalist', 'duo', and 'ripple'
        -- Set animate = true to enable animations on any recipe.
        -- See the docs for other config options.
        recipe = {'default', {animate=false}},
        ncmode = 'buffers', -- use 'windows' to fade inactive windows
        fadelevel = 0.4, -- any value between 0 and 1. 0 is hidden and 1 is opaque.
        tint = {
          -- bg = {rgb={0,0,0}, intensity=0.3}, -- adds 30% black to background
          -- fg = {rgb={0,0,255}, intensity=0.3}, -- adds 30% blue to foreground
          -- fg = {rgb={120,120,120}, intensity=1}, -- all text will be gray
          -- sp = {rgb={255,0,0}, intensity=0.5}, -- adds 50% red to special characters
          -- you can also use functions for tint or any value part in the tint object
          -- to create window-specific configurations
          -- see the `Tinting` section of the README for more details.
        },

        -- Changes the real or theoretical background color. basebg can be used to give
        -- transparent terminals accurating dimming.  See the 'Preparing a transparent terminal'
        -- section in the README.md for more info.
        -- basebg = [23,23,23],
        basebg = '',
        -- prevent a window or buffer from being styled. You 
        blocklist = {
          default = {
            highlights = {
              laststatus_3 = function(win, active)
                -- Global statusline, laststatus=3, is currently disabled as multiple windows take ownership
                -- of the StatusLine highlight (see #85).
                if vim.go.laststatus == 3 then
                    -- you can also return tables (e.g. {'StatusLine', 'StatusLineNC'})
                    return 'StatusLine'
                end
              end,
              -- Prevent ActiveTabs from highlighting.
              'TabLineSel',
              -- Exact highlight names are supported:
              -- 'WinSeparator',
              -- Lua patterns are supported, just put the text between / symbols:
              -- '/^StatusLine.*/' -- will match any highlight starting with "StatusLine"
            },
            buf_opts = { buftype = {'prompt'} },
            -- buf_name = {'name1','name2', name3'},
            -- buf_vars = { variable = {'match1', 'match2'} },
            -- win_opts = { option = {'match1', 'match2' } },
            -- win_vars = { variable = {'match1', 'match2'} },
            -- win_type = {'name1','name2', name3'},
            -- win_config = { variable = {'match1', 'match2'} },
          },
          default_block_floats = function (win, active)
            return win.win_config.relative ~= '' and
              (win ~= active or win.buf_opts.buftype =='terminal') and true or false
          end,
          -- any_rule_name1 = {
          --   buf_opts = {}
          -- },
          -- only_behind_float_windows = {
          --   buf_opts = function(win, current)
          --     if (win.win_config.relative == '')
          --       and (current and current.win_config.relative ~= '') then
          --         return false
          --     end
          --     return true
          --   end
          -- },
        },
        -- Link connects windows so that they style or unstyle together.
        -- Properties are matched against the active window. Same format as blocklist above
        link = {},
        groupdiff = true, -- links diffs so that they style together
        groupscrollbind = false, -- link scrollbound windows so that they style together.
        -- enable to bind to FocusGained and FocusLost events. This allows fading inactive
        -- tmux panes.
        enablefocusfading = false,
        -- Time in milliseconds before re-checking windows. This is only used when usecursorhold
        -- is set to false.
        checkinterval = 1000,
        -- enables cursorhold event instead of using an async timer.  This may make Vimade
        -- feel more performant in some scenarios. See h:updatetime.
        usecursorhold = false,
        -- when nohlcheck is disabled the highlight tree will always be recomputed. You may
        -- want to disable this if you have a plugin that creates dynamic highlights in
        -- inactive windows. 99% of the time you shouldn't need to change this value.
        nohlcheck = true,
      }
    }}
  ```
  </details>

  *<sub>::lua::packer::</sub>*
  ```lua
  require('packer').startup(function()
    use({
      'TaDaa/vimade',
      config = function ()
        require('vimade').setup({
          recipe = {'default', {animate = false}},
          ncmode = 'buffers',
          fadelevel = 0.4,
          tint = {},
          -- see the lazy.nvim config above or `Lua defaults` for full breakdown
        })
      end,
    })
  end)
  ```

  *<sub>::lua::paq::</sub>*
  ```lua
  require 'paq' { 'TaDaa/vimade' }

  require('vimade').setup({
    recipe = {'default', {animate = false}},
    ncmode = 'buffers',
    fadelevel = 0.4,
    tint = {},
    -- see the lazy.nvim config above or `Lua defaults` for full breakdown
  })
  ```

  *<sub>::vimscript::vim-plug::</sub>*
  ```lua
    Plug 'TaDaa/vimade'
    lua << EOF
    require('vimade').setup({
      recipe = {'default', {animate = false}},
      ncmode = 'buffers',
      fadelevel = 0.4,
      tint = {},
      -- see the lazy.nvim config above or `Lua defaults` for full breakdown
    })
    EOF
  ```

  <details open>
  <summary>
    <ins>For Python users:</ins>
    
    
  If you are using **vim** or older versions of **neovim** and want to configure using **python**, you need to bind your setup to `Vimade#PythonReady`.
  This ensures that **Vimade** has been added to the python path before your configuration runs.
    
  </summary>

  ```vim
  function! SetupMyVimadeConfig()
  python << EOF
  from vimade import vimade
  vimade.setup(
    recipe = ['default', {'animate':False}],
    ncmode = 'buffers',
    fadelevel = 0.4,
    tint = {},
    enablefocusfading = False,
    basebg = '',
    # all options listed in `Python defaults` section of README.md
   )
  EOF
  endfunction
  au! User Vimade#PythonReady call SetupMyVimadeConfig()
  ```
  </details>
  
---

</details>

<details>
<summary>
<a><ins>Lazy loading</ins></a>
<br>
</summary>
<br>

- In **Neovim** 0.8.0+, use **lazy.nvim** or similar plugin manager and the event of choice:

    *<sub>::lua::lazy::</sub>*
    ```lua
    require('lazy').setup({spec = {'tadaa/vimade', event = 'VeryLazy'}})
    ```

- For **Vim** or more granular control, enable `vimade.lazy` and call `vimade#Load()`:

  &nbsp;  *<sub>::vimscript::</sub>*
     ```vim
     let g:vimade = {}
     let g:vimade.lazy = 1
     
     au WinEnter * ++once call vimade#Load()
     ```

  
---

</details>

<details>
<summary>
<a><ins>Configuring Vimade (a basic guide)</ins></a>
 
</summary>
<br>

**Vimade** works by just installing it and no configuration is required.  However, it also offers extensive
customizations.  Most users may want to adjust the fadelevel and tint. You can configure **Vimade**
using Vimscript, Lua, or Python.

If you prefer a general configuration compatible with both Neovim and Vim, Vimscript is a good option.
You can also apply the Lua and Python-specific parts on top of these options, so nothing is 
mutually exclusive.

*<sub>::vimscript::</sub>*
```vim
let g:vimade = {}
```

This initializes a `vimade` object for configuration.  **Vimade** will automatically extend it with
 default values.
 
 Now let's start adding changes:


*<sub>::vimscript::</sub>*
```vim
let g:vimade.fadelevel = 0.5
```

This code changes the opacity of inactive windows.  You can choose any value between `0` (completely faded)
and `1` (fully opaque).

Let's add a blue tint:


*<sub>::vimscript::</sub>*
```vim
let g:vimade.tint = {'fg':{'rgb':[0,0,255], 'intensity': 0.5}}
```


You should notice that your text color has changed. The *tint* option can manipulate `fg`, `bg`, and `sp` attributes. Changing `vimade.tint.bg`
lets you customize the background color of inactive windows.


Let's try something a bit more complicated, suppose we have a filetree that we don't want to dim as extremely as our other windows.
You may remember that I said we need to configure functions directly in **python** or **lua**, so let's take a look:


 <sub> ::lua:: </sub>
```lua
require('vimade').setup{
  fadelevel = function(style, state)
    if style.win.buf_opts.syntax == 'nerdtree' then
      return 0.8
    else
      return 0.4
    end
  end}
```
 
 <sub> ::python:: </sub>
```python
from vimade import vimade
vimade.setup(
  fadelevel = lambda style, state:
    0.8 if style.win.buf_opts['syntax'] == 'nerdtree'
    else 0.4)
```

Both languages use almost identitical syntax for configuration.


Advanced configurations in **python** and **lua** are treated as overlays, whatever you pass through the **setup** functions will overlay
on top of your **vimscript** configuration. This means you won't be able to do an advanced configuration, then override it with
a **vimscript** configuration after.  You'll need to unset the advanced configuration first, which can be done as seen below
 
 <sub> ::lua:: </sub>
```lua
-- sets the overlay back to empty
require('vimade').setup{}
```
 
 <sub> ::python:: </sub>
```python
from vimade import vimade
# sets the overlay back to empty
vimade.setup()
```

You now know the basics for configuring **Vimade**!

---

</details>

</details>

<details>
<summary><a><ins>Vimscript defaults</ins></a></summary>

<sub>::vimscript::</sub>
```vim
let g:vimade = {
\   " common options below
\   'renderer': 'auto',
\   'ncmode': 'buffers',
\   'fadelevel': 0.4,
\   'tint': '',
\   'basebg': '',
\   'blocklist': {
\     'default': {
\       'buf_opts': {
\         'buftype': g:vimade_features.has_nvim ? ['prompt'] : ['popup', 'prompt']
\       },
\       'win_config':{
\         'relative': v:true
\       },
\     }
\   },
\   'link': {},
\   'groupdiff': 1,
\   'groupscrollbind': 0,
\   'checkinterval': 1000,
\   'usecursorhold': g:vimade_features.has_gui_running && !g:vimade_features.has_nvim && g:vimade_features.has_gui_version,
\   'enablefocusfading': 0,
\   'normalid': '',
\   'normalncid': '',
\   'lazy': 0,
\   " python-only options below
\   'basegroups': ['Folded', 'Search', 'SignColumn', 'CursorLine', 'CursorLineNr', 'DiffAdd', 'DiffChange', 'DiffDelete', 'DiffText', 'FoldColumn', 'Whitespace', 'NonText', 'SpecialKey', 'Conceal', 'EndOfBuffer', 'WinSeparator', 'LineNr', 'LineNrAbove', 'LineNrBelow'],
\   'enablebasegroups': 1,
\   'enablesigns': 1,
\   'signsid': 13100,
\   'signsretentionperiod': 4000,
\   'signspriority': 31,
\   'fademinimap': 1,
\   'matchpriority': 10,
\   'disablebatch': 0,
\   " lua only options below
\   'nohlcheck': 1,
\ }
```
</details>

<details>
<summary><a><ins>Lua defaults</ins></a></summary>

<sub>::lua::</sub>
```lua
vimade.setup{
  -- Recipe can be any of 'default', 'minimalist', 'duo', and 'ripple'
  -- Set animate = true to enable animations on any recipe.
  -- See the docs for other config options.
  recipe = {'default', {animate=false}},
  ncmode = 'buffers', -- use 'windows' to fade inactive windows
  fadelevel = 0.4, -- any value between 0 and 1. 0 is hidden and 1 is opaque.
  tint = {
    -- bg = {rgb={0,0,0}, intensity=0.3}, -- adds 30% black to background
    -- fg = {rgb={0,0,255}, intensity=0.3}, -- adds 30% blue to foreground
    -- fg = {rgb={120,120,120}, intensity=1}, -- all text will be gray
    -- sp = {rgb={255,0,0}, intensity=0.5}, -- adds 50% red to special characters
    -- you can also use functions for tint or any value part in the tint object
    -- to create window-specific configurations
    -- see the `Tinting` section of the README for more details.
  },

  -- Changes the real or theoretical background color. basebg can be used to give
  -- transparent terminals accurating dimming.  See the 'Preparing a transparent terminal'
  -- section in the README.md for more info.
  -- basebg = [23,23,23],
  basebg = '',
  -- prevent a window or buffer from being styled. You 
  blocklist = {
    default = {
      highlights = {
        laststatus_3 = function(win, active)
          -- Global statusline, laststatus=3, is currently disabled as multiple windows take ownership
          -- of the StatusLine highlight (see #85).
          if vim.go.laststatus == 3 then
              -- you can also return tables (e.g. {'StatusLine', 'StatusLineNC'})
              return 'StatusLine'
          end
        end,
        -- Prevent ActiveTabs from highlighting.
        'TabLineSel',
        -- Exact highlight names are supported:
        -- 'WinSeparator',
        -- Lua patterns are supported, just put the text between / symbols:
        -- '/^StatusLine.*/' -- will match any highlight starting with "StatusLine"
      },
      buf_opts = { buftype = {'prompt'} },
      -- buf_name = {'name1','name2', name3'},
      -- buf_vars = { variable = {'match1', 'match2'} },
      -- win_opts = { option = {'match1', 'match2' } },
      -- win_vars = { variable = {'match1', 'match2'} },
      -- win_type = {'name1','name2', name3'},
      -- win_config = { variable = {'match1', 'match2'} },
    },
    default_block_floats = function (win, active)
      return win.win_config.relative ~= '' and
        (win ~= active or win.buf_opts.buftype =='terminal') and true or false
    end,
    -- any_rule_name1 = {
    --   buf_opts = {}
    -- },
    -- only_behind_float_windows = {
    --   buf_opts = function(win, current)
    --     if (win.win_config.relative == '')
    --       and (current and current.win_config.relative ~= '') then
    --         return false
    --     end
    --     return true
    --   end
    -- },
  },
  -- Link connects windows so that they style or unstyle together.
  -- Properties are matched against the active window. Same format as blocklist above
  link = {},
  groupdiff = true, -- links diffs so that they style together
  groupscrollbind = false, -- link scrollbound windows so that they style together.
  -- enable to bind to FocusGained and FocusLost events. This allows fading inactive
  -- tmux panes.
  enablefocusfading = false,
  -- Time in milliseconds before re-checking windows. This is only used when usecursorhold
  -- is set to false.
  checkinterval = 1000,
  -- enables cursorhold event instead of using an async timer.  This may make Vimade
  -- feel more performant in some scenarios. See h:updatetime.
  usecursorhold = false,
  -- when nohlcheck is disabled the highlight tree will always be recomputed. You may
  -- want to disable this if you have a plugin that creates dynamic highlights in
  -- inactive windows. 99% of the time you shouldn't need to change this value.
  nohlcheck = true,
}
```

</details>

<details>
<summary><a><ins>Python defaults</ins></a></summary>

<sub>::python::</sub>
```python
from vimade import vimade
from vimade.recipe.default import Default
vimade.setup(
  # Recipe can be any of 'default', 'minimalist', 'duo', and 'ripple'
  # Set animate = true to enable animations on any recipe.
  # See the docs for other config options.
  recipe = ['default', {'animate': False}],
  ncmode = 'buffers', # use 'windows' to fade inactive windows
  fadelevel = 0.4, # any value between 0 and 1. 0 is hidden and 1 is opaque.
  tint = {
    # 'bg': {'rgb':[0,0,0], 'intensity':0.3}, # adds 30% black to background
    # 'fg': {'rgb':[0,0,255], 'intensity':0.3}, # adds 30% blue to foreground
    # 'fg': {'rgb':[120,120,120], 'intensity':1}, # all text will be gray
    # 'sp': {'rgb':[255,0,0], 'intensity':0.5}, # adds 50% red to special characters
  },
  # changes the real or theoretical background color. basebg can be used to give
  # transparent terminals accurating dimming.  See the 'Preparing a transparent terminal'
  # section in the README.md for more info
  basebg = '',
  blocklist = {
    'default': {
      'buf_opts': { 'buftype': ['popup', 'prompt'] },
      'win_config': { 'relative': True },
      # buf_name = ['name1','name2', name3'],
      # buf_vars = { 'variable': ['match1', 'match2'] },
      # win_opts = { 'option': ['match1', 'match2' ] },
      # win_vars = { 'variable': ['match1', 'match2'] },
    },
    # 'any_rule_name1': {
    #   'buf_opts': {}
    # },
  },
  # Link connects windows so that they style or unstyle together.
  # Properties are matched against the active window. Same format as blocklist above
  link = {},
  groupdiff = True, # links diffs so that they style together
  groupscrollbind = False, # link scrollbound windows so that they style together.
  # enable to bind to FocusGained and FocusLost events. This allows fading inactive
  # tmux panes.
  enablefocusfading = False,
  # Time in milliseconds before re-checking windows. This is only used when usecursorhold
  # is set to false.
  checkinterval = 1000,
  # enables cursorhold event instead of using an async timer.  This may make Vimade
  # feel more performant in some scenarios. See h:updatetime.
  usecursorhold = false,
  # Basegroups are extra highlights that are faded using winhl (neovim only)
  basegroups = ['Folded', 'Search', 'SignColumn', 'CursorLine', 'CursorLineNr', 'DiffAdd', 'DiffChange', 'DiffDelete', 'DiffText', 'FoldColumn', 'Whitespace', 'NonText', 'SpecialKey', 'Conceal', 'EndOfBuffer', 'WinSeparator', 'LineNr', 'LineNrAbove', 'LineNrBelow'],
  enablebasegroups = True,
  # Enable sign highlighting
  enablesigns = True,
  # Create signs starting at the following id.
  signsid = 13100,
  # How long in ms to check for sign updates after the buffer is faded.
  signsretentionperiod = 4000,
  # Priority that will be used for faded signs
  signspriority = 31,
  # Special handling for `severin-lemaignan/vim-minimap`
  fademinimap = True,
  # Priority to be used for matchaddpos highlights. Set to 0 to show search in inactive windows. 
  matchpriority = 10,
  # Set to True to disable IPC batch for debugging purposes. Enabling this will negatively
  # impact performance.
  disablebatch = False,
)
```

</details>

<details>
<summary>
<a><ins>Option docs & descriptions</ins></a>
 
</summary>
<br>

**Options for Lua, Python, and Vimscript**


| option | values/type | default | description |
| -      | -           | -       | -           |
| `renderer` | `'auto'` `'python'` `'lua'` <br> | `'auto'` | `auto` automatically assigns **vim** users to **python** and detects if **neovim**  users have the requires features for **lua**.  For **neovim** users on **lua** mode, the **python** logic is never run. **Neovim** users with missing features will be set to **python** and need **pynvim** installed.
| `ncmode` | `'windows'` `'buffers'` | `'buffers'` | highlight or unhighlight `buffers` or `windows` together
| `fadelevel` | `float [0-1]` `function(style,state)=>float` | `0.4` | The amount of fade opacity that should be applied to fg-text (`0` is invisible and `1` is no fading)
| `tint` | <sub>When set via **lua** or **python**, each object or number can also be a function that returns the corresponding value component</sub><br><br><sub>`{'fg':{'rgb':[255,255,255], 'intensity':1, 'bg':{'rgb':[0,0,0], 'intensity':1}, 'sp':{'fg':[0,0,255], 'intensity':0.5}}}`</sub> | `nil` | The amount of tint that can be applied against each highlight component (fg, bg, sp). Intensity is a float value [0-1], where 1 is the most intense and 0 is not tinted.  See the tinting tutorial for more details.
| `basebg` | <sub> `'#FFFFFF'` `[255,255,255]` `0xFFFFFF` </sub> | `nil` | This value manipulates the target background color. This is most useful for transparent windows, where the *Normal* bg is *NONE*.  Set this value to a good target value to improve fading accuracy.
| `blocklist` | <sub>When set via **lua** or **python**, the top level named object can be a `function(win)=>bool`. Each nested object or value can also be a `function(relative_config)=>bool`.  `True` indicates blocked, `False` not linked, `nil` indeterminate.</sub><br><br><sub>`{[key:string]: {'buf_opts': {[key]:string: value}, 'buf_vars': {...}, 'win_opts': {...}, 'win_vars': 'win_config': {...}}}`</sub> | <sub> ```{'default':{'buf_opts': {'buftype':['prompt']}, 'win_config': {'relative': 1}}}```</sub> | If the window is determined to be blocked, **Vimade** highlights will be removed and it will skip the styling process. See the block and linking section for more details.
| `link` | <sub>When set via **lua** or **python**, the top level named object can be a `function(win, active_win)=>bool`. Each nested object or value can also be a `function(relative_win_obj,active_win_obj)=>bool`.  `True` indicates linked, `False` not linked, `nil` indeterminate.</sub><br><br> | `nil` | Determines whether the current window should be linked and unhighlighted with the active window.  `groupdiff` and `groupscrollbind` tie into the default behavior of this object behind the scenes to unlink diffs.  See the block and linking section for more details.
| `groupdiff` | `0` `1` `bool` | `1` | highlights and unhighlights diff windows together.
| `groupscrollbind` | `0` `1` `bool` | `0` | highlights and unhighlights scrolllbound windows together.
| `checkinterval` | `int` | `1000` | Time in milliseconds before re-checking windows.
| `usecursorhold` | `0` `1` `bool` | `0` | Whether to use cursorhold events instead of async timer. Setting this option **disables the timer**. This option defaults to `0` for most editor versions.  **gvim** defaults to `1` due to async timers breaking visual selections.  If you use this value, remember to set `:set updatetime` appropriately.
| `enablefocusfading` | `0` `1` `bool` | `0` | Highlight the active window on application focus and blur events.  This can be desirable when switching applications, but requires additional setup for terminal and tmux.  See enablefocusfading section for more details (TODO link)
| `normalid` | `int` | nil | The id of the Normal highlight.  **Vimade** will automatically set this, so you don't need to worry about it. You can override it though if you just want to play around.
| `normalncid` | `int` | nil | The id of the NormalNC highlight.  **Vimade** will automatically set this, so you don't need to worry about it. You can override it though if you just want to play around.
| `lazy` | `1` `0` | nil | When set to `1` **Vimade** is disabled at startup. You will need to manually call `vimade#Load()`.  See lazy loading section for more details.


**Options only for Lua**

| option      | values/type | default | description                                                                                                                                                                                                                                                                                                                                         |
| -           | -           | -       | -                                                                                                                                                                                                                                                                                                                                                   |
| `recipe` | `arraylike[name, recipe_options]` <sub><br>Example:<br> `{'Minimalist',{'animate':true}}`</sub> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | '`{'Default'}`' | Recipe and recipe-specific options that will be imported and used. Any other configuration will overlay the recipe config.
| `nohlcheck` | `bool`      | `true`  | When set to `false`, **Vimade** will recompute namespaces each frame.  This is useful if you have a plugin that dynamically changes highlights periodically.  When to `true` **Vimade** only recomputes namespaces when you switch between buffers/windows.  Performance isn't an issue either way as the recomputation process is sub-millisecond. |


**Options only for python**
 

| option        | values/type    | default | description                                                                                                                                                                                                                                                                                                                                         |
| -             | -              | -       | -                                                                                                                                                                                                                                                                                                                                                   |
| `recipe` | `arraylike[name, recipe_options]` <sub><br>Example:<br> `['Minimalist',{'animate':True}]`</sub> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | '`['Default']`' | Recipe and recipe-specific options that will be imported and used. Any other configuration will overlay the recipe config.
| `enablesigns`   | `0` `1` `bool`       | `True`    | Whether or not to fade signs.  For **python** this has to be performed per-buffer.  If you want per-window signs, you will need to link your sign highlights to **Normal**.
| `signsid`       | `int`            | `13100`   | The id that should be used to generate sign.  This is required to avoid collisions with other plugins.
| `signsretentionperiod` | `int`     | `4000`    | The amount of time after a window becomes inactive to check for sign updates.  Many plugins asynchronously update the buffer after switching windows, this helps ensure signs stay faded.
| `fademinimap`   | `0` `1` `bool`       | `1`       | Enables a special fade effect for `severin-lemaignan/vim-minimap`.  Setting vimade.fademinimap to 0 disables the special fade.
| `matchpriority` | `int`            | `10`      | Controls the highlighting priority.  You may want to tweak this value to make Vimade play nicely with other highlighting plugins and behaviors.  For example, if you want hlsearch to show results on all buffers, you may want to lower this value to 0.
| `linkwincolor`  | `string[]`       | `[]`      | **Vim only** option when **wincolor** is supported. List of highlights that will be linked to `Normal`. `Normal` is highlighted using `setlocal wincolor`, which gives **Vim** some flexibility to target highlight groups (see minimalist recipe).
| `disablebatch`  | `0` `1` `bool`       | `0`       | Disables IPC batching. Enabling this will greatly reduce performance, but allow you debug issues.
| `enablebasegroups` | `0` `1` `bool`    | `true`    | Only old **Neovim**. Allows winlocal winhl for the basegroups listed below.
| `basegroups`    | `string[]`       | <sub>**every built-in highlight**</sub>  | Only old **Neovim**. Fades the listed highlights in addition to the buffer text.
| `enabletreesitter` | `0` `1` `bool`    | `0`       | Only old **Neovim**. Uses treesitter to directly query highlight groups instead of relying on `synID`.

</details>
  

<details>

<summary>
<a><ins>Preparing a transparent terminal</ins></a>

</summary>

<br>

When using a transparent terminal, your *Normal* highlight is set to `NONE`.  Plugins like **Vimade** don't know the real
color. **Vimade** will assume that your background is either `black` or `white` depending on the value of `echo &background`.
For better color accuracy:

1. Prepare a pure `white` background (it must be exactly `#FFFFFF`).
2. Place your terminal over the background
3. Use a color picker tool to obtain the exact color value.  This value is typically a good starting point.
4. Set `basebg` to whatever the color value is in your **Vimade** config. For example:
 
    <sub>::vimscript::</sub>
    ```vim
    let g:vimade.basebg=[11,11,11]
    ```
    <sub>::lua::</sub>
    ```vim
    require('vimade').setup{basebg={11,11,11}}
    ```
    <sub>::python::</sub>
    ```vim
    from vimade import vimade
    vimade.setup(basebg=[11,11,11])
    ```
5. Repeat step 4, but darken `basebg` until you find a value that suits your preferences.

6. Once you have a good result it should look like this.  The example below uses the **Minimalist** recipe, which completely fades out
   *EndOfBuffer* and *LineNr* highlights, notice how they aren't visible!

    ![transparent_with_hlchunks](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/transparent_with_hlchunks.png)

<br>

---

</details>


<details>
<summary>
<a><ins>Buffers or windows</ins></a>
 
</summary>
<br>

The primary and legacy behavior of **Vimade** is to fade and tint inactive buffers.  You can also enable window fading if you prefer!


*<sub>::vimscript::</sub>*
  ```vim
  let g:vimade.ncmode = 'buffers'
  ```

  ```vim
  let g:vimade.ncmode = 'windows'
  ```


Most users should try each option to see what they like best. For most, there are inherit benefits to fading based on buffers
as its easier to see which windows are impacted by your edits or which windows you can cleanup.


---
</details>

<details>
<summary>
<a><ins>Tinting</ins></a>
 
</summary>
<br>

Tinting influences the color of `fg`, `bg`, and `sp` for every highlight group. Every option allows you specify `intensity`,
which determines how much color to add.

Changing the `fg` alters the text color. Let's give our inactive windows some yoda spunk:

*<sub>::vimscript::</sub>*
```vim
let g:vimade.tint = {'fg':{'rgb':[0,255,0], 'intensity': 0.3}}
```

![tint_fg_green](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/tint_section_fg_green.png)

The more that you raise the intensity, the closer each highlight will be the specified `rgb` value.  So let's say you want to disable
`syntax` highlighting on inactive windows, all you need to do is set the `intensity` to the value `1`.


*<sub>::vimscript::</sub>*
```vim
let g:vimade.tint = {'fg':{'rgb':[200,200,200], 'intensity': 1}}
```

![tint_fg_full_intensity](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/tint_section_fg_full_intensity.png)


`bg` directly impacts the window background color. It also indirectly impacts the `fg` color if you have fading enabled because
fades are performed against the background color.

*<sub>::vimscript::</sub>*
```vim
let g:vimade.tint = {'bg':{'rgb':[0,0,0], 'intensity': 0.15}}
```

![tint_bg_black](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/tint_section_bg_black.png)

 `bg` and all `tint` attributes have different effects depending on the value of `vimade.ncmode`.  When using `let g:vimade.ncmode='buffers'`,
 tints only impact inactive *buffers*.  When using `let g:vimade.ncmode='windows'` they affect windows, see the screenshots below for a
 comparison that also combines our changes above.
 
<sub>::vimscript::</sub>
``` vimscript
let g:vimade.ncmode = 'buffers'
let g:vimade.tint = {
  \ 'fg': { 'rgb': [0,255,0], 'intensity': 0.3 },
  \ 'bg': { 'rgb': [0,0,0], 'intensity': 0.15 }}
```

![tint_buffer_mode](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/tint_section_combined_buffers.png)

<sub>::vimscript::</sub>
``` vimscript
let g:vimade.ncmode = 'windows'
let g:vimade.tint = {
  \ 'fg': {'rgb': [0,255,0], 'intensity': 0.3 },
  \ 'bg': {'rgb': [0,0,0], 'intensity': 0.15 }}
```

![tint_windows_mode](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/tint_section_combined_windows.png)


---
</details>

<details>
<summary>
<a><ins>Blocklists and linking</ins></a>
 
</summary>
<br>

*Blocklists* and *linking* are conceptually similar processes. Blocklists prevent a window from being **styled**.  Linking
on the other hand lets you bind other windows to the *active* window so that they **style** and **unstyle** together.

You can specific any property in the following objects, or use a function that returns **true** when a condition is met.

``` vim
let g:vimade.blocklist = {
 \ 'rule_name': {
 \   'buf_names': [], " list of strings and/or functions to evaluate string comparison
 \   'buf_opts': {}, " any buffer scoped option (e.g. buftype)
 \   'buf_vars': {}, " any buffer variable (i.e. `let b:...`)
 \   'win_opts': {}, " any window scoped option
 \   'win_vars': {}, " any window variable (i.e `let w:...`)
 \   'win_config': {}, " any window config item (see `help nvim_win_get_config`)
 \ }
}
let g:vimade.link = {
 \ 'rule_name': {
 \   'buf_names': [], " list of strings and/or functions to evaluate string comparison
 \   'buf_opts': {}, " any buffer scoped option (e.g. buftype)
 \   'buf_vars': {}, " any buffer variable (i.e. `let b:...`)
 \   'win_opts': {}, " any window scoped option
 \   'win_vars': {}, " any window variable (i.e `let w:...`)
 \   'win_config': {}, " any window config item (see `help nvim_win_get_config`)
 \ }
}
```

The `rule_name` in the config above is arbitrary, but don't use **`default`** unless you want to override **Vimade**'s
default settings.

For **lua** `defaults` are:
```lua
  blocklist = {
    default = {
      highlights = {
        laststatus_3 = function(win, active)
          if vim.go.laststatus == 3 then
              return 'StatusLine'
          end
        end,
        'TabLineSel',
      },
      buf_opts = {buftype = {'prompt'}},
    },
    default_block_floats = function (win, active)
      return win.win_config.relative ~= '' and
        (win ~= active or win.buf_opts.buftype =='terminal') and true or false
    end,
  },

```

and **python**:
```python
'blocklist': {
  'default': {
    'buf_opts': {
      'buftype': ['popup', 'prompt']
    },
    'win_config': {
      'relative': True #block all floating windows # TODO we can make this more customized soon
     },
  }
},
```

Each value for a property is a considered a value-matcher, you can use an *array-like* or exact value type.
*Array-like* indicates that any value in the array is a match. Using boolean (true) indicates that any *truthy*
value will match.

Let's put this to the test and block all window variables with `'cool'` equal to `1` or `2`

```vim
let w:cool = 2
let g:vimade.blocklist = {
\  'demo_tutorial': {
\    'win_vars': { 'cool': [1,2] },
\  }
\ }
```

Now when you navigate off the window, nothing happens.


Let's replace the previous rule with a function that blocks everything except when a floating window is open:

<sub>::lua::</sub>
```lua
require('vimade').setup({
  blocklist = {
    demo_tutorial = function (win, current)
      -- current can be nil
      if (win.win_config.relative == '') and (current and current.win_config.relative ~= '') then
        return false
      end
      return true
    end
  }
})
```

<sub>::python::</sub>
```python
def only_behind_float_windows (win, current):
  # current can be None
  if (win.win_config['relative'] == '') and (current and current.win_config['relative'] != ''):
    return False
  return True

vimade.setup(blocklist = {
    'demo_tutorial': only_behind_float_windows,
})
```

Now nothing is faded except when you open a floating window, voilà!

![block_unless_floating](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/only_when_floating.png)


For a final step let's apply the same concepts to linking

```vim
let w:linked_window = 1
let g:vimade.blocklist = {
\  'demo_tutorial': {
\    'win_vars': { 'linked_window': 1 },
\  }
\ }
```

Navigate to another window and also apply
```
let w:linked_window = 1
```

The windows are now bound together and will **style** and **unstyle** together. This is an extremely useful concept
and **Vimade** uses it behind the scenes to ensure that diffs are visible in unison.

---
</details>


<details>
<summary>
<a><ins>Style modifiers</ins></a>
</summary>

<br>

**Styles** are the core functions that drive **Vimade**.  Each **style** decides how to manipulate the highlights based on their own input.
**Styles** can be combined, nested, or transpose each other, the process itself is configurable and its up to you to decide how to use
them. This section is intended for advanced customizations or users who want to build their own recipes. You are also more than welcome to
build your own style and add it into **Vimade**.

  <details>
  <summary>
  <ins>Fade</ins>
  
  Fades each window based on the `value` (also referred to as `fadelevel`). Colors are modified against the
  background color.
  </summary>

  <sub>*::lua::*</sub>
  ```lua
  local Fade = require('vimade.style.fade').Fade
  vimade.setup{
    style = {
      Fade{value = 0.4}
    }
  }
  ```
  <sub>*::python::*</sub>
  ```python
  from vimade import vimade
  from vimade.style.fade import Fade
  vimade.setup(style = [
    Fade(value = 0.4)
  ])
  ```
  | option | values/type | default | description |
  | -      | -           | -       | -           |
  | `value` | `number` `function(style,state)=>number` | `nil` |  The target fadelevel. Value ranges from `0 to 1`, where `0` is completely faded and `1` is unfaded.
  | `tick` | `function()=>void` | `nil` |  A function that is run once per frame. Useful if you need to do expensive pre-computation that shouldn't occur once per-window.

  </details>

  <details>
  <summary>
  <ins>Tint</ins>
  
  Tints each window based on `fg`, `bg`, and `sp` inputs.
  </summary>

  <sub>*::lua::*</sub>
  ```lua
  local Tint = require('vimade.style.tint').Tint
  vimade.setup{
    style = {
      Tint{
        value = {
          fg = {rgb = {0,0,0}, intensity = 0.5},
          bg = {rgb = {0,0,0}, intensity = 0.5},
          sp = {rgb = {0,0,0}, intensity = 0.5},
        }
      }
    }
  }
  ```
  <sub>*::python::*</sub>
  ```python
  from vimade import vimade
  from vimade.style.tint import Tint
  vimade.setup(style = [
    Tint(value = {
      'fg': { 'rgb': [0,0,0], 'intensity': 0.5 },
      'bg': { 'rgb': [0,0,0], 'intensity': 0.5 },
      'sp': { 'rgb': [0,0,0], 'intensity': 0.5 },
    })
  ])
  ```
  
  | option | values/type | default | description |
  | -      | -           | -       | -           |
  | `value` | <pre><sub>`{fg:{rgb:[num,num,num],intensity:num},`<br>` bg:{rgb:[num,num,num],intensity:num},`</sub><br><sub>` sp:{rgb:[num,num,num],intensity:num}}`</sub></pre> <sub>`function(style,state)=any`<br>*functions can be used for any part of the tint config object*</sub> | `nil` |  The target tint colors. Intensity is the inverse of fadelevel. `1` is full intensity, while `0` is not applied.
  | `tick` | `function()=>void` | `nil` |  A function that is run once per frame. Useful if you need to do expensive pre-computation that shouldn't occur once per-window.

  </details>

  <details>
  <summary>
  <ins>Invert</ins>
  
  Invert the colors in each window by a percentage.
  </summary>

  <sub>*::lua::*</sub>
  ```lua
  local Tint = require('vimade.style.invert').Invert
  vimade.setup{
    style = {
      Invert{
        value = {
          fg = 0.5,
          bg = 0.5,
          sp = 0.5,
        }
        -- alternatively use
        -- value = 0.5 (applies 0.5 to fg, bg, and sp)
      }
    }
  }
  ```
  <sub>*::python::*</sub>
  ```python
  from vimade import vimade
  from vimade.style.invert import Invert
  vimade.setup(style = [
    Invert(value = {
      'fg': 0.5,
      'bg': 0.5,
      'sp': 0.5,
      # alternatively use
      # value = 0.5 (applies 0.5 to fg, bg, and sp)
    })
  ])
  ```
  
  | option | values/type | default | description |
  | -      | -           | -       | -           |
  | `value` | <pre><sub>`number\|{fg:number,bg:number,sp:number}`</sub></pre> <sub>`function(style,state)=any`<br>*functions can be used for any part of the invert config object*</sub> | `nil` |  The target inversion level. `1` is full inversion, while `0` is not applied.
  | `tick` | `function()=>void` | `nil` |  A function that is run once per frame. Useful if you need to do expensive pre-computation that shouldn't occur once per-window.

  </details>

  <details>
  <summary>
  <ins>Include</ins>
  
  Runs nested style modifiers when the highlight is included in the `value`.
  </summary>

  <sub>*::lua::*</sub>
  ```lua
  local Fade = require('vimade.style.fade').Fade
  local Include = require('vimade.style.include').Include
  vimade.setup{
    style = {
      Include{
        value = ['WinSeparator', 'VertSplit', 'LineNr', 'LineNrAbove', 'LineNrBelow'],
        style = {
          Fade { value = 0.4 }
        }
      }
    }
  }
  ```
  <sub>*::python::*</sub>
  ```python
  from vimade import vimade
  from vimade.style.fade import Fade
  from vimade.style.include import Include
  vimade.setup(style = [
    Include(
      value = ['Normal', 'Comment'],
      style = [
        Fade(value = 0.4)
      ]
    )
  ])
  ```
  
  | option | values/type | default | description |
  | -      | -           | -       | -           |
  | `value` | `string[]` | `nil` |  The list of highlight names that the nested styles will execute modifies on.
  | `style` | `Style[]` | `nil` |  The list of styles that are run when highlights are included.
  | `tick` | `function()=>void` | `nil` |  A function that is run once per frame. Useful if you need to do expensive pre-computation that shouldn't occur once per-window.

  </details>

  <details>
  <summary>
  <ins>Exclude</ins>
  
  Runs nested style modifiers when the highlight is **not** included in the `value`.
  </summary>

  <sub>*::lua::*</sub>
  ```lua
  local Fade = require('vimade.style.fade').Fade
  local Exclude = require('vimade.style.exclude').Exclude
  vimade.setup{
    style = {
      Exclude{
        value = ['WinSeparator', 'VertSplit', 'LineNr', 'LineNrAbove', 'LineNrBelow'],
        style = {
          Fade { value = 0.4 }
        }
      }
    }
  }
  ```
  <sub>*::python::*</sub>
  ```python
  from vimade import vimade
  from vimade.style.fade import Fade
  from vimade.style.exclude import Exclude
  vimade.setup(style = [
    Exclude(
      value = ['Normal', 'Comment'],
      style = [
        Fade(value = 0.4)
      ]
    )
  ])
  ```
  
  | option | values/type | default | description |
  | -      | -           | -       | -           |
  | `value` | `string[]` | `nil` |  The list of highlight names that the nested styles will execute modifies on.
  | `style` | `Style[]` | `nil` |  The list of styles that are run when highlights are included.
  | `tick` | `function()=>void` | `nil` |  A function that is run once per frame. Useful if you need to do expensive pre-computation that shouldn't occur once per-window.

  </details>
  
  <details open>
  <summary>
  <ins>Combining styles</ins>
  
  This section is not ready yet!
  </summary>
  </details>

---
</details>


<details>
<summary>
<a><ins>Animations</ins></a>
</summary>

<br>

The section below will look at using a custom animation value within a **style**, so please read the **style** section before proceeding!


Animations are functions that mutate values over time.  **Vimade** includes a number of helpers that alter the interpolation process. 

> [!NOTE]
> Animations can only be added using **lua** or **python**. 

 Let's look at an example:

<sub>::lua:: 
```lua
local Fade = require('vimade.style.fade').Fade
local animate = require('vimade.style.value.animate')
require('vimade').setup{style = {
  Fade {
    value = animate.Number {
      start = 1,
      to = 0.2
    }
  }
}}
```

<sub>::python::
```python
from vimade import vimade
from vimade.style import fade
from vimade.style.value import animate
vimade.setup(style = [
  Fade(value = animate.Number(
    start = 1,
    to = 0.2,
  )),
])
```

The example above uses `animate.Number` to fade inactive windows from no-fade `start = 1` to almost completely faded `to = 0.2`.

The animation can be further customized by overriding any of the default values:

<sub>::lua:: 
```lua
local Fade = require('vimade.style.fade').Fade
local direction = require('vimade.style.value.direction')
local ease = require('vimade.style.value.ease')
local animate = require('vimade.style.value.animate')
require('vimade').setup{style = {
  Fade {
    value = animate.Number {
      start = 1,
      to = 0.2,
      direction = direction.IN_OUT,
      ease = ease.OUT_BOUNCE,
      duration = 1000,
      delay = 100,
    }
  }
}}
```

<sub>::python::
```python
from vimade import vimade
from vimade.style import fade
from vimade.style.value import animate
from vimade style.value import direction
from vimade style.value import ease
vimade.setup(style = [
  Fade(value = animate.Number(
    start = 1,
    to = 0.2,
    direction = direction.IN_OUT,
    ease = ease.OUT_BOUNCE,
    duration = 1000,
    delay = 100,
  )),
])
```

Every value type can be animated included tints and nested values in complex objects.  See the recipe source for more examples.



| option | values/type | default | description |
| -      | -           | -       | -           |
| `start` | `any` `function(style,state)=>any` | `nil` |  The starting value that the animation begins at.  If `direction=IN_OUT`, then the starting value is only used one time when the value is uninitialized.
| `to` | `any` `function(style,state)=>any` | `nil` |  The ending value that the animation ends at. 
| `direction` | `IN` `OUT` `IN_OUT` | `OUT` |  These are specialized functions and **MUST** be used from the exported `vimade.style.value.direction` enum.  `OUT` is a outward animation, which should typically be associated with "leaving" something. `IN` is an inward animation that should be associated with "entering".  `IN_OUT` tracks the value and performs both `IN` and `OUT` behaviors.
| `ease` | `LINEAR` `OUT_QUART` `IN_QUART` `IN_OUT_QUART` `IN_CUBIC` `OUT_CUBIC` ... | `OUT_QUART` |  These are functions and **can** be used from `vimade.style.value.ease`.  You can also use your own custom `function(time)=>percent_time`.  Easing functions change the animation behavior by mutating `percent_time`.  See source for examples: [lua](https://github.com/TaDaa/vimade/blob/master/lua/vimade/style/value/ease.lua) \| [python](https://github.com/TaDaa/vimade/blob/master/lib/vimade/style/value/ease.py).
| `duration` | `number` `function(state,state)=>number`   | `300` |  The duration of the animation in milliseconds.
| `delay` | `number` `function(style,state)=>number` | `0` |  How long to wait before starting the animation.



---
</details>


<details open>
<summary>
<a><ins>Recipe: Default</ins></a>
</summary>

<br>

Enabled by default, but you can re-apply this recipe with additional customizations (e.g. animations).
You can only enable **recipes** through a configuration overlay (**no vimscript**).

*<sub>::lua:: [source](https://github.com/TaDaa/vimade/tree/master/lua/vimade/recipe/default.lua) (see here for additional params)</sub>*

```lua
require('vimade').setup({recipe = {'default', {animate = true}}})
```


*<sub>::python:: [source](https://github.com/TaDaa/vimade/tree/master/lua/vimade/recipe/default.lua) (see here for additional params)</sub>*
```python
from vimade import vimade
vimade.setup(recipe = ['default', {'animate': True}])
```

![default_recipe](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/default_recipe_animate.gif)
---
</details>

<details open>
<summary>
<a><ins>Recipe: Minimalist</ins></a>
</summary>

<br>

This recipe hides low value built-in highlights on inactive windows such as number column and end of buffer highlights.  Greatly reduces visibility of WinSeparator on inactive windows. 

*<sub>::lua:: [source](https://github.com/TaDaa/vimade/tree/master/lua/vimade/recipe/minimalist.lua) (see here for additional params)</sub>*

```lua
require('vimade').setup({recipe = {'minimalist', {animate = true}}})
```

*<sub>::python:: [source](https://github.com/TaDaa/vimade/tree/master/lib/vimade/recipe/minimalist.py) (see here for additional params)</sub>*

<sub>NOTE: For **vim** users with wincolor, minimalist will link the `no_visibility_highlights` to `Normal` so that they can completely fade-out per-window.<sub>
```python
from vimade import vimade
vimade.setup(recipe = ['minimalist', {'animate': True}])
```

![minimalist_recipe](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/minimalist_recipe_animate2.gif)
---
</details>

<details open>
<summary>
<a><ins>Recipe: Duo</ins></a>
</summary>

<br>

Looking for a balanced approach between *window* and *buffer* styles?  Duo applies full `fadelevel` and `tint` to inactive *buffers*
and a fraction of the values to same-split *buffers*.

*<sub>::lua:: [source](https://github.com/TaDaa/vimade/tree/master/lua/vimade/recipe/duo.lua) (see here for additional params)</sub>*

```lua
require('vimade').setup({recipe = {'duo', {animate = true}}})
```

*<sub>::python:: [source](https://github.com/TaDaa/vimade/tree/master/lib/vimade/recipe/duo.py) (see here for additional params)</sub>*

```python
from vimade import vimade
vimade.setup(recipe = ['duo', {'animate': True}])
```

![duo_recipe](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/duo-reduced.gif)

To make it look exactly like the screenshot above, you will want to combine the recipe with some background tint:

*<sub>::lua::</sub>*
```lua
require('vimade').setup({
  recipe = {'duo', {animate = true}},
  tint = {bg = {rgb={0,0,0}, intensity = 0.3}}
})
```

*<sub>::python::</sub>*

```python
from vimade import vimade
vimade.setup(
  recipe = ['duo', {'animate': True}],
  tint = {'bg': {'rgb':[0,0,0], 'intensity': 0.3}})
```

---
</details>

<details open>
<summary>
<a><ins>Recipe: Paradox</ins></a>
</summary>

<br>

Manipulate contrast to match your insanity. Paradox flips your colorscheme on its head and adds some inversion to the active window. This
recipe is mostly useful for improving contrast on some colorschemes.

*<sub>::lua:: [source](https://github.com/TaDaa/vimade/tree/master/lua/vimade/recipe/paradox.lua) (see here for additional params)</sub>*

```lua
require('vimade').setup({recipe = {'paradox', {animate = true}}})
```

![paradox_recipe](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/paradox.gif)

For the truly insane (full inversion):

*<sub>::lua::</sub>*
```lua
require('vimade').setup({
  recipe = {'paradox', {
      animate = true,
      invert = {
        start = 0,
        to = 1,
      }
  }},
})
```

** *Python support to follow*

---
</details>

<details>
<summary>
<a><ins>Recipe: Ripple</ins></a>
</summary>

<br>

Gradually increases the fade and tint level based on distance from the current window. The maximum target values are equal to your `fadelevel` and `tint` settings.

> [!NOTE]
> 
> This recipe requires and enables fading by windows (`ncmode='windows'`)


*<sub>::lua:: [source](https://github.com/TaDaa/vimade/tree/master/lua/vimade/recipe/ripple.lua) (see here for additional params)</sub>*

```lua
require('vimade').setup({recipe = {'ripple', {animate = true}}})
```

*<sub>::python:: [source](https://github.com/TaDaa/vimade/tree/master/lib/vimade/recipe/ripple.py) (see here for additional params)</sub>*

```python
from vimade import vimade
vimade.setup(recipe = ['ripple', {'animate': True}])
```

![ripple_recipe](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/ripple.gif)

---
</details>

<details>
<summary>
<a><ins>Commands</ins></a>
 
</summary>
<br>

| command |  description |
| -       |  -           |
| `VimadeEnable` |  Enables **Vimade**.  Not necessary to run unless you have explicitly disabled **Vimade**.
| `VimadeDisable` |  Disable and remove all **Vimade** highlights.
| `VimadeToggle` |  Toggle between enabled/disabled states.
| `VimadeRedraw` |  Force vimade to recalculate and redraw every highlight.
| `VimadeInfo` |  Provides debug information for Vimade.  Please include this info in bug reports.
| `VimadeWinDisable` | Disables fading for the current window.
| `VimadeWinEnable` | Enables fading for the current window.
| `VimadeBufDisable` | Disables fading for the current buffer.
| `VimadeBufEnable` | Enables fading for the current buffer.
| `VimadeFadeActive` | Fades the current active window.
| `VimadeUnfadeActive` | Unfades the current active window.
| `VimadeOverrideFolded` | Overrides the Folded highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include Folded highlights that are distracting in faded windows.
| `VimadeOverrideSignColumn` | Overrides the SignColumn highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include SignColumn highlights that are distracting in faded windows.
| `VimadeOverrideLineNr` | Overrides the LineNr highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include LineNr highlights that are distracting in faded windows.
| `VimadeOverrideSplits` | Overrides the VertSplit highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include VertSplit highlights that are distracting in faded windows.
| `VimadeOverrideNonText` | Overrides the NonText highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include NonText highlights that are distracting in faded windows.
| `VimadeOverrideEndOfBuffer` | Overrides the EndOfBuffer highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include EndOfBuffer highlights that are distracting in faded windows.
| `VimadeOverrideAll` | Combines all VimadeOverride commands.
| `VimadeFadeLevel [0.0-1.0]` |  Sets the FadeLevel config and forces an immediate redraw.
| `VimadeFadePriority [0+]` |  Sets the FadePriority config and forces an immediate redraw.

  
---
</details>


<details open>
<summary>
<a><ins>FAQ/Help</ins></a>

</summary>
<br>

Tmux is not working!
- *Vimade only works in a 256 or higher color mode and by default TMUX may set t_Co to 8.   it is recommended that you set `export TERM=xterm-256color` before starting vim.  You can also set `set termguicolors` inside vim if your term supports it for an even more accurate level of fading.*
- If you also want windows to fade when switching between tmux panes:
  1. Enable focusfading `let g:vimade.enablefocusfading = 1`
  2. Add `set -g focus-events on` to your tmux.conf
  3. (vim-only) On some environments, you still may need to install `tmux-plugins/vim-tmux-focus-events`.


---

</details>

<br>

## Comparison against other plugins
 
Many similar **Neovim** plugins have recently been created. 
I'm not aware of any feature that these plugins support that **Vimade** doesn't, so I'm going to keep this table limited to key differences.
If you find a feature gap, please file an issue or contribute!

| Feature                                       | Vimade | Shade | Tint         | Sunglasses |
| -                                             | -      | -     | -            | -          |
| Fade buffers                                  | Yes    |       |              |            |
| Fade windows                                  | Yes    | Yes   | Yes          | Yes        |
| Group diffs                                   | Yes    |       | via function |            |
| Links                                         | Yes    |       | via function |            |
| Blocklist                                     | Yes    |       | via function | Yes        |
| Animations                                    | Yes    |       |              |            |
| Recipes                                       | Yes    |       |              |            |
| 256 colors                                    | Yes    |       |              |            |
| Per-window config (e.g. fadelevel, tint, etc) | Yes    |       |              |            |
| Cleared highlights                            | Yes    | Yes   |              |            |
| Compatible with other namespaces              | Yes    | Yes   |              |            |
| Supports **Vim** + All versions of **Neovim** | Yes    |       |              |            |


## Contributing

Feel free to open a PR or file issues for bugs and feature requests. All contributions are valued even its just a question!
If you are looking for a place to share your own code and flavor in this plugin, **recipes** are a great starting place.

**Thanks for reading!**

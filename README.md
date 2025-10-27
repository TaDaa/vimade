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

**Vimade** helps you maintain focus on what matters. It dims, fades, and tints inactive windows and buffers. It can also provide "limelight" or "twilight" style highlighting around your cursor, but with a key difference: **Vimade preserves syntax highlighting**, allowing you to stay in context while focusing on the code that matters most.

Vimade offers a powerful and flexible way to customize your coding environment with:

*   🎨 **Pre-built Recipes:** Get started quickly with a variety of visual styles.
*   🔋 **Batteries Included:** Works out-of-the-box with no configuration necessary.
*   ✨ **Smooth Animations:** Enjoy a fluid and visually appealing experience.
*   🌈 **Extensive Customization:** Tailor every aspect of the fading and tinting to your liking.
*   🧩 **Unmatched Compatibility:** Compatible with all colorschemes and plugins.
*   ⏰ **Sub-millisecond Performance:** Keep your editor snappy and responsive.

Create a truly unique and focused coding environment with Vimade.

## 🚀 Getting Started

> [!IMPORTANT]
> Neovim 0.8+ uses a pure Lua implementation.  Some features, like focus mode, require Neovim 0.10+.
> For Vim and older versions of Neovim, Python is required.

<details open>
<summary><a><ins>lazy.nvim</ins></a></summary>
<br>

*<sub>::lua::lazy.nvim::</sub>*
```lua
{
  "tadaa/vimade",
  opts = {
    recipe = {"default", {animate = true}},
    fadelevel = 0.4,
  }
}
```

</details>

<details open>
<summary><a><ins>vim-plug</ins></a></summary>
<br>

*<sub>::vimscript::vim-plug::</sub>*
```vim
Plug 'TaDaa/vimade'
```

</details>

<details>
<summary><a><ins>Configure with lua (Neovim only)</ins></a></summary>

```
require('vimade').setup({
  recipe = {'default', {animate = true}},
  fadelevel = 0.4,
})
```

</details>

<details>
<summary><a><ins>Configure with vimscript</ins></a></summary>

> Recipes are not available via vimscript configuration (use either python or lua)

```
let g:vimade = {}
let g:vimade.fadelevel = 0.4
```

</details>

<details>
<summary><a><ins>Configure with python</ins></a></summary>
<br>

> For Vim & Neovim < 0.8



*<sub>::python::</sub>*
```vim
function! SetupMyVimadeConfig()
python << EOF
from vimade import vimade
vimade.setup(
  recipe = ['default', {'animate':True}],
  fadelevel = 0.4,
 )
EOF
endfunction
# SetupMyVimadeConfig will be called lazily after python becomes available.
# You can call vimade.setup(...) whenever you want.
au! User Vimade#PythonReady call SetupMyVimadeConfig()
```

</details>

## 📖 Guides

<details>
<summary><a><ins>Important note on configuration</ins></a></summary>
<br>

Vimade treats the `setup()` command as an overlay. Each time you call it, it will override any previous settings. Therefore, if you want to combine multiple settings, you must include them all in the same `setup()` call.  If you want to reset the overlay to defaults, just call `setup()` with no options.

**Correct:**
```lua
require('vimade').setup({
  recipe = {'minimalist', {animate = true}},
  fadelevel = 0.3,
})
```

**Incorrect:**
```lua
require('vimade').setup({recipe = {'minimalist', {animate = true}}})
require('vimade').setup({fadelevel = 0.3}) -- This will override the recipe setting!
```
</details>

<details>
<summary><a><ins>Choosing an ncmode</ins></a></summary>
<br>

Vimade can fade inactive windows in a few different ways. You can control this behavior with the `ncmode` option.

- **`'buffers'`**: (Default) Fades all windows that do not share the same buffer as the active window. This is useful if you have the same buffer open in multiple splits and you want them all to remain highlighted.
- **`'windows'`**: Fades all inactive windows. This is a good choice if you want a clear distinction between the window you are currently working in and all other windows.
- **`'focus'`**: (Neovim 0.10+) Only fades when the `:VimadeFocus` command is active. This is useful for on-demand highlighting.

Most users should try each option to see what they like best.

*<sub>::vimscript::</sub>*
```vim
let g:vimade.ncmode = 'buffers' " or 'windows' or 'focus'
```

*<sub>::lua::</sub>*
```lua
require('vimade').setup{ncmode = 'buffers'} -- or 'windows' or 'focus'
```

*<sub>::python::</sub>*
```python
from vimade import vimade
vimade.setup(ncmode='buffers') # or 'windows' or 'focus'
```

</details>

<details>
<summary><a><ins>Preparing a transparent terminal</ins></a></summary>
<br>

When using a transparent terminal, your `Normal` highlight group has a background of `NONE`. Vimade needs to know the actual background color to properly calculate faded colors. For the best results, you should set the `basebg` option.

1.  Place your transparent terminal over a pure white background (`#FFFFFF`).
2.  Use a color picker to determine the hex code of the background color of your terminal.
3.  Set `basebg` to this value in your configuration. You may need to darken it slightly to get the best results.


*<sub>::lua::</sub>*
```lua
require('vimade').setup{basebg = '#2d2d2d'} -- or {45, 45, 45}
```

*<sub>::vimscript::</sub>*
```vim
let g:vimade.basebg = '#2d2d2d' " or [45, 45, 45]
```

*<sub>::python::</sub>*
```python
from vimade import vimade
vimade.setup(basebg='#2d2d2d') # or [45, 45, 45]
```

</details>

<details>
<summary><a><ins>Fixing Issues with tmux</ins></a></summary>
<br>

If you are having issues with Vimade in tmux, here are a few things to try:

- **256 Colors:** Vimade requires a 256 color terminal. By default, tmux may set `t_Co` to 8. It is recommended that you set `export TERM=xterm-256color` before starting Vim. You can also set `set termguicolors` inside Vim if your terminal supports it for an even more accurate level of fading.
- **Focus Events:** If you want windows to fade when switching between tmux panes, you need to enable focus events.
  1.  Enable focus fading in Vimade: `let g:vimade.enablefocusfading = 1`
  2.  Add `set -g focus-events on` to your `tmux.conf`.
  3.  For Vim users, you may also need to install the `tmux-plugins/vim-tmux-focus-events` plugin.

</details>

<details>
<summary><a><ins>[Tutorial] Fading only behind floating windows</ins></a></summary>
<br>

You can configure Vimade to only fade windows when a floating window is open. This is useful if you only want to dim the background when you are focused on a floating window, like a popup or a dialog.

This can be achieved with a `blocklist` function that checks if the current window is a floating window.

<ins>Lua:</ins>
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

<ins>Python:</ins>

> Similar behaviors can be managed for python as well.  Vim doesn't support
> Focusable floating windows, so the logic required is a bit more complex, but still achievable

```python
from vimade import vimade
from vimade.state import globals
g_tick_id = -1
g_popup_visible = False
g_popup_winids = []
def refresh_popup_visible():
  global g_popup_visible
  global g_popup_winids
  g_popup_winids = vim.eval('popup_list()')
  any_visible = False
  for winid in g_popup_winids:
    if vim.eval(f'popup_getpos({winid})["visible"]') == '1':
      any_visible = True
      break
  if any_visible != g_popup_visible:
    g_popup_visible = any_visible
    if g_popup_visible:
      # A popup is visible, so fade the background including active win
      vim.command('VimadeFadeActive')
    else:
      # No popups are visible, so clear the fade including active win
      vim.command('VimadeUnfadeActive')
def only_behind_float_windows (win, current):
  global g_tick_id
  # This is a performance optimization. We only run the expensive
  # refresh_popup_state() function once per "tick" (screen refresh),
  # not for every single window being checked.
  if g_tick_id != globals.tick_id:
    g_tick_id = globals.tick_id
    refresh_popup_visible()
  return not g_popup_visible or win.winid in g_popup_winids

vimade.setup(blocklist = {
  'demo_tutorial': only_behind_float_windows,
})


```

Now, Vimade will only fade windows when a floating window is active.

![block_unless_floating](https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/only_when_floating.png)

</details>


## 🎨 Recipes

Vimade comes with several pre-built recipes to get you started. You can enable them with the `recipe` option.

<details>
<summary><a><ins>Default</ins></a></summary>
<br>

The standard Vimade experience.

<table>
<tbody>
<tr>
<td>
    <p align="center">
      <img height="236" src="https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/default_recipe_animate.gif" alt="Default Recipe">
    </p>
</td>
</tr>
<tr>
<td>

```lua
require("vimade").setup({recipe = {"default", {animate = true}}})
```

</td>
</tr>
</tbody>
</table>

</details>

<details open>
<summary><a><ins>Minimalist</ins></a></summary>
<br>

Hides low-value inactive highlights like line numbers and the end-of-buffer marker.

<table>
<tbody>
<tr>
<td>
  <p align="center">
    <img height="236" src="https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/minimalist_recipe_animate2.gif" alt="Minimalist Recipe">
  </p>
</td>
</tr>
<tr>
<td>

  ```lua
    require("vimade").setup({recipe = {"minimalist", {animate = true}}})
  ```

</td>
</tr>
</tbody>
</table>


</details>

<details open>
<summary><a><ins>Duo</ins></a></summary>
<br>

A balanced approach between window and buffer fading.

<table>
<tbody>
<tr>
<td>
  <p align="center">
    <img height="251" src="https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/duo-reduced.gif" alt="Duo Recipe">
  </p>
</td>
</tr>
<tr>
<td>

  ```lua
  require("vimade").setup({recipe = {"duo", {animate = true}}})
  ```

</td>
</tr>
</tbody>
</table>

</details>

<details open>
<summary><a><ins>Paradox</ins></a></summary>
<br>

Inverts the colors of the active window for a high-contrast look. (Neovim only)

<table>
<tbody>
<tr>
<td>
  <p align="center">
    <img height="220" src="https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/paradox.gif" alt="Paradox Recipe">
  </p>
</td>
</tr>
<tr>
<td>

  ```lua
  require("vimade").setup({recipe = {"paradox", {animate = true}}})
  ```

</td>
</tr>
</tbody>
</table>

</details>

<details>
<summary><a><ins>Ripple</ins></a></summary>
<br>

Gradually fades windows based on their distance from the active window.

<table>
<tbody>
<tr>
<td>
  <p align="center">
    <img height="201" src="https://raw.githubusercontent.com/TaDaa/tadaa.github.io/refs/heads/master/images/ripple.gif" alt="Ripple Recipe">
  </p>
</td>
</tr>
<tr>
<td>

  ```lua
  require("vimade").setup({recipe = {"ripple", {animate = true}}})
  ```

</td>
</tr>
</tbody>
</table>

</details>

## ⚙️ Configuration

<details>
<summary><a><ins>Option docs & descriptions</ins></a></summary>
<br>

| Option | Description |
|---|---|
| **`recipe`**<br><sub>`table`<br>_Default:_ `{'default', {}}`</sub> | Specifies a recipe to use for styling. A recipe is a pre-configured set of styles and options. Any other configuration will overlay the recipe config. See the [Recipes](#-recipes) section for available recipes.<br><br><ins>Example (lua):</ins></a><pre><code>require('vimade').setup({recipe = {'minimalist', {animate = true}}})</code></pre><br><ins>Example (python):</ins></a><pre><code>vimade.setup(recipe = ['minimalist', {'animate': True}])</code></pre> |
| **`ncmode`**<br><sub>`string`<br>_Default:_ `'buffers'`</sub> | - **`'buffers'`**: Fades all windows that do not share the same buffer as the active window. This is useful if you have the same buffer open in multiple splits and you want them all to remain highlighted.<br><br>- **`'windows'`**: Fades all inactive windows. This is a good choice if you want a clear distinction between the window you are currently working in and all other windows.<br><br>- **`'focus'`** (Neovim 0.10+): Only fades when the `:VimadeFocus` command is active. This is useful for on-demand highlighting.<br><br> |
| **`fadelevel`**<br><sub>`float` or `function`<br>_Default:_ `0.4`</sub> | The amount of fade to apply to inactive windows. A value between `0.0` (completely faded) and `1.0` (not faded at all). |
| **`tint`**<br><sub>`table` or `function`<br>_Default:_ `{}`</sub> | Apply a color tint to inactive windows. The `tint` option is a table that can contain `fg`, `bg`, and `sp` keys. Each of these keys is a table that can contain `rgb` and `intensity` keys. The `rgb` key is a table of 3 values (red, green, blue) from 0-255. The `intensity` is a value from 0.0-1.0 that determines how much of the color to apply.<br><br><ins>Example (lua):</ins></a><sub><pre><code>require('vimade').setup{ tint = { fg = { rgb = {255, 0, 0}, intensity = 0.5}, bg = { rgb = {0, 0, 0}, intensity = 0.2}}}</pre></code></sub><br><ins>Example (vimscript):</ins></a><sub><pre><code>let g:vimade.tint = { 'fg': {'rgb': [255, 0, 0], 'intensity': 0.5}, 'bg': {'rgb': [0, 0, 0], 'intensity': 0.2}}</code></pre></sub><br><ins>Example (python):</ins></a><sub><pre><code>vimade.setup(tint = { 'fg':{'rgb':[255,0,0], 'intensity':0.5}, 'bg':{'rgb':[0,0,0], 'intensity':0.2}})</pre></code></sub> |
| **`basebg`**<br><sub>`string` or `table` (list in python)<br>_Default:_ `nil`</sub> | The base background color for transparent terminals. When using a transparent terminal, your `Normal` highlight group has a background of `NONE`. Vimade needs to know the actual background color to properly calculate faded colors. You can provide a hex string (e.g., `'#2d2d2d'`) or a table/list of RGB values (e.g., `{20, 20, 20}`).<br><br><ins>For best results, follow these steps:</ins><br>1. Place your transparent terminal over a pure white background.<br>2. Take a screenshot of your terminal.<br>3. Use a color picker to get the hex code of the background color.<br>4. Set `basebg` to that value.<br>5. Darken `basebg` until you find the highlights acceptable. |
| **`blocklist`**<br><sub>`table` or `function`<br>_Default:_ `See below`</sub> | A list of windows or buffers to exclude from fading. This can be a table of rules or a function that returns `true` to block a window. Each rule is a table of conditions that must be met for the window to be blocked. The available conditions are:<br>- `buf_name`: Matches against the buffer name.<br>- `win_type`: Matches against the window type.<br>- `buf_opts`: Matches against the buffer options.<br>- `buf_vars`: Matches against the buffer variables.<br>- `win_opts`: Matches against the window options.<br>- `win_vars`: Matches against the window variables.<br>- `win_config`: Matches against the window configuration.<br>- `highlights`: (Neovim only) A list of highlight groups to exclude from fading. This can be a list of strings or a function that returns a list of strings. You can also use a pattern by surrounding the string with `/`.<br><br><ins>Default (lua):</ins></a><sub><pre><code>blocklist = {</code><br><code>    default = {</code><br><code>      highlights = {</code><br><code>        laststatus_3 = function(win, active)</code><br><code>          if vim.go.laststatus == 3 then</code><br><code>              return 'StatusLine'</code><br><code>          end</code><br><code>        end,</code><br><code>        'TabLineSel',</code><br><code>        'Pmenu',</code><br><code>        'PmenuSel',</code><br><code>        'PmenuKind',</code><br><code>        'PmenuKindSel',</code><br><code>        'PmenuExtra',</code><br><code>        'PmenuExtraSel',</code><br><code>        'PmenuSbar',</code><br><code>        'PmenuThumb',</code><br><code>      },</code><br><code>      buf_opts = {buftype = {'prompt'}},</code><br><code>    },</code><br><code>    default_block_floats = function (win, active)</code><br><code>      return win.win_config.relative ~= '' and</code><br><code>        (win ~= active or win.buf_opts.buftype =='terminal') and true or false</code><br><code>    end,</code><br><code>  }</code></pre></sub><br><ins>Default (python):</ins></a><sub><pre><code>'blocklist': {</code><br><code>  'default': {</code><br><code>    'buf_opts': {</code><br><code>      'buftype': ['popup', 'prompt']</code><br><code>    },</code><br><code>    'win_config': {</code><br><code>      'relative': True #block all floating windows</code><br><code>     },</code><br><code>  }</code><br><code>},</code></pre></sub><br><ins>Example (lua):</ins></a><sub><pre><code>require('vimade').setup({ blocklist = { my_rule = { buf_opts = { ft = 'oil' } } } })</code></pre></sub><br><ins>Example (vimscript):</ins></a><sub><pre><code>let g:vimade.blocklist = { 'my_rule': { 'buf_opts': { 'ft' : 'nerdtree'} } }</code></pre></sub><br><ins>Example (python):</ins></a><sub><pre><code>vimade.setup(blocklist={'my_rule': {'buf_opts': {'ft': 'nerdtree'}}})</code></pre></sub> |
| **`link`**<br><sub>`table` or `function`<br>_Default:_ `{}`</sub> | A list of windows to style together. When windows are linked, they are styled together, meaning they will both be considered "active" or "inactive" based on the rules. This can be a table of rules or a function that returns `true` to link a window. Each rule is a table of conditions that must be met for the window to be linked. The available conditions are:<br>- `buf_name`: Matches against the buffer name.<br>- `win_type`: Matches against the window type.<br>- `buf_opts`: Matches against the buffer options.<br>- `buf_vars`: Matches against the buffer variables.<br>- `win_opts`: Matches against the window options.<br>- `win_vars`: Matches against the window variables.<br>- `win_config`: Matches against the window configuration.<br><br>By default, Vimade links diff windows (if `groupdiff` is `true`) and scroll-bound windows (if `groupscrollbind` is `true`).<br><br><ins>Tutorial Example: Linking Windows with `linked_window`</ins><br>Let's say you want to link two windows so they always have the same fade state. You can achieve this by setting a window-local variable, for example, `linked_window`, to `1` in both windows. Then, configure Vimade's `link` option to recognize this variable.<br><br><ins>Step 1: Set a window-local variable in both windows</ins></a><sub><pre><code>:let w:linked_window = 1</code></pre></sub><br><br><ins>Step 2: Configure Vimade to link windows based on this variable</ins></a><br><br><sub><ins>Example (lua):</ins></a><sub><pre><code>require('vimade').setup({</code><br><code>  link = {</code><br><code>    my_linked_windows = function(win, active)</code><br><code>      return win.win_vars.linked_window == 1 and active.win_vars.linked_window == 1</code><br><code>    end,</code><br><code>  },</code><br><code>})</code></pre></sub><br><ins>Example (vimscript):</ins></a><sub><pre><code>let g:vimade.link = {</code><br><code>  \ 'my_linked_windows': {</code><br><code>  \   'win_vars': {'linked_window': 1},</code><br><code>  \ },</code><br><code>  \ }</code></pre></sub><br><ins>Example (python):</ins></a><sub><pre><code>from vimade import vimade</code><br><code>vimade.setup(link={</code><br><code>    'my_linked_windows': {</code><br><code>        'win_vars': {'linked_window': 1}</code><br><code>    }</code><br><code>})</code></pre></sub><br><br>Now, when you navigate between these two windows, they will be styled together. This is an extremely useful concept, and Vimade uses it behind the scenes to ensure that diffs are visible in unison. |
| **`groupdiff`**<br><sub>`boolean`<br>_Default:_ `true`</sub> | When `true`, all windows in diff mode are treated as a single entity. This means they will all be styled together, remaining active or inactive in unison. This is particularly useful for keeping visual consistency when reviewing changes across multiple diff splits. |
| **`groupscrollbind`**<br><sub>`boolean`<br>_Default:_ `false`</sub> | When `true`, all windows with the `'scrollbind'` option enabled are treated as a single entity. This ensures that they are styled in unison, maintaining a consistent appearance as you scroll through them together. |
| **`enablefocusfading`**<br><sub>`boolean`<br>_Default:_ `false`</sub> | When `true`, Vimade will fade the entire editor when it loses focus and unfade it upon gaining focus. This is useful for visually distinguishing between active and inactive editor instances when switching between different applications. Note that this feature may require additional configuration for some terminal multiplexers like tmux.<br><br><ins>Tmux Configuration:</ins><br>To get focus events working in tmux, you need to do the following:<br>1. Add `set -g focus-events on` to your `tmux.conf` file.<br>2. For Vim users, you may also need to install the `tmux-plugins/vim-tmux-focus-events` plugin. |
| **`checkinterval`**<br><sub>`integer`<br>_Default:_ `1000`</sub> | The interval in milliseconds for checking window states. This option is ignored if `usecursorhold` is enabled. |
| **`usecursorhold`**<br><sub>`boolean`<br>_Default:_ `false`*</sub> | When `true`, Vimade will use the `CursorHold` event to trigger updates instead of a timer. This disables the `checkinterval` option and can provide a more responsive feel in some scenarios. See `:help updatetime` for more information on configuring the `CursorHold` event. |
| **`lazy`**<br><sub>`boolean`<br>_Default:_ `false`</sub> | When set to `true`, Vimade is disabled at startup. You will need to manually call `:VimadeEnable` or `vimade#Load()` to enable it.<br><br><ins>Neovim (lazy.nvim):</ins><br>For lazy loading with `lazy.nvim`, you can use the `event` key to specify when to load the plugin. For example, to load Vimade on the `VeryLazy` event:<sub><pre><code>require('lazy').setup({spec = {{'tadaa/vimade', event = 'VeryLazy'}}})</code></pre></sub><br><ins>Vimscript/Python:</ins><br>To lazy load with vimscript, you can set `g:vimade.lazy` to 1 and then call `vimade#Load()` on an autocommand:<sub><pre><code>let g:vimade = {}</code><br><code>let g:vimade.lazy = 1</code><br><code>au WinEnter * ++once call vimade#Load()</code></pre></sub> |
| **`renderer`**<br><sub>`string`<br>_Default:_ `'auto'`</sub> | Specifies the rendering engine for Vimade. In most cases, you should not need to change this setting, as Vimade will automatically select the best available renderer for your environment.<br><br>- **`'auto'`**: (Default) Automatically selects the best available renderer. It will prioritize the Lua renderer on Neovim 0.8+ and fall back to the Python renderer on older Neovim versions and Vim.<br><br>- **`'lua'`**: Forces the use of the Lua renderer. This is only available on Neovim 0.8+.<br><br>- **`'python'`**: Forces the use of the Python renderer. This is required for Vim and older versions of Neovim. |
| **`nohlcheck`**<br><sub>`boolean`<br>_Default:_ `true`</sub> | (Lua only) This option controls how often Vimade checks for updates to highlight namespaces. By default, this is `true`, which means that Vimade will only recompute namespaces when you switch windows or buffers. While this is efficient, some plugins that dynamically change highlight groups may not be reflected immediately. <br><br>In general, you should not need to change this setting. However, if you are experiencing issues with highlights not updating correctly, you can set this to `false` for debugging purposes. When set to `false`, Vimade will recompute highlight namespaces on every frame, which may have a minor performance impact. |
| **`enablesigns`**<br><sub>`boolean`<br>_Default:_ `True`</sub> | (Python only) Whether or not to fade signs. |
| **`signsid`**<br><sub>`integer`<br>_Default:_ `13100`</sub> | (Python only) The starting ID for placing Vimade signs. If you use other plugins that place signs, you may need to change this value to avoid conflicts. |
| **`signsretentionperiod`**<br><sub>`integer`<br>_Default:_ `4000`</sub> | (Python only) The amount of time after a window becomes inactive to check for sign updates. Many plugins update signs asynchronously, so having a long enough retention period helps ensure that newly added signs are faded. |
| **`fademinimap`**<br><sub>`boolean`<br>_Default:_ `true`</sub> | (Python only) Enables a special fade effect for `severin-lemaignan/vim-minimap`. |
| **`matchpriority`**<br><sub>`integer`<br>_Default:_ `10`</sub> | (Python only) Controls the highlighting priority. You may want to tweak this value to make Vimade play nicely with other highlighting plugins and behaviors. For example, if you want hlsearch to show results on all buffers, you may want to lower this value to 0. |
| **`linkwincolor`**<br><sub>`table`<br>_Default:_ `{}`</sub> | (Python only) **Vim only** option when **wincolor** is supported. List of highlights that will be linked to `Normal`. |
| **`disablebatch`**<br><sub>`boolean`<br>_Default:_ `false`</sub> | (Python only) Disables IPC batching. Users should not need to toggle this feature unless they are debugging issues with Vimade, as it will greatly reduce performance. |
| **`enablebasegroups`**<br><sub>`boolean`<br>_Default:_ `true`</sub> | (Python only) Only old **Neovim**. Allows winlocal winhl for the basegroups listed below. |
| **`basegroups`**<br><sub>`table`<br>_Default:_ <sub>**every built-in highlight**</sub></sub> | (Python only) Only old **Neovim**. Fades the listed highlights in addition to the buffer text. |
| **`enabletreesitter`**<br><sub>`boolean`<br>_Default:_ `false`</sub> | (Python only) Only old **Neovim**. Uses treesitter to directly query highlight groups instead of relying on `synID`. |

</details>

## 📚 Commands

<details>
<summary><a><ins>Command List</ins></a></summary>
<br>

| command |  description |
| -       |  -           |
| `VimadeEnable` |  Enables **Vimade**.  Not necessary to run unless you have explicitly disabled **Vimade**.
| `VimadeDisable` |  Disable and remove all **Vimade** highlights.
| `VimadeToggle` |  Toggle between enabled/disabled states.
| `VimadeRedraw` |  Force vimade to recalculate and redraw every highlight.
| `VimadeInfo` |  Provides debug information for Vimade.  Please include this info in bug reports.
| `VimadeFocus` |  Neovim-only. Highlights around the cursor using your configured providers. When used with no subcommand, it toggles the focus highlight. This command has the following subcommands:<br>- `toggle`: Toggles the focus highlight. (Default)<br>- `toggle-on`: Enables the focus highlight.<br>- `toggle-off`: Disables the focus highlight. |
| `VimadeMark` |  Neovim-only. Mark an area that should not be highlighted in inactive windows. When used with no subcommand, it toggles the mark for the current selection. This command has the following subcommands:<br>- `set`: Marks the current selection.<br>- `remove`: Removes marks within the current selection.<br>- `remove-win`: Removes all marks in the current window.<br>- `remove-buf`: Removes all marks in the current buffer.<br>- `remove-tab`: Removes all marks in the current tab.<br>- `remove-all`: Removes all marks. |
| `VimadeWinDisable` | Disables fading for the current window.
| `VimadeWinEnable` | Enables fading for the current window.
| `VimadeBufDisable` | Disables fading for the current buffer.
| `VimadeBufEnable` | Enables fading for the current buffer.
| `VimadeFadeActive` | Fades the current active window.
| `VimadeUnfadeActive` | Unfades the current active window.
| `VimadeFadeLevel [0.0-1.0]` |  Sets the FadeLevel config and forces an immediate redraw.
| `VimadeFadePriority [0+]` |  Sets the FadePriority config and forces an immediate redraw.
| `VimadeOverrideFolded` | (Recommended for Vim users) Overrides the Folded highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include Folded highlights that are distracting in faded windows.  |
| `VimadeOverrideSignColumn` | (Recommended for Vim users) Overrides the SignColumn highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include SignColumn highlights that are distracting in faded windows.
| `VimadeOverrideLineNr` | (Recommended for Vim users) Overrides the LineNr highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include LineNr highlights that are distracting in faded windows.  |
| `VimadeOverrideSplits` | (Recommended for Vim users) Overrides the VertSplit highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include VertSplit highlights that are distracting in faded windows.
| `VimadeOverrideNonText` | (Recommended for Vim users) Overrides the NonText highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include NonText highlights that are distracting in faded windows.
| `VimadeOverrideEndOfBuffer` | (Recommended for Vim users) Overrides the EndOfBuffer highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include EndOfBuffer highlights that are distracting in faded windows.
| `VimadeOverrideAll` | (Recommended for Vim users) Combines all VimadeOverride commands. |

</details>

## 🛠️ Creating Recipes

<details>
<summary><a><ins>Crafting Your Own Vimade Experience</ins></a></summary>
<br>

Recipes are the heart of Vimade's customization. A recipe is simply a collection of styles that are applied to inactive windows. You can mix and match styles to create your own unique look and feel. All of Vimade's built-in recipes are just a collection of the styles listed below, with varying degrees of complexity.

To create a recipe, you define a list of styles in your configuration. Each style is a Lua table with a specific set of options.

Here is an example of a simple recipe:

<ins>Lua:</ins>
```lua
require('vimade').setup({
  style = {
    -- Fade inactive windows by 60%
    require('vimade.style.fade').Fade({value = 0.4}),
    -- Tint the foreground of inactive windows with a blue color
    require('vimade.style.tint').Tint({
      value = {
        fg = {rgb = {100, 100, 255}, intensity = 0.2},
      }
    }),
  }
})
```

<ins>Python:</ins>
```python
from vimade import vimade
from vimade.style.fade import Fade
from vimade.style.tint import Tint

vimade.setup(
  style = [
    # Fade inactive windows by 60%
    Fade(value = 0.4),
    # Tint the foreground of inactive windows with a blue color
    Tint(
      value = {
        'fg': {'rgb': [100, 100, 255], 'intensity': 0.2},
      }
    ),
  ]
)
```

If you create a style combination that you find particularly useful, you can abstract it into your own recipe. Recipes are located in the [`lua/vimade/recipe/`](https://github.com/TaDaa/vimade/tree/master/lua/vimade/recipe) directory. If you believe your recipe would be beneficial to other users, please feel free to open a pull request to add it to Vimade!

### Available Styles

Here is a list of the available styles and their options:

<details>
<summary>Fade</summary>
<br>

Fades the highlights of inactive windows.

| Option | Description |
|---|---|
| **`value`**<br><sub>`number` or `function`<br>_Default:_ `nil`</sub> | The target fade level. A value between `0.0` (completely faded) and `1.0` (not faded). |
| **`condition`**<br><sub>`function`<br>_Default:_ `CONDITION.INACTIVE`</sub> | A function that determines if the style should be applied. |

</details>

<details>
<summary>Tint</summary>
<br>

Tints the highlights of inactive windows.

| Option | Description |
|---|---|
| **`value`**<br><sub>`table` or `function`<br>_Default:_ `nil`</sub> | A table with `fg`, `bg`, and `sp` keys, each with `rgb` and `intensity` values. |
| **`condition`**<br><sub>`function`<br>_Default:_ `CONDITION.INACTIVE`</sub> | A function that determines if the style should be applied. |

</details>

<details>
<summary>Invert</summary>
<br>

Inverts the colors of inactive windows.

| Option | Description |
|---|---|
| **`value`**<br><sub>`number` or `table` or `function`<br>_Default:_ `nil`</sub> | The inversion level from `0.0` to `1.0`. Can be a single number or a table with `fg`, `bg`, and `sp` keys. |
| **`condition`**<br><sub>`function`<br>_Default:_ `CONDITION.INACTIVE`</sub> | A function that determines if the style should be applied. |

</details>

<details>
<summary>Include</summary>
<br>

Applies nested styles to a specific list of highlight groups.

| Option | Description |
|---|---|
| **`value`**<br><sub>`table`<br>_Default:_ `nil`</sub> | A list of highlight group names. |
| **`style`**<br><sub>`table`<br>_Default:_ `nil`</sub> | A list of styles to apply to the included highlight groups. |
| **`condition`**<br><sub>`function`<br>_Default:_ `CONDITION.INACTIVE`</sub> | A function that determines if the style should be applied. |

</details>

<details>
<summary>Exclude</summary>
<br>

Applies nested styles to all highlight groups except for a specific list.

| Option | Description |
|---|---|
| **`value`**<br><sub>`table`<br>_Default:_ `nil`</sub> | A list of highlight group names to exclude. |
| **`style`**<br><sub>`table`<br>_Default:_ `nil`</sub> | A list of styles to apply to the not-excluded highlight groups. |
| **`condition`**<br><sub>`function`<br>_Default:_ `CONDITION.INACTIVE`</sub> | A function that determines if the style should be applied. |

</details>

<details>
<summary>Component</summary>
<br>

A container style that groups other styles under a name and a condition. This is useful for creating logical groups of styles that can be enabled or disabled together.

| Option | Description |
|---|---|
| **`name`**<br><sub>`string`<br>_Default:_ `nil`</sub> | The name of the component. |
| **`style`**<br><sub>`table`<br>_Default:_ `nil`</sub> | A list of styles to be included in the component. |
| **`condition`**<br><sub>`function`<br>_Default:_ `CONDITION.INACTIVE`</sub> | A function that determines if the component's styles should be applied. |

</details>

<details>
<summary>Link</summary>
<br>

Links one highlight group to another.

| Option | Description |
|---|---|
| **`value`**<br><sub>`table`<br>_Default:_ `nil`</sub> | A list of tables, each with a `from` and `to` key specifying the highlight group to link from and to. |
| **`condition`**<br><sub>`function`<br>_Default:_ `CONDITION.INACTIVE`</sub> | A function that determines if the linking should be applied. |

</details>

</details>

## 🆚 Similar Plugins

Vimade is the original syntax-aware dimming and fading plugin for Vim and
Neovim. While other window fading plugins have emerged, Vimade
is a powerful and flexible option with a rich feature set and the only option that correctly
handles plugin namespaces.

This table highlights some of the features that make only Vimade stand out:
| Feature | Vimade |
|---|---|
| Fade buffers and windows | Yes |
| Dim around cursor (Neovim) | Yes |
| Mark areas to stay visible (Neovim)| Yes |
| Group diffs and scroll-bound windows | Yes |
| Advanced block-listing and linking | Yes |
| Smooth animations | Yes |
| High performance | Lua: **~0.5ms-1.4ms per frame** <br> Python: varies, but expect **~0.5-6ms per frame** |
| Composable recipes | Yes |
| Support for 256 colors and `termguicolors` | Yes |
| Per-window configuration | Yes |
| Cleared highlights | Yes |
| Compatibility with other namespaces | Yes |
| Support for **Vim** + All versions of **Neovim** | Yes |
                                                                             
If you are looking for a mature, feature-rich, and highly customizable
plugin, Vimade is the right choice for you.

### Related plugins to `:VimadeFocus` and `:VimadeMark`
                                                                              
- [limelight](https://github.com/junegunn/limelight.vim)
- [snacks.nvim](https://github.com/folke/snacks.nvim/blob/main/docs/dim.md)
- [twilight.nvim](https://github.com/folke/twilight.nvim)
- [focushere.nvim](https://github.com/kelvinauta/focushere.nvim)

## 🙌 Contributing

Contributions are always welcome! Whether you have a feature request, a bug report, or a question, please feel free to open an issue or a pull request.

### Recipes

If you've created a recipe that you think others would enjoy, please consider sharing it! Recipes are a great way to contribute to the Vimade community. You can find the existing recipes in the [`lua/vimade/recipe/`](https://github.com/TaDaa/vimade/tree/master/lua/vimade/recipe) directory.

### Bug Reports and Feature Requests

If you encounter a bug or have an idea for a new feature, please open an issue on the GitHub repository. When opening an issue, please provide as much detail as possible, including:

*   Your Vim/Neovim version
*   The output of `:VimadeInfo`
*   Steps to reproduce the issue

**Thanks for your interest in contributing to Vimade!**

# vimade (vim+fade)
> Fade, highlight, and customize your windows + buffers

## What is this?
This plugin was created to help keep your attention focused on the active buffer especially in scenarios where you might have many windows open at the same time.  

Previously Vimade accomplished this by fading just the inactive buffers.  Vimade has now transitioned into a plugin that is fully customizable and you can highlight any window/buffer however you see fit.  The old "just fade/dim" functionality is a small subset of the new features!


##### Screenshots

**Fade inactive windows**

![](http://tadaa.github.io/images/vimade_fadek.gif)

**Fade using custom tints**

![](http://tadaa.github.io/images/vimade_tintk.gif)

**Change the fadelevel**

![](http://tadaa.github.io/images/vimade_fadelevelk.gif)

**Fade signs (example below does 4000 signs)**

![](http://tadaa.github.io/images/vimade_signsk.gif)

**Fade/Unfade diffs together**

![](http://tadaa.github.io/images/vimade_diffk.gif)

**Fade/Unfade using word wrap**

![](http://tadaa.github.io/images/vimade_wrapk.gif)

**Fade using NormalNC (NVIM only)**

![](http://tadaa.github.io/images/vimade_normalnck.gif)

## Features
- [X] Fade & highlight buffers and windows
- [X] Switch between Window and Buffer highlighting
- [X] Link windows so that change together (e.g. diffs!)
- [X] Blocklist 
- [X] Custom tints
- [X] Prebuilt recipes
- [X] Fully customizable (see styles and recipes for examples of what you can do)
- [X] Animations (in, out, all directions, and extensive easing options)
- [X] Auto adjust to state and configuration changes
- [X] Automatically adjust to fadelevel changes
- [X] 256color and termguicolor support!
- [X] Performance.  Lua-mode is sub-millisecond per frame. Updated python logic is 2-10x faster than the previous iteration.
- [X] Many commands (VimEnable, VimDisable, VimToggle)
- [X] Supports Lua-only for Neovim 0.8.0+
- [X] Supports Vim8+, Neovim 0+???? (requires python2.7 or newer)
- [X] (Vim+Older Neovim) Tons of logic to support wrapped text, folded text, ownsyntax, signs, etc.  
- [X] `VimadeOverrideAll` and other override commands to help make built-in highlights look better while Vimade is enabled.
- [X] Vim Documentation/Help

#### Whats coming?
- [ ] Some good stuff
- [ ] Code cleanup
- [ ] Tests

## Install
*Add `TaDaa/vimade` to your vimrc -- you can use any plugin manager e.g:*

```
Plug 'TaDaa/vimade'
```

## Getting started / Recipes:

- [Fade buffers](#fade-buffers)
- [Fade windows](#fade-windows)
- [Default recipe](#default-recipe)
- [Minimalist recipe](#minimalist-recipe)

<details>

<summary>

### Fade buffers

Just adding **Vimade** to your vimrc is enough as this is the default behavior. But you may want to play around the config options and other recipes!
</summary>


<blockquote>

###### vimscript

```vimscript
let g:vimade = {}
let g:vimade.fadelevel = 0.4
```



###### lua

```lua
require('vimade').setup{fadelevel = 0.4}
```


###### python

```python
vimade.setup(fadelevel = 0.4)
```
  
</blockquote>

</details>

<details>

<summary>

### Fade windows

Fade inactive windows instead of buffers!

</summary>

<blockquote>

```vimscript
let g:vimade = {}
let g:vimade.fadelevel = 0.4
let g:vimade.ncmode = 'windows'
```

###### lua

```lua
require('vimade').setup{fadelevel = 0.4, ncmode = 'windows'}
```

###### python

```python
vimade.setup(fadelevel = 0.4, ncmode = 'windows')
```

</blockquote>

</details>

<details open>

<summary>

### Default recipe

This recipe is enabled by default, but you can re-apply it with additional customizations (e.g. animations)

</summary>

<blockquote>


###### lua | [source](https://github.com/TaDaa/vimade/tree/master/lua/vimade/recipe/default.lua)

```lua
local Default = require('vimade.recipe.default').Default
require('vimade').setup(Default(animate=true))
```

###### python | [source](https://github.com/TaDaa/vimade/tree/master/lib/vimade/recipe/default.py)

```python
from vimade import vimade
from vimade.recipe.default import Default
vimade.setup(Default(animate=True))
```

![](https://github.com/TaDaa/tadaa.github.io/blob/master/images/default_recipe_animate.gif)

</blockquote>

</details>



<details open>

<summary>

### Minimalist recipe

Hide low value built-in highlights on inactive windows such as number column and end of buffer highlights.  Additionally greatly reduces visibility of WinSeparator on inactive windows. 

</summary>

###### lua | [source](https://github.com/TaDaa/vimade/lua/tree/master/vimade/recipe/minimalist.lua)

<blockquote>

```lua 
local Minimalist = require('vimade.recipe.minimalist').Minimalist
require('vimade').setup(Minimalist{animate = true})
```

![](https://github.com/TaDaa/tadaa.github.io/blob/master/images/minimalist_recipe_animate2.gif)

</details>

</blockquote>


##### General Config
Vimade is initialized with the following and will react to configuration changes on the fly.  Some of these options don't matter if you are using the lua renderer, but you can set them anyways just in case you ever need to use Vim as well. 
```
let g:vimade = {
  \ 'renderer': 'auto',
  \ 'ncmode': 'buffers',
  \ 'normalid": '',
  \ 'normalncid': '',
  \ 'basebg': '',
  \ 'fadelevel': 0.4,
  \ 'groupdiff': 1,
  \ 'groupscrollbind': 0,
  \ 'checkinterval': 100, "100 is the default for gui vim, 500 is the default for terminals and neovim
  \ 'usecursorhold': 0, "0 is default, but will automatically set to 1 for Windows GVIM
  \ 'blocklist': {'default': {'buf_opts': {'buftype': ['prompt', 'terminal', 'popup']}, 'win_config': {'relative': 1}}}, " blocks floatings windows and prompts.  Terminal is blocked on Neovim but may be added later.  See below for how to use blocklist
  \ 'enablesigns': g:vimade_features.has_signs_priority, "enabled for vim/nvim versions that support sign priority.  Older vim/nvim versions may suffer performance issues
  \ 'signsid': 13100,
  \ 'signsretentionperiod': 4000,
  \ 'fademinimap': 1,
  \ 'matchpriority': 10,
  \ 'enablefocusfading': 0,
  \ 'enablebasegroups': 1,
  \ 'enabletreesitter' : 0, "EXPERIMENTAL FEATURE - 0 is the default, enables support for treesitter highlights"
  \ 'basegroups': ['Folded', 'Search', 'SignColumn', 'LineNr', 'CursorLine', 'CursorLineNr', 'DiffAdd', 'DiffChange', 'DiffDelete', 'DiffText', 'FoldColumn', 'Whitespace']
}
```


###### Common functionality between Lua and Python renderers

- **vimade.renderer** - Set to **auto** by default. The **auto** renderer prioritizes **lua** for Neovim users that have the required features and **python** for everyone else. **python-legacy** is the previous version of the **python** renderer, but should not be used as the newer versions are much higher performing!  

| Renderer | Neovim version | Vim version | Performance per frame |
| -------- | ------ | ------- | ----------|
| let g:vimade.renderer='auto' | All | 0.7.4+ | See below |
| let g:vimade.renderer='lua'  | 0.8.0+ | N/A | < 1ms | 
| let g:vimade.renderer='python' | All | 0.7.4+ | variable based on many factors |

- **vimade.ncmode** - either `'windows'` or `'buffers'`.  Determines whether windows or buffers are highlighted and unhighlighted together.  By default Vimade uses `'buffers'`.
- **vimade.fadelevel** - amount of fading applied between text and basebg.  0 will make the text the same color as the background and 1 applies no fading.  The default value is 0.4.  If you are using terminal, you may need to tweak this value to get better results.
- **vimade.groupdiff** - highlights and unhighlights diff windows together (otherwise you wouldn't be able to see the diff!).  Enable by default
- **vimade.groupscrollbind** - Same as **vimade.groupdiff** but for windows with scrollbind. Disabled by default. 
- **vimade.checkinterval** - the amount of time in milliseconds that vimade should check the screen for changes.  This config is mainly used to detect resize and scroll changes that occur on inactive windows. Checkinterval does nothing on gvim, if you want to control the refresh time, see 'h updatetime'. Default is 100.  
- **vimade.usecursorhold** -  disables the timer running in the background and instead relies `OnCursorHold` and `updatetime` (see h:updatetime).  The default value is `0` except on Windows GVIM, which defaults to `1` due to the timer breaking movements.  If you find that the timer is causing performance problems or other issues you can disable it by setting this option to `1`. 
- **vimade.basebg** - basebg can be either be six digit hexidecimal color, rgb array [0-255,0-255,0-255], or cterm code (in terminal).  basebg is used as a tint applied to fg text.  This option exists mainly as a legacy option (hence the strange naming!).  See the tint option below for a more
customizable way to modify your configuration. 
- **vimade.tint** - Allows full configuration over the colors applied to **fg**, **bg**, and **sp** highlights.  This is further customaizable via the **Lua** and **Python** logic.  
Vimscript:
```
let g:vimade.tint = {
\   'fg': {
\     'rgb': [255,0,0], " Any rgb value is valid. If you are in 256 color mode, the value will automatically be converted for you
\     'intensity': 1 " [0-1] are valid values. 0 is no tint applied and 1 is maximum
\   },
\   'bg': {
\     'rgb': [0,0,0], " Neovim will modify the full background color with this setting allowing you to fully customize the window appearance!
\     'intensity': 0.5
\   },
\   'sp': {
\     'rgb': [0,0,255], " Modifies special highlights
\     'intensity': 0.5
\   }
\ }
```
- **vimade.blocklist** - Configurable via vimscript, but more customizable via **Lua** and **Python** specific logic.  This allows you block windows that match against parts of the window matcher object.  Window matchers include `buf_name`, `buf_opts`, `buf_vars`, `win_opts`, `win_vars`, `win_type`, and `win_config`.  For example:
```
let g:vimade.blocklist = {
\ 'some_blocklist_name': {
\   'buf_name': ['buffer_name.py'],
\   'buf_opts': {
\     'buftype': ['terminal'],
\   },
\   'buf_vars': {
\     'some_buf_var': 123
\   },
\   'win_opts': {},
\   'win_vars': {},
\   'win_config': {}
\  }
\ }
```
**vimade.link** - Configurable via vimscript, but more customizable via **Lua** and **Python** specific logic below. This allows you to use a window matcher object to highlight and unhlighlight windows together.  Windows are matched for linked status against the active window.
```
let g:vimade.link = { \
'some_link_name': { \
\   'buf_name': [],
\   'buf_opts': {},
\   'buf_vars': {},
\   'win_opts': {
\     'diff': 1
\   },
\   'win_vars': {},
\   'win_config': {}
\  }
\ }
```
- **vimade.enablefocusfading** - Fades the current active window on focus blur and unfades when focus gained.  This can be desirable when switching applications or TMUX splits.  Default value is 0.   
  *Requires additional setup for terminal and tmux:*

    1. Install `tmux-plugins/vim-tmux-focus-events`
    2. Add `set -g focus-events on` to your tmux.conf
    3. Neovim should just work at this point.  If you are using Vim, you may need to add the following snippet to the very end of your vimrc.
          ```
          if has('gui_running') == 0 && has('nvim') == 0
             call feedkeys(":silent execute '!' | redraw!\<CR>")
          endif
          ```
- **vimade.normalid** - if not specified, the normalid is determined when vimade is first loaded.  normalid provides the id of the "Normal" highlight which is used to calculate fading.  You can override this config with another highlight group.
- **vimade.normalncid** - if not specified, the normalncid is determined when vimade is first loaded.  normalncid provides the id of the "NormalNC" highlight which is used to calculate fading for inactive buffers in NVIM.  You can override this config with another highlight group.


###### Lua-specific options

** Ensure you are on **Neovim 0.8.0** or later.



###### Python-specific options

- **vimade.enablesigns** - Enabled by default for vim/nvim versions that support sign priority and causes signs to be faded when switching buffers.  Only visible signs are faded.  This feature can cause performance issues on older vim/nvim versions that don't support sign priority.  Use signsretentionperiod to control the duration that vimade checks for sign updates after switching buffers.
- **vimade.enablescroll** - Enables fading while scrolling inactive windows.  This is only useful in gui vim and does have a performance cost.  By default this setting is enabled in gui vim and disabled for terminals.
- **vimade.signsid** - The starting id that Vimade should use when creating new signs. By default Vim requires numeric values to create signs and its possible that collisions may occur between plugins.  If you need to override this value for compatibility, please open an issue as well.  Default is 13100.
- **vimade.signspriority** - Controls the signs fade priority. You may need to change this value if you find that not all signs are fading properly.  Please also open a defect if you need to tweak this value as Vimade strives to minimize manual configuration where possible.  Default is 31.
- **vimade.signsretentionperiod** - The amount of time in milliseconds that faded buffers should be tracked for sign changes.  Default value is 4000.
- **vimade.fademinimap** - Enables a special fade effect for `severin-lemaignan/vim-minimap`.  Setting vimade.fademinimap to 0 disables the special fade.  Default is 1.
- **vimade.fadepriority** - Controls the highlighting priority.  You may want to tweak this value to make Vimade play nicely with other highlighting plugins and behaviors.  For example, if you want hlsearch to show results on all buffers, you may want to lower this value to 0.  Default is 10.
- **vimade.groupdiff** - Controls whether or not diffs will fade/unfade together.  If you want diffs to be treated separately, set this value to 0. Default is 1.
- **vimade.groupscrollbind** - Controls whether or not scrollbound windows will fade/unfade together.  If you want scrollbound windows to unfade together, set this to 1.  Default is 0.
- **vimade.enablebasegroups** - Neovim only setting.  Enabled by default and allows basegroups/built-in highlight fading using winhl.  This allows fading of built-in highlights such as Folded, Search, etc.
- **vimade.basegroups** - Neovim only setting that specifies the basegroups/built-in highlight groups that will be faded using winhl when switching windows
- **vimade.enabletreesitter** - This is an EXPERIMENTAL feature.  Combines treesitter with syntax highlights if needed to fade buffer.  Default value is 0.
- **viamde.disablebatch** - Disables high-performance batch mode. Set this feature to 1 if you need to debug something not working.  
 

##### Config Example(s)
*Always remember to first set the global vimade object (`let g:vimade={}`)
*this example reduces the amount of fading applied to text*
```
let g:vimade = {}
let g:vimade.fadelevel = 0.7
let g:vimade.enablesigns = 1
```
##### Commands
- **VimadeEnable** - Turns vimade on (Vimade is on by default)
- **VimadeDisable** - Turns vimade off and unfades all buffers
- **VimadeToggle** - Toggles between on/off states
- **VimadeRedraw** - Forces vimade to redraw fading for every window.
- **VimadeFadeLevel [0.0-1.0]** - Sets the FadeLevel config and forces an immediate redraw.
- **VimadeFadePriority [0+]** - Sets the FadePriority config and forces an immediate redraw.
- **VimadeInfo** - Provides debug information for Vimade.  Please include this info in bug reports
- **VimadeWinDisable** - Disables fading for the current window
- **VimadeWinEnable** - Enables fading for the current window
- **VimadeBufDisable** - Disables fading for the current buffer
- **VimadeBufEnable** - Enables fading for the current buffer
- **VimadeFadeActive** - Fades the current active window
- **VimadeUnfadeActive** - Unfades the current active window
- **VimadeOverrideFolded** - Overrides the Folded highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include Folded highlights that are distracting in faded windows.
- **VimadeOverrideSignColumn** - Overrides the SignColumn highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include SignColumn highlights that are distracting in faded windows.
- **VimadeOverrideLineNr** - Overrides the LineNr highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include LineNr highlights that are distracting in faded windows.
- **VimadeOverrideSplits** - Overrides the VertSplit highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include VertSplit highlights that are distracting in faded windows.
- **VimadeOverrideNonText** - Overrides the NonText highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include NonText highlights that are distracting in faded windows.
- **VimadeOverrideEndOfBuffer** - Overrides the EndOfBuffer highlight by creating a link to the Vimade base fade.  This should produce acceptable results for colorschemes that include EndOfBuffer highlights that are distracting in faded windows.
- **VimadeOverrideAll** - Combines all VimadeOverride commands.

##### FAQ/Help
I am using GVIM and my mappings are not working
- *Add `let g:vimade.usecursorhold=1` to your vimrc*

What about Vim < 8?
- *Vim 7.4 is currently untested/experimental, but should work if you add `let g:vimade.usecursorhold=1` to your vimrc*

My colors look off in terminal mode!
- *Make sure that you either use a supported terminal or colorscheme or manually define the fg and bg for 'Normal'.  You can also manually define the tint in your vimade config (g:vimade.basebg and g:vimade.basefg)*

Tmux is not working!
- *Vimade only works in a 256 or higher color mode and by default TMUX may set t_Co to 8.   it is recommended that you set `export TERM=xterm-256color` before starting vim.  You can also set `set termguicolors` inside vim if your term supports it for an even more accurate level of fading.*

Vim becomes slow when completions ar visible/changing (typically noticeable when a large number of buffers are open and autocomplete is running).  Neovim does not seem to suffer from the same performance degradation.
- *This issue seems to be due to redraws that occur as the pum content changes.  The best way to lessen the effect is to add `au! CompleteChanged * redraw` to your vimrc.  The user redraw can force Vim to be more responsive in this scenario*

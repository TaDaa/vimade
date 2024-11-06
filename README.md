# vimade
([n]vim[f]ade)

### Fade, highlight, and customize your windows + buffers

![](http://tadaa.github.io/images/minimalist_full.gif)

## What is this?
This plugin was created to help keep your attention focused on the active buffer especially in scenarios where you might have many windows open at the same time.  

Previously **Vimade** faded just the inactive buffers.  Vimade has now transitioned into a plugin that is fully customizable and you can highlight any window/buffer however you see fit.  The old "just fade/dim" functionality is a small subset of the new features!


## What is required?

For Neovim 0.8.0+ nothing. This plugin supports a lua-only code path, you are all set!

Vim7.4+ and Neovim < 0.8.0 require Python or Python3 support. For older versions of Neovim, you will need to install `pynvim`.

## Features
- [X] Fade or highlight windows or buffers.
- [X] Link windows so that change together (e.g. diffsplit)
- [X] Blocklist
- [X] Custom tints
- [X] Prebuilt recipes
- [X] Fully customizable (see styles and recipes for some of the possibilities)
- [X] Animated transitions.
- [X] Automatically adjusts to configuration changes.
- [X] Helpers to make inactive built-ins look better
- [X] Supports 256 color terminals and termguicolors.
- [X] Sub milliscond Lua performance and highly optimized Python logic for Vim.
- [X] Preconfigured commands such as (VimadeEnable, VimadeDisable, VimadeRedraw, etc)
- [X] Supports all versions of Neovim and Vim 7.4+
- [X] Vim Documentation/Help

#### Whats coming?
- [ ] Some good stuff
- [ ] Code cleanup
- [ ] Tests




## Getting started:

<details open>
<summary>
<a><ins>Installation</ins></a> - 
Any plugin manager will work.
<br>
</summary>

*<sub>::vimscript::plug::</sub>*
  ```vimscript
  Plug 'TaDaa/vimade'
  ```
  
---

</details>

<details>
<summary>
<a><ins>Basic tutorial</ins></a>
 
</summary>
<br>

There are a number of ways to specify the configuration for **Vimade** . Most users will be interested in manipulating the fadelevel and/or tint.
**Vimade** can be configured via vimscript if you prefer a general config that is compatibile with both Neovim and Vim.
It can also be configured with Lua and Python if you prefer a specific config or want an advanced configuration that includes animations, recipes, or conditional functions.

If you are configuring **Vimade** directly in your vimrc, add the following at the start:

*<sub>::vimscript::</sub>*
```vimscript
let g:vimade = {}
```

The initialization above will ensure that you have a vimade object initialized regardless of where you need it.  **Vimade** will initialize its own if it doesn't find one.  This object is automatically extended with
the default values, so don't worry about adding every option.

Now you can start customizing vimade:

*<sub>::vimscript::</sub>*
```vimscript
let g:vimade.fadelevel = 0.5
```

Simple right? the above code changes the opacity.  You can choose any value between **0 and 1**.  You can change any option at any time and **Vimade** will automatically react to those changes.

Let's add a blue tint:


*<sub>::vimscript::</sub>*
```vimscript
let g:vimade.tint = {'fg':{'rgb':[0,0,255], 'intensity': 0.5}}
```


You should notice that your text color has changed.  By default **tint** is applied before **fade**, but don't worry you can change that but that's going to be in a later section (**styles not documented yet**).

Let's make the above example a bit more complicated, suppose we have a filetree that we don't want to dim as extremely as our other windows.
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

Both languages use the same syntax and logic for configuration.


> [!Note]
> Advanced configurations in **python** and **lua** are treated as overlays, whatever you pass through the **setup** functions will overlay
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

<details>
<summary>
<a><ins>Highlight by active buffers or windows</ins></a>
 
</summary>
<br>
<b>Vimade</b> fades buffers by default. This is the primary and legacy behavior of this plugin. Some users may prefer fading by windows, toggling between windows and buffers, or creating their own conditions for determining when to fade or
highlight a buffer. These are all possible.

Most users should try both, there are inherit benefits to fading based on buffers as its easier to see which windows
are impacted by your edits or which windows you can cleanup.

*<sub>::vimscript::</sub>*
  ```vimscript
  let g:vimade.ncmode = 'buffers'
  ```

  ```vimscript
  let g:vimade.ncmode = 'windows'
  ```
  
---
</details>

<details open>
<summary>
<a><ins>Style modifiers</ins></a>
</summary>

<br>

Sorry this section will be updated soon.

---
</details>

<details open>
<summary>
<a><ins>Animations</ins></a>
</summary>

<br>

Sorry this section will be updated soon.

---
</details>

<details open>
<summary>
<a><ins>Recipe: Default</ins></a>
</summary>

<br>

This recipe is enabled by default, but you can re-apply it with additional customizations (e.g. animations).
You can only enable **recipes** through a configuration overlay (**no vimscript**).

*<sub>::lua:: [source](https://github.com/TaDaa/vimade/tree/master/lua/vimade/recipe/default.lua) (see here for additional params)</sub>*

```lua
local Default = require('vimade.recipe.default').Default
require('vimade').setup(Default(animate=true))
```


*<sub>::python:: [source](https://github.com/TaDaa/vimade/tree/master/lua/vimade/recipe/default.lua) (see here for additional params)</sub>*
```python
from vimade import vimade
from vimade.recipe.default import Default
vimade.setup(**Default(animate=True))
```

![](https://github.com/TaDaa/tadaa.github.io/blob/master/images/default_recipe_animate.gif)
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
local Minimalist = require('vimade.recipe.minimalist').Minimalist
require('vimade').setup(Minimalist{animate = true})
```

*<sub>::python:: [source](https://github.com/TaDaa/vimade/tree/master/lib/vimade/recipe/minimalist.py) (see here for additional params)</sub>*
<sub>NOTE:Vvim users with wincolor, minimalist will link `no_visibility_highlights` to `Normal` so that they can be toggled per-window<sub>
```python
from vimade import vimade
from vimade.recipe.minimalist import Minimalist
vimade.setup(**Minimalist(animate = True))
```

![](https://github.com/TaDaa/tadaa.github.io/blob/master/images/minimalist_recipe_animate2.gif)
---
</details>


<details>
<summary>
<a><ins>Configuration options for <b>lua</b>, <b>python</b>, and <b>vimscript</b></ins></a>
 
</summary>
<br>


| option | values/type | default | description |
| -      | -           | -       | -           |
| `renderer` | `'auto'` `'python'` `'lua'` | `'auto'` | `auto` automatically assigns **vim** users to **python** and detects if **neovim**  users have the requires features for **lua**.  For **neovim** users on **lua** mode, the **python** logic is never run. **Neovim** users with missing features will be set to **python** and need **pynvim** installed.
  | `ncmode` | `'windows'` `'buffers'` | `'buffers'` | highlight or unhighlight `buffers` or `windows` together
| `fadelevel` | `float [0-1]` `function(style,state)->float` | `0.4` | The amount of fade opacity that should be applied to fg-text (`0` is invisible and `1` is no fading)
| `tint` | <sub>When set via **lua** or **python**, each object or number can also be a function that returns the corresponding value component</sub><br><br><sub>`{'fg':{'rgb':[255,255,255], 'intensity':1, 'bg':{'rgb':[0,0,0], 'intensity':1}, 'sp':{'fg':[0,0,255], 'intensity':0.5}}}`</sub> | `nil` | The amount of tint that can be applied against each highlight component (fg, bg, sp). Intensity is a float value [0-1], where 1 is the most intense and 0 is not tinted.  See the tinting tutorial for more details (TODO link).
| `basebg` | <sub> `'#FFFFFF'` `[255,255,255]` `0xFFFFFF` </sub> | `nil` | Setting this value automatically changes the `fg` **tint** in the config object above. It is named this way for legacy reasons, prefer using the **tint** object above.
| `blocklist` | <sub>When set via **lua** or **python**, the top level named object can be a `(win) -> bool function`. Each nested object or value can also be a function `(relative_config) -> bool`.  `True` indicates blocked, `False` not linked, `nil` indeterminate.</sub><br><br><sub>`{[key:string]: {'buf_opts': {[key]:string: value}, 'buf_vars': {...}, 'win_opts': {...}, 'win_vars': 'win_config': {...}}}`</sub> | <sub>`{'default': {'buf_opts': {'buftype': ['prompt', 'terminal', 'popup']}, 'win_config': {'relative': 1}}}`</sub> | If the window is determined to be blocked, **Vimade** highlights will be removed and it will skip the styling process. See the block and linking section for more details (TODO link).
| `link` | <sub>When set via **lua** or **python**, the top level named object can be a `(win, active_win)-> bool`. Each nested object or value can also be a function `(relative_win_obj, active_win_obj) -> bool`.  `True` indicates linked, `False` not linked, `nil` indeterminate.</sub><br><br> | `nil` | Determines whether the current window should be linked and unhighlighted with the active window.  `groupdiff` and `groupscrollbind` tie into the default behavior of this object behind the scenes to unlink diffs.  See the block and linking section for more details (TODO link).
| `groupdiff` | `0` `1` `bool` | `1` | highlights and unhighlights diff windows together.
| `groupscrollbind` | `0` `1` `bool` | `0` | highlights and unhighlights scrolllbound windows together.
| `checkinterval` | `int` | `100`-`500` | Time in milliseconds before re-checking windows. Default varies depending on **Neovim**, **terminals**, and **gui vim**.
| `usecursorhold` | `0` `1` `bool` | `0` | Whether to use cursorhold events instead of async timer. Setting this option **disables the timer**. This option defaults to `0` for most editor versions.  **gvim** defaults to `1` due to async timers breaking visual selections.  If you use this value, remember to set `:set updatetime` appropriately.
| `enablefocusfading` | `0` `1` `bool` | `0` | Highlight the active window on application focus and blur events.  This can be [desirable](desirable) when switching applications, but requires additional setup for terminal and tmux.  See enablefocusfading section for more details (TODO link)
| `normalid` | `int` | nil | The id of the Normal highlight.  **Vimade** will automatically set this, so you don't need to worry about it. You can override it though if you just want to play around.
| `normalncid` | `int` | nil | The id of the NormalNC highlight.  **Vimade** will automatically set this, so you don't need to worry about it. You can override it though if you just want to play around.


---
</details>

<details>
<summary>
<a><ins>Configuration options only for <b>lua</b></ins></a>
 
</summary>
<br>

| option      | values/type | default | description                                                                                                                                                                                                                                                                                                                                         |
| -           | -           | -       | -                                                                                                                                                                                                                                                                                                                                                   |
| `nohlcheck` | `bool`      | `true`  | When set to `false`, **Vimade** will recompute namespaces each frame.  This is useful if you have a plugin that dynamically changes highlights periodically.  When to `true` **Vimade** only recomputes namespaces when you switch between buffers/windows.  Performance isn't an issue either way as the recomputation process is sub-millisecond. |

  
---
</details>

<details>
<summary>
<a><ins>Configuration options only for <b>python</b></ins></a>
 
</summary>
<br>

| option        | values/type    | default | description                                                                                                                                                                                                                                                                                                                                         |
| -             | -              | -       | -                                                                                                                                                                                                                                                                                                                                                   |
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
| Supports **Vim** + All versions of **Neovim** | Yes    |       |              |            |


## Contributing

Feel free to open a PR or file issues for bugs and feature requests. All contributions are valued even its just a question!
If you are looking for a place to share your own code and flavor in this plugin, **recipes** are a great starting place.

**Thanks for reading!**

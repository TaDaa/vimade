# vimade
([n]vim[f]ade)

### Fade, highlight, and customize your windows + buffers

![](https://tadaa.github.io/images/minimalist_full.gif)

## What is this?

**Vimade** keeps your attention focused on the active part of the screen especially in scenarios where you might have many windows open!
You can customize, highlight, fade, tint, and animate the colors in your windows and buffers.



## What is required?

**Neovim 0.8.0+**: This plugin supports a lua-only code path, you are all set!

**Vim7.4+** and **Neovim < 0.8.0** require Python or Python3 support. In these older versions of Neovim, you will need to install `pynvim`.

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
```vim
  Plug 'TaDaa/vimade'
```
  
*<sub>::lua::lazy::</sub>*
```lua
require('lazy').setup({spec = {'tadaa/vimade'}})
```
  
  <details open>
  <summary>
    <ins>For Lua users:</ins>
    
    
  This is just here to remind you that you don't need to do anything!
    
  </summary>

  </details>

  <details open>
  <summary>
    <ins>For Python users:</ins>
    
    
  If you are using **vim** or older versions of **neovim** and want to configure using **python**, you need to bind your setup to `Vimade#PythonReady`.
  This ensures that **Vimade** has been added to the python path before your configuration runs. Here's an example that sets up
  the *Minimalist* recipe.
    
  </summary>

  ```vim
function! SetupMyVimadeConfig()
python << EOF
from vimade import vimade
from vimade.recipe.minimalist import Minimalist
vimade.setup(**Minimalist(animate=True))
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

- In **Neovim** 0.8.0+, you can just use **lazy.nvim** and the event of choice:

    *<sub>::lua::lazy::</sub>*
    ```lua
    require('lazy').setup({spec = {'tadaa/vimade', event = 'VeryLazy'}})
    ```

- If you want more granular control or are using **Vim**, just enable `vimade.lazy` and then call `vimade#Load()`.  Here's an example:

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
<a><ins>Basic tutorial</ins></a>
 
</summary>
<br>

There are a number of options and ways to configure **Vimade**. Most users will only be interested in manipulating the fadelevel
and tint. **Vimade** can be configured using vimscript if you prefer a general config that is compatibile with both Neovim and Vim.
It can also be configured with Lua or Python specific configurations, which allow you to enable animations, recipes, and conditional
functions.

If you are configuring **Vimade** using vimscript in your vimrc, add the following:

*<sub>::vimscript::</sub>*
```vim
let g:vimade = {}
```

The initialization above ensures that you have a vimade object initialized regardless of where you need it.  **Vimade** will initialize
its own if it doesn't find one.  This object is automatically extended with the default values, so don't worry about adding every option.

Now you can start customizing vimade:

*<sub>::vimscript::</sub>*
```vim
let g:vimade.fadelevel = 0.5
```

Simple right? the above code changes the opacity.  You can choose any value between **0 and 1**.  You can change any option at any time
and **Vimade** will automatically react to those changes.

Let's add a blue tint:


*<sub>::vimscript::</sub>*
```vim
let g:vimade.tint = {'fg':{'rgb':[0,0,255], 'intensity': 0.5}}
```


You should notice that your text color has changed. The *tint* option lets manipulate `fg`, `bg`, and `sp` attributes. Changing `vimade.tint.bg`
lets you customize the background color of windows as well.


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
<a><ins>Preparing a transparent terminal</ins></a>


</summary>

When using a transparent terminal, your *Normal* background highlights are set to `guibg=NONE`  and the exact target colors are unknown.
In this scenario, **Vimade** by default assumes that the target color is either `black` or `white` depending on background settings.
For better color accuracy with transparent terminals, you can set `basebg` to a good target value.  If you aren't sure what the background
to use, you can perform the following steps:

1. Prepare a pure `white` background (it must be exactly `#FFFFFF`).
2. Place your terminal over the background
3. Use a color picker tool and obtain the exact color value of your terminal.  This value is the color code that your terminal
considers *transparent*.
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

There are lots of ways that you can configure tinting.  Tinting influences the color of `fg`, `bg`, and `sp` for every highlight group.
Every option allows you specify `intensity`, which determines how much color to add.

Changing the `fg` alters the text color. Let's give our inactive windows some yoda spunk:

*<sub>::vimscript::</sub>*
```vim
let g:vimade.tint = {'fg':{'rgb':[0,255,0], 'intensity': 0.3}}
```

![](http://tadaa.github.io/images/tint_section_fg_green.png)

The more that you raise the intensity, the closer each highlight will be the specified `rgb` value.  So let's say you want to disable
`syntax` highlighting on inactive windows, all you need to do is set the `intensity` to the value `1`.


*<sub>::vimscript::</sub>*
```vim
let g:vimade.tint = {'fg':{'rgb':[200,200,200], 'intensity': 1}}
```

![](http://tadaa.github.io/images/tint_section_fg_full_intensity.png)


`bg` directly impacts the window background color. It also indirectly impacts the `fg` color if you have fading enabled because
fades are performed against the background color.

*<sub>::vimscript::</sub>*
```vim
let g:vimade.tint = {'bg':{'rgb':[0,0,0], 'intensity': 0.15}}
```

![](http://tadaa.github.io/images/tint_section_bg_black.png)

 `bg` and all `tint` attributes have different effects depending on the value of `vimade.ncmode`.  When using `let g:vimade.ncmode='buffers'`,
 tints only impact inactive *buffers*.  When using `let g:vimade.ncmode='windows'` they affect windows, see the screenshots below for a
 comparison that also combines our changes above.
 
<sub>::vimscript::</sub>
``` vimscript
let g:vimade.ncmode = 'buffers'
let g:vimade.tint = {'fg':{'rgb':[0,255,0], 'intensity': 0.3},'bg': {'rgb': [0,0,0], 'intensity': 0.15}}
```

![](http://tadaa.github.io/images/tint_section_combined_buffers.png)

<sub>::vimscript::</sub>
``` vimscript
let g:vimade.ncmode = 'windows'
let g:vimade.tint = {'fg':{'rgb':[0,0,255], 'intensity': 0.3},'bg': {'rgb': [12,12,22], 'intensity': 0.2}}
```

![](http://tadaa.github.io/images/tint_section_combined_windows.png)


---
</details>

<details open>
<summary>
<a><ins>Blocklists and linking</ins></a>
 
</summary>
<br>

Sorry, tutorial not ready yet! See config options for usage.

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
  local Tint = require('vimade.style.Tint').Tint
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
  | `value` | <pre><sub>`{fg:{rgb:[num,num,num],intensity:num},`<br>` bg:{rgb:[num,num,num],intensity:num},`</sub><br><sub>` sp:{rgb:[num,num,num],intensity:num}}`</sub></pre> <sub>`function(style,state)=any`(functions can be used for any part of the tint config object)</sub> | `nil` |  The target tint colors. Intensity is the inverse of fadelevel. `1` is full intensity, while `0` is not applied.
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

![](https://tadaa.github.io/images/default_recipe_animate.gif)
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

<sub>NOTE: For **vim** users with wincolor, minimalist will link the `no_visibility_highlights` to `Normal` so that they can completely fade-out per-window.<sub>
```python
from vimade import vimade
from vimade.recipe.minimalist import Minimalist
vimade.setup(**Minimalist(animate = True))
```

![](https://tadaa.github.io/images/minimalist_recipe_animate2.gif)
---
</details>


<details>
<summary>
<a><ins>Configuration options for <b>lua</b>, <b>python</b>, and <b>vimscript</b></ins></a>
 
</summary>
<br>


| option | values/type | default | description |
| -      | -           | -       | -           |
| `renderer` | `'auto'` `'python'` `'lua'` <br> | `'auto'` | `auto` automatically assigns **vim** users to **python** and detects if **neovim**  users have the requires features for **lua**.  For **neovim** users on **lua** mode, the **python** logic is never run. **Neovim** users with missing features will be set to **python** and need **pynvim** installed.
| `ncmode` | `'windows'` `'buffers'` | `'buffers'` | highlight or unhighlight `buffers` or `windows` together
| `fadelevel` | `float [0-1]` `function(style,state)=>float` | `0.4` | The amount of fade opacity that should be applied to fg-text (`0` is invisible and `1` is no fading)
| `tint` | <sub>When set via **lua** or **python**, each object or number can also be a function that returns the corresponding value component</sub><br><br><sub>`{'fg':{'rgb':[255,255,255], 'intensity':1, 'bg':{'rgb':[0,0,0], 'intensity':1}, 'sp':{'fg':[0,0,255], 'intensity':0.5}}}`</sub> | `nil` | The amount of tint that can be applied against each highlight component (fg, bg, sp). Intensity is a float value [0-1], where 1 is the most intense and 0 is not tinted.  See the tinting tutorial for more details (TODO link).
| `basebg` | <sub> `'#FFFFFF'` `[255,255,255]` `0xFFFFFF` </sub> | `nil` | This value manipulates the target background color. This is most useful for transparent windows, where the *Normal* bg is *NONE*.  Set this value to a good target value to improve fading accuracy.
| `blocklist` | <sub>When set via **lua** or **python**, the top level named object can be a `function(win)=>bool`. Each nested object or value can also be a `function(relative_config)=>bool`.  `True` indicates blocked, `False` not linked, `nil` indeterminate.</sub><br><br><sub>`{[key:string]: {'buf_opts': {[key]:string: value}, 'buf_vars': {...}, 'win_opts': {...}, 'win_vars': 'win_config': {...}}}`</sub> | <sub> ```{'default':{'buf_opts': {'buftype':['prompt', 'terminal', 'popup']}, 'win_config': {'relative': 1}}}```</sub> | If the window is determined to be blocked, **Vimade** highlights will be removed and it will skip the styling process. See the block and linking section for more details (TODO link).
| `link` | <sub>When set via **lua** or **python**, the top level named object can be a `function(win, active_win)=>bool`. Each nested object or value can also be a `function(relative_win_obj,active_win_obj)=>bool`.  `True` indicates linked, `False` not linked, `nil` indeterminate.</sub><br><br> | `nil` | Determines whether the current window should be linked and unhighlighted with the active window.  `groupdiff` and `groupscrollbind` tie into the default behavior of this object behind the scenes to unlink diffs.  See the block and linking section for more details (TODO link).
| `groupdiff` | `0` `1` `bool` | `1` | highlights and unhighlights diff windows together.
| `groupscrollbind` | `0` `1` `bool` | `0` | highlights and unhighlights scrolllbound windows together.
| `checkinterval` | `int` | `100`-`500` | Time in milliseconds before re-checking windows. Default varies depending on **Neovim**, **terminals**, and **gui vim**.
| `usecursorhold` | `0` `1` `bool` | `0` | Whether to use cursorhold events instead of async timer. Setting this option **disables the timer**. This option defaults to `0` for most editor versions.  **gvim** defaults to `1` due to async timers breaking visual selections.  If you use this value, remember to set `:set updatetime` appropriately.
| `enablefocusfading` | `0` `1` `bool` | `0` | Highlight the active window on application focus and blur events.  This can be [desirable](desirable) when switching applications, but requires additional setup for terminal and tmux.  See enablefocusfading section for more details (TODO link)
| `normalid` | `int` | nil | The id of the Normal highlight.  **Vimade** will automatically set this, so you don't need to worry about it. You can override it though if you just want to play around.
| `normalncid` | `int` | nil | The id of the NormalNC highlight.  **Vimade** will automatically set this, so you don't need to worry about it. You can override it though if you just want to play around.
| `lazy` | `1` `0` | nil | When set to `1` **Vimade** is disabled at startup. You will need to manually call `vimade#Load()`.  See lazy loading section for more details.


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

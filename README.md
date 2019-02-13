# vimade


###### An eye catching plugin that fades your inactive buffers and preserves syntax highlighting!!!!

##### Screenshots

**Fade inactive windows**

![](http://tadaa.github.io/images/vimade_fade.gif)

**Change the colorscheme and fadelevel on the fly**

![](http://tadaa.github.io/images/vimade_colorscheme.gif)
![](http://tadaa.github.io/images/vimade_fadelevel.gif)

**Fade/Unfade diffs together**

![](http://tadaa.github.io/images/vimade_diff.gif)


##### Features
- [X] Fade inactive buffers
- [X] Fade/Unfade diffs together
- [X] Automatically adjust to colorscheme changes
- [X] Automatically adjust to basebg changes
- [X] Automatically adjust to fadelevel changes
- [X] React to window resize + scroll changes
- [X] Apply custom tints (not necessarily your background color to text)
- [X] Vim8+
- [X] Neovim + also plays well with NormalNC
- [X] Python3
- [X] Python2
- [X] 256 color terminal support (Xterm)
- [X] Toggle vimade on/off (VimadeEnable, VimadeDisable, VimadeToggle)
- [X] Supports terminal backgrounds for Vim8(not nvim yet) and iTerm, Tilix, Kitty, Gnome, rxvt
- [X] Wrapped Text
- [X] Sign column support (disabled by default)
- [ ] Secondary buffer window highlighting
- [ ] Vim Documentation/Help

###### Todo
- [ ] Support other terminals palletes? -- Open an issue if you need support for a different terminal or palette
- [ ] Improve terminal color rounding for grays
- [ ] Experiment with threading to improve performance, this may be necessary to implement limelight.  This will also be beneficial to the SignColumn logic
- [ ] Experiment with highlighted text within current window (limelight behavior)
- [ ] Cleanup this Readme!
- [ ] Code cleanup
- [ ] Tests

##### What/Why?
- Vimade fades inactive/unfocused buffer text and removes the fade from focused buffers. 
- Vimade diffs and multiple windows linked to the same buffer are treated as a group that highlights/unhighlights together.
- Vimade reacts to scrolling, tab changes, colorscheme changes, diff, and much more!

##### Install
*Add `TaDaa/vimade` to your vimrc -- you can use any plugin manager e.g:*
```
Plugin 'TaDaa/vimade'
```

##### Config
Vimade is initialized with the following configuration.  Vimade will react to configuration changes on the fly:
```
let g:vimade = {
  \ "normalid": '',
  \ "normalncid": '',
  \ "basefg": '',
  \ "basebg": '',
  \ "fadelevel": 0.4,
  \ "colbufsize": 15,
  \ "rowbufsize": 15,
  \ "checkinterval": 100,
  \ "usecursorhold": 0, "0 is default, but will automatically set to 1 for Windows GVIM
  \ "detecttermcolors": 1,
  \ 'enablesigns': 0,
  \ 'signsretentionperiod': 4000,
}
```
- **vimade.normalid** - if not specified, the normalid is determined when vimade is first loaded.  normalid provides the id of the "Normal" highlight which is used to calculate fading.  You can override this config with another highlight group.
- **vimade.normalncid** - if not specified, the normalncid is determined when vimade is first loaded.  normalncid provides the id of the "NormalNC" highlight which is used to calculate fading for inactive buffers in NVIM.  You can override this config with another highlight group.
- **vimade.basefg** - basefg can either be six digit hexidecimal color, rgb array [0-255,0-255,0-255], or cterm code (in terminal).  Basefg is only used to calculate the default fading that should be applied to Normal text.  By default basefg is calculated as the "Normal" highlight guifg or ctermfg.
- **vimade.basebg** - basebg can be either be six digit hexidecimal color, rgb array [0-255,0-255,0-255], or cterm code (in terminal).  basebg is used as the color that text is faded against.  You can override this config with another hexidecimal color.  A cool feature of basebg is to use it to change the tint of faded text even if its not your background!
- **vimade.fadelevel** - amount of fading applied between text and basebg.  0 will make the text the same color as the background and 1 applies no fading.  The default value is 0.4.  If you are using terminal, you may need to tweak this value to get better results.
- **vimade.rowbufsize** - the number of rows above and below of the determined scroll area that should be precalculated. Default is 15.
- **vimade.colbufsize** - the number of cols left and right of the determined scroll area that should be precalculated. Default is 15.
- **vimade.checkinterval** - the amount of time in milliseconds that vimade should check the screen for changes.  This config is mainly used to detect resize and scroll changes that occur on inactive windows. Checkinterval does nothing on gvim, if you want to control the refresh time, see 'h updatetime'. Default is 100.  
- **vimade.usecursorhold** -  disables the timer running in the background and instead relies `OnCursorHold` and `updatetime` (see h:updatetime).  The default value is `0` except on Windows GVIM, which defaults to `1` due to the timer breaking movements.  If you find that the timer is causing performance problems or other issues you can disable it by setting this option to `1`. 
- **vimade.detecttermcolors** - detect the terminal background and foreground colors.  This will work for Vim8 + iTerm, Tilix, Kitty, Gnome, Rxvt, and other editors that support the following query (```\033]11;?\007``` or ```\033]11;?\033\\```).  Default is 1.
- **vimade.enablesigns** - Enables sign fading.  This feature is disabled by default due to how signs affect performance, however this plugin is heavily optimized and alleviates most sign performance issues. Give it a go and open an issue if you see performance drops.  Default is 0.
- **vimade.signsretentionperiod** - The amount of time in milliseconds that faded buffers should be tracked for sign changes.  Default value is 4000.

##### Example
*this example reduces the amount of fading applied to text*
```
let g:vimade = {}
let g:vimade.fadelevel = 0.7
```
##### Commands
- **VimadeEnable** - Turns vimade on (Vimade is on by default)
- **VimadeDisable** - Turns vimade off and unfades all buffers
- **VimadeToggle** - Toggles between on/off states
- **VimadeRedraw** - Forces vimade to redraw fading for every window.
- **VimadeFadeLevel [0.0-1.0]** - Sets the FadeLevel config and forces an immediate redraw.
- **VimadeInfo** - Provides debug information for Vimade.  Please include this info in bug reports

##### FAQ/HELP
I am using GVIM and my mappings are not working
- *Add `let g:vimade.usecursorhold=1` to your vimrc*

Sometimes I hear an annoying bell sound when starting vim/nvim
- *Add `let g:vimade.detecttermcolors=0` to your vimrc -- the color detection may cause this sound on unsupported terminals*

What about Vim < 8?
- *Vim 7 is currently untested/experimental, but may work if you add `let g:vimade.usecursorhold=1` to your vimrc*

My colors look off in terminal mode!
- *Make sure that you either use a supported terminal or colorscheme or manually define the fg and bg for 'Normal'.  You can also manually define the tint in your vimade config (g:vimade.basebg and g:vimade.basefg)*

Tmux is not working!
- *Vimade only works in 256 color mode and by default TMUX may set t_Co to 8.   it is recommended that you set `export TERM=xterm-256color` before starting vim.  You can also set `set termguicolors` inside vim if your term supports it for an even more accurate level of fading.*



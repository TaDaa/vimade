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


##### Compatibility
- gui vim8+
- gui nvim
- xterm 256 colors
- leave an issue if you need a different terminal palette supported

##### What/Why?
- Vimade fades inactive/unfocused buffer text and removes the fade from focused buffers. 
- Vimade diffs and multiple windows linked to the same buffer are treaded as a group that highlights/unhighlights together.
- Vimade reacts to scrolling, tab changes, colorscheme changes, diff, and much more!

##### Install
*Add `TaDaa/vimade` to your vimrc -- you can use any plugin manager e.g:*
```
Plugin 'TaDaa/vimade'
```

##### Init Config
- **g:vimade_usecursorhold** - When enabled, this optional config disables the timer running in the background and instead relies `OnCursorHold` and `updatetime` (see h:updatetime).  The default value is `0` except on Windows GVIM, which defaults to `1` due to the timer breaking movements.  If you find that the timer is causing performance problems or other issues you can disable it by setting this option to `1`. 
- **g:vimade_detect_term_colors** - Enabled by default.  When enabled, Vimade will try to detect the terminal background and foreground colors during init.  This will work for Vim8 + Tilix, Kitty, Gnome, Rxvt, and other editors that support the following query (```\033]11;?\007``` or ```\033]11;?\033\\```). 

##### Live Config
Vimade is initialized with the following configuration:
```
let g:vimade = {
  \ "normalid": '',
  \ "basefg": '',
  \ "basebg": '',
  \ "fadelevel": 0.4,
  \ "colbufsize": 30,
  \ "rowbufsize": 30,
  \ "checkinterval": 32,
}
```
- **vimade.normalid** - if not specified, the normalid is determined when vimade is first loaded.  normalid provides the id of the "Normal" highlight which is used to calculate fading.  You can override this config with another highlight group.
- **vimade.basefg** - basefg is a hexidecimal color (in gui) and a 256 color code (in term).  By default basefg is calculated as the "Normal" highlight guifg or ctermfg.
- **vimade.basebg** - basebg is a hexidecimal color (in gui) and a 256 color code (in term).  basebg is used as the color that text is faded against.  You can override this config with another hexidecimal color.
- **vimade.fadelevel** - amount of fading applied between text and basebg.  0 will make the text the same color as the background and 1 applies no fading.  The default value is 0.4.  If you are using terminal, you may need to tweak this value to get better results.
- **vimade.rowbufsize** - the number of rows above and below of the determined scroll area that should be precalculated. Default is 30.
- **vimade.colbufsize** - the number of cols left and right of the determined scroll area that should be precalculated. Default is 30.
- **vimade.checkinterval** - the amount of time in milliseconds that vimade should check the screen for changes.  This config is mainly used to detect resize and scroll changes that occur on inactive windows. Checkinterval does nothing on gvim, if you want to control the refresh time, see 'h updatetime'. Default is 32.  

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
- **VimadeInfo** - Provides debug information for Vimade.  Please include this info in bug reports


##### Features
- [X] Fade inactive buffers
- [X] Fade/Unfade diffs together
- [X] Automatically adjust to colorscheme changes
- [X] Automatically adjust to basebg changes
- [X] Automatically adjust to fadelevel changes
- [X] React to window resize + scroll changes
- [X] Vim8+ (gui)
- [X] Neovim (gui)
- [X] Python3
- [X] Python2
- [X] 256 color terminal support (Xterm)
- [X] Toggle vimade on/off (VimadeEnable, VimadeDisable, VimadeToggle)
- [X] Supports terminal backgrounds for Vim8(not nvim yet) and Tilix, Kitty, Gnome, rxvt
- [ ] Secondary buffer window highlighting
- [ ] Vim Documentation/Help

###### Todo
- [ ] Support other terminals palletes? -- Open an issue if you need support for a different palette
- [ ] Improve terminal color rounding for grays
- [ ] Wrapped Text
- [ ] Experiment with highlighted text within current window (limelight behavior)
- [ ] Investigate sign column





##### FAQ/HELP
I am using GVIM and my mappings are not working
- *Add `let g:vimade_usecursorhold=1` to your vimrc*
Sometimes I hear an annoying bell sound when starting vim/nvim
- *Add `let g:vimade_detect_term_color=0` to your vimrc -- the color detection may cause this sound on unsupported terminals

What about Vim < 8?
- *Vim 7 is currently untested/experimental, but may work if you add `let g:vimade_usecursorhold=1` to your vimrc*

My colors look off in terminal mode!
- *Make sure that you either use a supported terminal or colorscheme or manually define the fg and bg for 'Normal'.  You can also manually define the tint in your vimade config (g:vimade.basebg and g:vimade.basefg)*

Tmux is not working!
- *Vimade only works in 256 color mode, it is recommended that you set `export TERM=xterm-256color` before starting vim

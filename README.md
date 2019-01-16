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
Bundle 'TaDaa/vimade'
```

##### Config
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
- [ ] Secondary buffer window highlighting
- [ ] Vim Documentation/Help

###### Todo
- [ ] Support other terminals palletes? -- Open an issue if you need support for a different palette
- [ ] Improve terminal color rounding for grays
- [ ] Wrapped Text
- [ ] Experiment with highlighted text within current window (limelight behavior)
- [ ] Investigate sign column

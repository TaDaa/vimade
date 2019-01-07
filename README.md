# vimade


###### An eye catching plugin that fades your inactive buffers and preserves syntax highlighting!!!!

##### Screenshots



##### Compatibility
- gui vim8+
- gui nvim
- terminal support is coming

##### What/Why?
- Vimade fades inactive/unfocused buffer text and removes the fade from focused buffers. 
- Vimade diffs and multiple windows linked to the same buffer are treaded as a group that highlights/unhighlights together.
- Vimade reacts to scrolling, tab changes, colorscheme changes, diff, and much more!

##### Install
*Add `tadaa/vimade` to your vimrc -- you can use any plugin manager e.g:*
```
Bundle 'tadaa/vimade'
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
- **vimade.basefg** - basefg is a hexidecimal color code.  It's default is calculated as the "Normal" highlight guifg. 
- **vimade.basebg** - basebg is a hexidecimal color code that is used as the color that text is faded against.  You can override this config with another hexidecimal color.
- **vimade.fadelevel** - amount of fading applied between text and basebg.  0 will make the text the same color as the background and 1 applies no fading.  The default value is 0.4
- **vimade.rowbufsize** - the number of rows above and below of the determined scroll area that should be precalculated. Default is 30.
- **vimade.colbufsize** - the number of cols left and right of the determined scroll area that should be precalculated. Default is 30.
- **vimade.checkinterval** - the amount of time in milliseconds that vimade should check the screen for changes.  This config is mainly used to detect resize and scroll changes that occur on inactive windows.  Default is 32.

##### Example
*this example reduces the amount of fading applied to text*
```
let g:vimade = {}
let g:vimade.fadelevel = 0.7
```



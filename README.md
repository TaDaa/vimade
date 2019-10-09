# vimade


###### An eye catching plugin that fades your inactive buffers and preserves syntax highlighting!!!!

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

##### Features
- [X] Fade inactive buffers
- [X] Fade/Unfade diffs together
- [X] Automatically adjust to colorscheme changes
- [X] Automatically adjust to basebg changes
- [X] Automatically adjust to fadelevel changes
- [X] Automatically adjust to &syntax changes
- [X] React to window resize + scroll changes
- [X] Apply custom tints (not necessarily your background color to text)
- [X] Vim8+
- [X] Neovim + also plays well with NormalNC
- [X] Python3
- [X] Python2
- [X] GUI Neovim + GUI Vim
- [X] 256 color terminal support (Xterm)
- [X] Toggle vimade on/off (VimadeEnable, VimadeDisable, VimadeToggle)
- [X] Supports terminal backgrounds for Vim8(not nvim yet) and iTerm, Tilix, Kitty, Gnome, rxvt
- [X] Wrapped Text
- [X] Folded Text (detects folded rows and fades above/below -- see VimadeOverrideFolded for highlight recommendations on hi Folded)
- [X] :ownsyntax support
- [X] Sign column support (disabled by default)
- [X] Vim Documentation/Help
- [ ] Secondary buffer window highlighting

###### Whats coming?
- [ ] Helpers to fade Vim global highlights (e.g VertSplit, Folded, NonText, etc -- will alleviate issues with high contrast in some colorschemes)
- [ ] Configurable FadeLevel per buffer
- [ ] Conditional interface to determine which windows/buffers get faded/unfaded.
- [ ] Performance Improvements
- [ ] Limelight with syntax highlighting
- [ ] Improve terminal color rounding for grays
- [ ] Code cleanup
- [ ] Tests

##### What/Why?
- Vimade fades inactive/unfocused buffer text and removes the fade from focused buffers. 
- Vimade diffs and multiple windows linked to the same buffer are treated as a group that highlights/unhighlights together.
- Vimade reacts to scrolling, tab changes, colorscheme changes, diff, and much more!

##### Install
*Add `TaDaa/vimade` to your vimrc -- you can use any plugin manager e.g:*
```
Plug 'TaDaa/vimade'
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
  \ "colbufsize": 15, "15 is the default for gui vim, 5 is the default for terminals and gvim
  \ "rowbufsize": 15, "15 is the default for gui vim, 0 is the default for terminals and gvim
  \ "checkinterval": 100, "100 is the default for gui vim, 500 is the default for terminals and neovim
  \ "usecursorhold": 0, "0 is default, but will automatically set to 1 for Windows GVIM
  \ "detecttermcolors": 0,
  \ 'enablescroll': 1, "1 is the default for gui vim, but will automatically set to 0 for terminals and Windows GVIM.
  \ 'enablesigns': 0,
  \ 'signsid': 13100,
  \ 'signsretentionperiod': 4000,
  \ 'fademinimap': 1,
  \ 'fadepriority': 10,
  \ 'groupdiff': 1,
  \ 'groupscrollbind': 0,
  \ 'enablefocusfading': 0,
}
```
- **vimade.normalid** - if not specified, the normalid is determined when vimade is first loaded.  normalid provides the id of the "Normal" highlight which is used to calculate fading.  You can override this config with another highlight group.
- **vimade.normalncid** - if not specified, the normalncid is determined when vimade is first loaded.  normalncid provides the id of the "NormalNC" highlight which is used to calculate fading for inactive buffers in NVIM.  You can override this config with another highlight group.
- **vimade.basefg** - basefg can either be six digit hexidecimal color, rgb array [0-255,0-255,0-255], or cterm code (in terminal).  Basefg is only used to calculate the default fading that should be applied to Normal text.  By default basefg is calculated as the "Normal" highlight guifg or ctermfg.
- **vimade.basebg** - basebg can be either be six digit hexidecimal color, rgb array [0-255,0-255,0-255], or cterm code (in terminal).  basebg is used as the color that text is faded against.  You can override this config with another hexidecimal color.  A cool feature of basebg is to use it to change the tint of faded text even if its not your background!
- **vimade.fadelevel** - amount of fading applied between text and basebg.  0 will make the text the same color as the background and 1 applies no fading.  The default value is 0.4.  If you are using terminal, you may need to tweak this value to get better results.
- **vimade.rowbufsize** - the number of rows above and below of the determined scroll area that should be precalculated. Reduce this value to improve performance. Default is 15 for gui vim and 0 for terminals/gvim.
- **vimade.colbufsize** - the number of cols left and right of the determined scroll area that should be precalculated. Reduce this value to improve performance. Default is 15 for gui vim and 1 for terminals/gvim.
- **vimade.checkinterval** - the amount of time in milliseconds that vimade should check the screen for changes.  This config is mainly used to detect resize and scroll changes that occur on inactive windows. Checkinterval does nothing on gvim, if you want to control the refresh time, see 'h updatetime'. Default is 100.  
- **vimade.usecursorhold** -  disables the timer running in the background and instead relies `OnCursorHold` and `updatetime` (see h:updatetime).  The default value is `0` except on Windows GVIM, which defaults to `1` due to the timer breaking movements.  If you find that the timer is causing performance problems or other issues you can disable it by setting this option to `1`. 
- **vimade.detecttermcolors** - detect the terminal background and foreground colors.  This will work for Vim8 + iTerm, Tilix, Kitty, Gnome, Rxvt, and other editors that support the following query (```\033]11;?\007``` or ```\033]11;?\033\\```).  Default is 0.  Enable this at your own risk as it can cause unwanted side effects.
- **vimade.enablesigns** - Enables sign fading.  This feature is disabled by default due to how signs affect performance, however these are performance impacts are mostly solved in the latest versions of vim. 
- **vimade.enablescroll** - Enables fading while scrolling inactive windows.  This is only useful in gui vim and does have a performance cost.  By default this setting is enabled in gui vim and disabled for terminals.
- **vimade.signsid** - The starting id that Vimade should use when creating new signs. By default Vim requires numeric values to create signs and its possible that collisions may occur between plugins.  If you need to override this value for compatibility, please open an issue as well.  Default is 13100.
- **vimade.signspriority** - Controls the signs fade priority. You may need to change this value if you find that not all signs are fading properly.  Please also open a defect if you need to tweak this value as Vimade strives to minimize manual configuration where possible.  Default is 31.
- **vimade.signsretentionperiod** - The amount of time in milliseconds that faded buffers should be tracked for sign changes.  Default value is 4000.
- **vimade.fademinimap** - Enables a special fade effect for `severin-lemaignan/vim-minimap`.  Setting vimade.fademinimap to 0 disables the special fade.  Default is 1.
- **vimade.fadepriority** - Controls the highlighting priority.  You may want to tweak this value to make Vimade play nicely with other highlighting plugins and behaviors.  For example, if you want hlsearch to show results on all buffers, you may want to lower this value to 0.  Default is 10.
- **vimade.groupdiff** - Controls whether or not diffs will fade/unfade together.  If you want diffs to be treated separately, set this value to 0. Default is 1.
- **vimade.groupscrollbind** - Controls whether or not scrollbound windows will fade/unfade together.  If you want scrollbound windows to unfade together, set this to 1.  Default is 0.
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

##### FAQ/Help
I am using GVIM and my mappings are not working
- *Add `let g:vimade.usecursorhold=1` to your vimrc*

What about Vim < 8?
- *Vim 7 is currently untested/experimental, but may work if you add `let g:vimade.usecursorhold=1` to your vimrc*

My colors look off in terminal mode!
- *Make sure that you either use a supported terminal or colorscheme or manually define the fg and bg for 'Normal'.  You can also manually define the tint in your vimade config (g:vimade.basebg and g:vimade.basefg)*

Tmux is not working!
- *Vimade only works in a 256 or higher color mode and by default TMUX may set t_Co to 8.   it is recommended that you set `export TERM=xterm-256color` before starting vim.  You can also set `set termguicolors` inside vim if your term supports it for an even more accurate level of fading.*



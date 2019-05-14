if exists('g:vimade_loaded')
  finish
endif
if !exists('g:vimade_running')
  let g:vimade_running = 1
endif

let g:vimade_loaded = 1

let g:vimade_error_count = 0

let g:vimade_is_nvim = has('nvim')

""The vimade configuration object
"@setting vimade

let g:vimade_defaults = {
  \ '$extended': 1,
\ }

""@setting vimade.normalid
"If not specified, the normalid is determined when vimade is first loaded.  normalid provides the id of the "Normal" highlight which is used to calculate fading.  You can override this config with another highlight group.

let g:vimade_defaults.normalid = ''

""@setting vimade.normalncid
"If not specified, the normalncid is determined when vimade is first loaded.  normalncid provides the id of the "NormalNC" highlight which is used to calculate fading for inactive buffers in NVIM.  You can override this config with another highlight group.

let g:vimade_defaults.normalncid = ''

""@setting vimade.basefg
"basefg can either be six digit hexidecimal color, rgb array [0-255,0-255,0-255], or cterm code (in terminal).  Basefg is only used to calculate the default fading that should be applied to Normal text.  By default basefg is calculated as the "Normal" highlight guifg or ctermfg.

let g:vimade_defaults.basefg = ''

""@setting vimade.basebg
"basebg can be either be six digit hexidecimal color, rgb array [0-255,0-255,0-255], or cterm code (in terminal).  basebg is used as the color that text is faded against.  You can override this config with another hexidecimal color.  A cool feature of basebg is to use it to change the tint of faded text even if its not your background!

let g:vimade_defaults.basebg = ''

""@setting vimade.fadelevel
"Amount of fading applied between text and basebg.  0 will make the text the same color as the background and 1 applies no fading.  The default value is 0.4.  If you are using terminal, you may need to tweak this value to get better results.

let g:vimade_defaults.fadelevel = 0.4

""@setting vimade.colbufsize
"The number of cols left and right of the determined scroll area that should be precalculated. Default is 15.

let g:vimade_defaults.colbufsize = 15

""@setting vimade.rowbufsize
"The number of rows above and below of the determined scroll area that should be precalculated. Default is 15.

let g:vimade_defaults.rowbufsize = 15

""@setting vimade.checkinterval
"The amount of time in milliseconds that vimade should check the screen for changes.  This config is mainly used to detect resize and scroll changes that occur on inactive windows. Checkinterval does nothing on gvim, if you want to control the refresh time, see 'h updatetime'. Default is 100 for gui vim and 500 for neovim/terminal.  

let g:vimade_defaults.checkinterval = has('gui_running') && !has('nvim') ? 100 : 500

""@setting vimade.usecursorhold
"Disables the timer running in the background and instead relies `OnCursorHold` and `updatetime` (see h:updatetime).  The default value is `0` except on Windows GVIM, which defaults to `1` due to the timer breaking movements.  If you find that the timer is causing performance problems or other issues you can disable it by setting this option to `1`. 

let g:vimade_defaults.usecursorhold = has('gui_running') && !has('nvim') && execute('version')=~"GUI version"

""@setting vimade.detecttermcolors
"Detect the terminal background and foreground colors.  This will work for Vim8 + iTerm, Tilix, Kitty, Gnome, Rxvt, and other editors that support the following query (```\033]11;?\007``` or ```\033]11;?\033\\```).  Default is 1.

let g:vimade_defaults.detecttermcolors = 1

""@setting vimade.enablesigns
"Enables sign fading.  This feature is disabled by default due to how signs affect performance, however this plugin is heavily optimized and alleviates most sign performance issues. Give it a go and open an issue if you see performance drops.  Default is 0.

let g:vimade_defaults.enablesigns = 0

""@setting vimade.signsretentionperiod
"Amount of time in milliseconds that faded buffers should be tracked for sign changes.  Default value is 4000.

let g:vimade_defaults.signsretentionperiod = 4000



let g:vimade_defaults_keys = keys(g:vimade_defaults)
if !exists('g:vimade')
  let g:vimade = {}
endif
call vimade#ExtendState()

if exists('g:vimade_detect_term_colors')
  let g:vimade.detecttermcolors = g:vimade_detect_term_colors
endif

if exists('g:vimade_usecursorhold')
  let g:vimade.usecursorhold = g:vimade_usecursorhold
endif

if !exists('g:vimade_py_cmd')
    if has('python3')
        let g:vimade_py_cmd = "py3"
    elseif has('python')
        let g:vimade_py_cmd = "py"
    else
        finish
    endif
endif

let g:vimade_last = extend({}, g:vimade)

let g:vimade_plugin_current_directory = resolve(expand('<sfile>:p:h').'/../lib')
exec g:vimade_py_cmd  join([
    \ "import vim",
    \ "sys.path.append(vim.eval('g:vimade_plugin_current_directory'))",
\ ], "\n")


""Enables Vimade
command! VimadeEnable call vimade#Enable()

""Unfades all buffers, signs, and disables Vimade
command! VimadeDisable call vimade#Disable()

""Disables the current window
command! VimadeWinDisable call vimade#WinDisable()

""Disables the current buffer
command! VimadeBufDisable call vimade#BufDisable()


""Enables the current window
command! VimadeWinEnable call vimade#WinEnable()

""Enables the current buffer
command! VimadeBufEnable call vimade#BufEnable()

""Toggles Vimade between enabled and disabled states
command! VimadeToggle call vimade#Toggle()

""Prints debug information that should be included in bug reports
command! VimadeInfo echo json_encode(vimade#GetInfo())

""Recalculates all fades and redraws all inactive buffers and signs
command! VimadeRedraw call vimade#Redraw()

""Changes vimade_fadelevel to the {value} specified.  {value} can be between
"0.0 and 1.0
command! -nargs=1 VimadeFadeLevel call vimade#FadeLevel(<q-args>)

if v:vim_did_enter
  call vimade#Init()
endif

call vimade#UpdateEvents()

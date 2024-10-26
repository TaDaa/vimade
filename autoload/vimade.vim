function! vimade#Empty()
endfunction

function! vimade#CreateGlobals()
  "let g:vimade_lua_renderer = exists('g:vimade') && get(g:vimade, 'renderer') =~ 'lua'
  "let g:vimade_py_v2_renderer = exists('g:vimade') && get(g:vimade, 'renderer') =~ 'python-v2'

  if !exists('g:vimade_running')
    ""@setting vimade_running
    "This flag is used to control whether or not vimade should be running.  This can be useful to toggle vimade during startup.  Alternatively, you may as also use VimadeDisable, VimadeEnable, call vimade#Disable, call vimade#Enable respectively

    let g:vimade_running = 1
  endif
  let g:vimade_paused = 0
  let g:vimade_error_count = 0
  let g:vimade_fade_active = 0
  if !exists('g:vimade')
    let g:vimade = {}
  endif
endfunction

function! vimade#SetupRenderer()
  let l:next_renderer = g:vimade_active_renderer.name
  " TODO remove python-legacy below when ready to release and switch to renderer='auto'
  if ((g:vimade.renderer == 'auto' || (g:vimade.renderer == 'python-legacy' && g:vimade_features.supports_python_renderer == 0)) && g:vimade_features.supports_lua_renderer) || g:vimade.renderer == 'lua'
    let l:next_renderer = 'lua'
  else
    if g:vimade_python_setup == 0
      call vimade#SetupPython()
    endif
    if g:vimade.renderer == 'auto'
      let l:next_renderer = 'python'
    elseif g:vimade.renderer == 'python' || g:vimade.renderer == 'python-legacy'
      let l:next_renderer = g:vimade.renderer
    endif
  endif
  if l:next_renderer != g:vimade_active_renderer.name
    try
      call vimade#UnfadeAll()
    catch
    endtry
    if l:next_renderer == 'lua'
      let g:vimade_active_renderer = s:lua_renderer
    elseif l:next_renderer == 'python'
      let g:vimade_active_renderer = s:python_renderer
    elseif l:next_renderer == 'python-legacy'
      let g:vimade_active_renderer = s:python_legacy_renderer
    else
      let g:vimade_active_renderer = s:empty_renderer
    endif
  endif
endfunction

function! vimade#SetupPython()
  let g:vimade_python_setup = 1
  " find proper command
  if !exists('g:vimade_py_cmd')
    if has('python3')
      let g:vimade_py_cmd = "py3"
    elseif has('python')
      let g:vimade_py_cmd = "py"
    else
      return
    endif
    exec g:vimade_py_cmd  join([
          \ "import vim",
          \ "sys.path.append(vim.eval('g:vimade_plugin_current_directory'))",
          \ ], "\n")
  endif
endfunction

function! vimade#GetFeatures()
  if !exists('g:vimade_features')
    let g:vimade_features = {}
    let g:vimade_features.has_gui_running = has('gui_running')
    let g:vimade_features.has_gui = has('gui')
    let g:vimade_features.has_nvim = has('nvim')
    let g:vimade_features.has_vimr = has('gui_vimr')
    try
      let g:vimade_features.has_python = has('python')
    catch
      let g:vimade_features.has_python = 0
    endtry
    let g:vimade_features.has_python3 = has('python3')
    let g:vimade_features.has_gui_version = !has('nvim') && (execute('version')=~"GUI version")
    let g:vimade_features.has_timer_start = exists('*timer_start')
    let g:vimade_features.has_sign_getplaced = exists('*sign_getplaced')

    " Below are for lua renderer

    " Required:
    " Required: nvim_win_set_hl_ns
    let g:vimade_features.has_nvim_win_set_hl_ns = exists('*nvim_win_set_hl_ns')
    " Required:
    " Either (preferred) nvim_get_hl
    let g:vimade_features.has_nvim_get_hl = exists('*nvim_get_hl')
    " Or (fallback) nvim__get_hl_defs + nvim_get_hl_by_name (assume supported)
    let g:vimade_features.has__nvim_get_hl_defs = exists('*nvim__get_hl_defs')
    
    "Optional:
    " preferred but not required nvim_get_hl_ns
    " fallback is try and manually track (probably will have conflicts with some plugins)
    let g:vimade_features.has_nvim_get_hl_ns = exists('*nvim_get_hl_ns')

    let g:vimade_features.supports_lua_renderer = (g:vimade_features.has_nvim_get_hl || g:vimade_features.has__nvim_get_hl_defs) && g:vimade_features.has_nvim_win_set_hl_ns

    let g:vimade_features.has_python3 = has('python3')
    let g:vimade_features.has_python = has('python')
    let g:vimade_features.supports_python_renderer = g:vimade_features.has_python3 || g:vimade_features.has_python

    try
      sign define Vimade_Test text=1
      sign place 1 group=vimade line=1 name=Vimade_Test priority=100
      sign unplace 1 group=vimade
      let g:vimade_features.has_sign_group = 1
      let g:vimade_features.has_sign_priority = 1
    catch
      let g:vimade_features.has_sign_group = 0
      let g:vimade_features.has_sign_priority = 0
    endtry
  endif
  return g:vimade_features
endfunction

function! vimade#GetDefaults()
  if !exists('g:vimade_defaults')

    ""The vimade configuration object
    "@setting vimade
    
    let g:vimade_defaults = {'$extended': 1}

    ""@setting vimade.renderer
    "If not specificed, defaults to ['python-legacy']. This default value will soon change to 'auto'.
    "Current options are:
    "  - 'auto' - Uses lua renderer if supported on your Neovim version
    "  - 'python' - Uses a new high performance renderer compatible with Vim and Neovim
    "  - 'python-legacy' - Uses the legacy and stable python renderer that Vimade has relied on for the last 6 years. This will be removed once all bugs have been fixed in new renderers.

    let g:vimade_defaults.renderer = 'python-legacy'

    ""@setting vimade.fadelevel
    "Supported:     lua, python, python-legacy
    "Amount of fading applied between text and basebg.  0 will make the text the same color as the background and 1 applies no fading.  The default value is 0.4.  If you are using terminal, you may need to tweak this value to get better results.

    let g:vimade_defaults.fadelevel = 0.4
    
    ""@setting vimade.tint
    "Supported:     lua, python
    "Amount and type of tinting to apply. Unset by default.  This param is currently under maintainence. This function can currently be either a config object such as:
    "{'fg':{'rgb':[255,0,0], 'intensity': 0.5, 'type': 'MIX'}, 'bg':{'rgb':[255,0,0], 'type': 'REPLACE'}, 'sp': {'rgb':[255,0,0], 'type': 'MIX'}}
    "The fields in the object are completely optional (you can peform a bg-only or fg-only tint)
    "You can also set g:vimade.tint to a lua or python function that returns the tint object.
    "Lua
    "require('vimade').setup({
    " tint = function (win)
    "   return {
    "    fg = {
    "      rgb={255,0,0},
    "      intensity = 0.75,
    "    },
    "  }
    " end
    "})
    "Python
    "from vimade.v2 import vimade
    "vimade.setup({
    " 'tint': lambda a,test : {'fg':{'rgb':[255,0,0], 'intensity': 0.5}}
    "})

    ""@setting vimade.basebg
    "Supported:     lua, python, python-legacy
    "basebg can be either be six digit hexidecimal color, rgb array [0-255,0-255,0-255], or cterm code (in terminal).  basebg is used as the color that text is faded against.  You can override this config with another hexidecimal color.  A cool feature of basebg is to use it to change the tint of faded text even if its not your background!

    let g:vimade_defaults.basebg = ''

    ""@setting vimade.fademode
    "Supported:     lua, python, python-legacy
    "Whether to fade active windows or buffers.  Options are 'windows' or 'buffers'.  Defaults to 'buffers'.

    let g:vimade_defaults.fademode = 'buffers'

    ""@setting vimade.fadecondition
    "Supported:     lua, python
    "TODO docs

    "Can be set via vim object
    ""@setting vimade.blocklist
    "Supported:     lua, python
    "TODO docs

    ""@setting vimade.link
    "Supported:     lua, python
    "Controls whether or not diffs will fade/unfade together.
    "TODO docs


    ""@setting vimade.groupdiff
    "Supported:     lua, python, python-legacy
    "Controls whether or not diffs will fade/unfade together.  If you want diffs
    "to be treated separately, set this value to 0. Default is 1

    let g:vimade_defaults.groupdiff = 1

    ""@setting vimade.groupscrollbind
    "Supported:     lua, python, python-legacy
    "Controls whether or not scrollbound windows will fade/unfade together.  If
    "you want scrollbound windows to unfade together, set this to 1.  Default is
    "0.
    
    let g:vimade_defaults.groupscrollbind = 0

    ""@setting vimade.enablefocusfading
    "Supported:     lua, python, python-legacy
    "Fades the current active window on focus blur and unfades when focus gained.
    "This can be desirable when switching applications or TMUX splits.
    "* Install 'tmux-plugins/vim-tmux-focus-events' using your preferred plugin manager
    "* Add `set -g focus-events on` to your tmux.conf
    "* Neovim should work at this point, If you are using Vim you may also need the following snippet to the very end of your vimrc
    ">
    "  if has('gui_running') == 0 && has('nvim') == 0
    "     call feedkeys(":silent execute '!' | redraw!\<CR>")
    "  endif
    "<

    let g:vimade_defaults.enablefocusfading = 0
   
    ""@setting vimade.normalid
    "Supported:     lua, python, python-legacy
    "If not specified, the normalid is determined when vimade is first loaded.  normalid provides the id of the "Normal" highlight which is used to calculate fading.  You can override this config with another highlight group.
    "You shouldn't really ever need to modify this.

    let g:vimade_defaults.normalid = ''

    ""@setting vimade.normalncid
    "Supported:     lua, python, python-legacy
    "If not specified, the normalncid is determined when vimade is first loaded.  normalncid provides the id of the "NormalNC" highlight which is used to calculate fading for inactive buffers in NVIM.  You can override this config with another highlight group.
    "You shouldn't really ever need to modify this.

    let g:vimade_defaults.normalncid = ''

    ""@setting vimade.checkinterval
    "Supported:     lua, python, python-legacy
    "The amount of time in milliseconds that vimade should check the screen for changes.  This config is mainly used to detect resize and scroll changes that occur on inactive windows. Checkinterval does nothing on gvim, if you want to control the refresh time, see 'h updatetime'. Default is 100 for gui vim and 500 for neovim/terminal.  

    let g:vimade_defaults.checkinterval = g:vimade_features.has_gui_running && !(g:vimade_features.has_nvim) ? 100 : 500

    ""@setting vimade.usecursorhold
    "Supported:     lua, python, python-legacy
    "Disables the timer running in the background and instead relies `OnCursorHold` and `updatetime` (see h:updatetime).  The default value is `0` except on Windows GVIM, which defaults to `1` due to the timer breaking movements.  If you find that the timer is causing performance problems or other issues you can disable it by setting this option to `1`. 

    let g:vimade_defaults.usecursorhold = g:vimade_features.has_gui_running && !g:vimade_features.has_nvim && g:vimade_features.has_gui_version

    ""@setting vimade.basegroups
    "Supported:     python, python-legacy
    "lua uses namespaces and doesn't require this setting.
    "Neovim only setting that specifies the basegroups/built-in highlight groups that will be faded using winhl when switching windows

    let g:vimade_defaults.basegroups = ['Folded', 'Search', 'SignColumn', 'CursorLine', 'CursorLineNr', 'DiffAdd', 'DiffChange', 'DiffDelete', 'DiffText', 'FoldColumn', 'Whitespace', 'NonText', 'SpecialKey', 'Conceal', 'EndOfBuffer', 'WinSeparator', 'LineNr', 'LineNrAbove', 'LineNrBelow']

    ""@setting vimade.enablebasegroups
    "Supported:     python, python-legacy
    "lua uses namespaces and doesn't require this setting.
    "Neovim only setting.  Enabled by default and allows basegroups/built-in highlight fading using winhl.  This allows fading of built-in highlights such as Folded, Search, etc.

    let g:vimade_defaults.enablebasegroups = 1


    ""@setting vimade.enabletreesitter
    "Supported:     python, python-legacy
    "lua uses namespaces and doesn't require this setting.
    "Neovim only setting.  Disabled by default and hooks vimade into the internals of treesitter.

    let g:vimade_defaults.enabletreesitter = 0

    ""@setting vimade.enablesigns
    "Supported:     python, python-legacy
    "lua renderer doesn't require additional logic to fade signs.
    "Enabled by default for vim/nvim versions that support sign priority and causes signs to be faded when switching buffers.
    "Only visible signs are faded. This feature can cause performance issues
    "on older nvim/vim versions that don't support sign priority. 
    "Use signsretentionperiod to control the duration that vimade checks for sign updates after switching buffers.

    let g:vimade_defaults.enablesigns = g:vimade_features.has_sign_priority

    ""@setting vimade.signsid
    "Supported:     python, python-legacy
    "lua renderer doesn't require additional logic to fade signs.
    "The starting id that Vimade should use when creating new signs. By
    "default Vim requires numeric values to create signs and its possible that
    "collisions may occur between plugins.  If you need to override this value for
    "compatibility, please open an issue as well.  Default is 13100.

    let g:vimade_defaults.signsid = 13100

    ""@setting vimade.signsretentionperiod
    "Supported:     python, python-legacy
    "lua renderer doesn't require additional logic to fade signs.
    " *python & python-legacy only*: Serves no purpose on lua renderer.
    "Amount of time in milliseconds that faded buffers should be tracked for sign changes.  Default value is 4000.

    let g:vimade_defaults.signsretentionperiod = 4000

    ""@setting vimade.signspriority
    "Supported:     python, python-legacy
    "lua renderer doesn't require additional logic to fade signs.
    "Controls the signs fade priority.
    "You may need to change this value if you find that not all signs are fading properly.
    "Please also open a defect if you need to tweak this value as Vimade strives to minimize manual configuration where possible.
    "Default is 31.

    let g:vimade_defaults.signspriority = 31

    ""@setting vimade.fademinimap
    "Supported:     lua, python, python-legacy
    "Enables fading for `severin-lemaignan/vim-minimap`. Setting vimade.fademinimap to
    "0 disables the special fade.  Default is 1.

    let g:vimade_defaults.fademinimap = 1

    ""@setting vimade.fadepriority
    "Supported:     python, python-legacy
    "lua uses namespaces and doesn't require priority settings
    "Controls the highlighting priority.
    "You may want to tweak this value to make Vimade play nicely with other highlighting plugins and behaviors.
    "For example, if you want hlsearch to show results on all buffers, you may want to lower this value to 0.
    "Default is 10.

    let g:vimade_defaults.fadepriority = 10

    ""@setting vimade.disablebatch
    "Supported:     python
    "Disables interprocess batching. Useful if you are seeing issues and need to debug an error.

    let g:vimade_defaults.disablebatch = 0

    " ----------------------------------------------

    " legacy only settings

    ""@setting vimade.basefg
    "Supported:     python-legacy
    "lua and python renderers should use the *tint* config for better customization
    "basefg can either be six digit hexidecimal color, rgb array [0-255,0-255,0-255], or cterm code (in terminal).  Basefg is only used to calculate the default fading that should be applied to Normal text.  By default basefg is calculated as the "Normal" highlight guifg or ctermfg.

    let g:vimade_defaults.basefg = ''

    ""@setting vimade.colbufsize
    "Supported:     python-legacy
    "lua and python renderers don't need to support this option.
    "The number of cols left and right of the determined scroll area that should be precalculated. Reduce this value to improve performance. Default is 15 for gui vim and 5 for terminals/gvim.
   
    let g:vimade_defaults.colbufsize = g:vimade_features.has_gui_running && !(g:vimade_features.has_gui_version) ? 15 : 5

    ""@setting vimade.rowbufsize
    "Supported:     python-legacy
    "lua and python renderers don't need to support this option.
    "The number of rows above and below of the determined scroll area that should be precalculated. Reduce this value to improve performance Default is 15 for gui vim and 0 for terminals/gvim.

    let g:vimade_defaults.rowbufsize = g:vimade_features.has_gui_running && !(g:vimade_features.has_gui_version) ? 15 : 0

    ""@setting vimade.detecttermcolors
    "Supported:     python-legacy
    "lua and python renderers don't need to support this option.
    "Detect the terminal background and foreground colors.  This will work for Vim8 + iTerm, Tilix, Kitty, Gnome, Rxvt, and other editors that support the following query (```\033]11;?\007``` or ```\033]11;?\033\\```).  Default is 0.  This feature can cause unwanted side effects during startup and should be enabled at your own risk

    let g:vimade_defaults.detecttermcolors = 0

    ""@setting vimade.enablescroll
    "Supported:     python-legacy
    "lua and python renderers don't need to support this option.
    "Enables fading while scrolling inactive windows.  This is only useful in gui vim and does have a performance cost.  By default this setting is enabled in gui vim and disabled for terminals.

    let g:vimade_defaults.enablescroll = ((g:vimade_features.has_gui_running || g:vimade_features.has_vimr) && !(g:vimade_features.has_gui_version))


    let g:vimade_defaults_keys = keys(g:vimade_defaults)
    if exists('g:vimade_detect_term_colors')
      let g:vimade.detecttermcolors = g:vimade_detect_term_colors
    endif

    if exists('g:vimade_usecursorhold')
      let g:vimade.usecursorhold = g:vimade_usecursorhold
    endif
  endif
  return g:vimade_defaults
endfunction

function! vimade#Enable()
  "enable vimade
  let g:vimade_running = 1
  if !exists('g:vimade_init')
    call vimade#Init()
  endif
  call vimade#DeferredCheckWindows()
  call vimade#StartTimer()
endfunction

function! vimade#WinEnable()
  if exists('w:vimade_disabled')
    unlet w:vimade_disabled
    call vimade#DeferredCheckWindows()
  endif
endfunction

function! vimade#WinDisable()
  let w:vimade_disabled=1
  call vimade#DeferredCheckWindows()
endfunction

function! vimade#BufEnable()
  if exists('b:vimade_disabled')
    unlet b:vimade_disabled
    call vimade#DeferredCheckWindows()
  endif
endfunction

function! vimade#BufDisable()
  let b:vimade_disabled=1
  call vimade#DeferredCheckWindows()
endfunction

function! vimade#Disable()
  if winnr() == 0
    return
  endif
  "disable vimade
  let g:vimade_running = 0
  call vimade#StopTimer()
  call g:vimade_active_renderer.unfadeAll()
endfunction

function! vimade#UnfadeAll()
  if winnr() == 0
    return
  endif
  call g:vimade_active_renderer.unfadeAll()
endfunction

function! vimade#DetectTermColors()
  call g:vimade_active_renderer.detectTermColors()
endfunction

function! vimade#Toggle()
  "toggle enabled state
  if g:vimade_running
    call vimade#Disable()
  else
    call vimade#Enable()
  endif
endfunction

function! vimade#OverrideFolded()
  hi! clear Folded
  hi! link Folded vimade_0
endfunction

function! vimade#OverrideSignColumn()
  hi! clear SignColumn
  hi! link SignColumn vimade_0
endfunction

function! vimade#OverrideLineNr()
  hi! clear LineNr
  hi! link LineNr vimade_0
endfunction

function! vimade#OverrideVertSplit()
  hi! clear VertSplit
  hi! link VertSplit vimade_0
endfunction

function! vimade#OverrideEndOfBuffer()
  hi! clear EndOfBuffer
  hi! link EndOfBuffer vimade_0
endfunction

function! vimade#OverrideNonText()
  hi! clear NonText
  hi! link NonText vimade_0
endfunction

function! vimade#OverrideAll()
  call vimade#OverrideFolded()
  call vimade#OverrideSignColumn()
  call vimade#OverrideLineNr()
  call vimade#OverrideVertSplit()
  call vimade#OverrideNonText()
  call vimade#OverrideEndOfBuffer()
endfunction

function! vimade#Pause()
  let g:vimade_paused=1
endfunction

function! vimade#Unpause()
  let g:vimade_paused=0
endfunction

function! vimade#FocusGained()
  call vimade#UpdateState()
  call vimade#Unpause()
  call vimade#InvalidateSigns()
  if g:vimade.enablefocusfading
    call vimade#UnfadeActive()
  endif
endfunction

function! vimade#FocusLost()
  if g:vimade.enablefocusfading
    call vimade#FadeActive()
  endif
  call vimade#Pause()
endfunction

function! vimade#InvalidateSigns()
  "prevent if inside popup window
  if winnr() == 0
    return
  endif
  if g:vimade_running && g:vimade_paused == 0
    call g:vimade_active_renderer.softInvalidateSigns()
    call vimade#DeferredCheckWindows()
  endif
endfunction

function! vimade#Recalculate()
  if g:vimade_running && g:vimade_paused == 0
    call g:vimade_active_renderer.recalculate()
  endif
endfunction

function! vimade#Redraw()
  "prevent if inside popup window
  if winnr() == 0
    return
  endif
  if g:vimade_running && g:vimade_paused == 0
    call g:vimade_active_renderer.redraw()
  endif
endfunction

function! vimade#GetSigns (bufnr, rows)
  let signs = get(getbufinfo(a:bufnr)[0],'signs',[])
  let result = []
  let g:rows = a:rows
  for sign in signs
    if has_key(a:rows, sign['lnum'])
      call add(result, sign)
    endif
  endfor
  return result
endfunction

function! vimade#GetInfo()
  "get debug info
  call g:vimade_active_renderer.getInfo()
  return {
      \ 'version': '0.1.0',
      \ 'config': g:vimade,
      \ 'renderer': g:vimade_renderer_info,
      \ 'features': g:vimade_features, 
      \ 'other': {
        \ 'normal_id': g:vimade.normalid,
        \ 'normal_hi': vimade#GetHi(g:vimade.normalid),
        \ 'syntax': &syntax,
        \ 'colorscheme': execute(':colorscheme'),
        \ 'background': &background,
        \ 'vimade_py_cmd': (exists('g:vimade_py_cmd') ? g:vimade_py_cmd: 0),
        \ 'vimade_running': g:vimade_running,
        \ 'vimade_paused': g:vimade_paused,
        \ 'vimade_error_count': g:vimade_error_count,
        \ 'vimade_timer': exists('g:vimade_timer') ? g:vimade_timer : -1,
        \ 'vimade_loaded': g:vimade_loaded,
        \ 't_Co': &t_Co,
      \ }
  \ }
endfunction

function! vimade#FadeLevel(level)
  let g:vimade.fadelevel = a:level
  call vimade#DeferredCheckWindows()
endfunction

function! vimade#FadePriority(priority)
  let g:vimade.fadepriority = a:priority
  call vimade#DeferredCheckWindows()
endfunction

function! vimade#DeferredCheckWindows()
  if g:vimade_features.has_timer_start
    if exists('g:vimade_deferred_timer') || exists('g:vimade_animation_running')
      return
    endif
    let g:vimade_deferred_timer = timer_start(0, 'vimade#DeferredTick')
  else
    return vimade#CheckWindows()
  endif
endfunction

function! vimade#DeferredTick(num)
  unlet g:vimade_deferred_timer
  call vimade#Tick(0)
endfunction

function! vimade#CheckWindows()
  call vimade#UpdateState()
  "prevent if inside popup window
  " TODO: confirm if this is needed in newer renderers, which perform
  " significantly better
  if winnr() == 0 || pumvisible() 
    return
  endif
  if g:vimade_running && g:vimade_paused == 0 && getcmdwintype() == ''
    call g:vimade_active_renderer.update()
  endif
endfunction

function! vimade#StartAnimationTimer()
  if g:vimade_features.has_timer_start
    let g:vimade_animation_running = 1
    if !exists('g:vimade_animation_timer')
      let g:vimade_animation_timer = timer_start(16, 'vimade#DoAnimations', {'repeat': -1})
    else
      call timer_pause(g:vimade_animation_timer, 0)
    endif
  endif
endfunction

function! vimade#DoAnimations(val)
  unlet g:vimade_animation_running
  call timer_pause(g:vimade_animation_timer, 1)
  if g:vimade_running && g:vimade_paused == 0 && getcmdwintype() == ''
    call g:vimade_active_renderer.animate()
  endif
endfunction

function! vimade#softInvalidateBuffer(bufnr)
  "prevent if inside popup window
  if winnr() == 0
    return
  endif
  "Don't check paused condition because the application may have not been regained and triggered FocusGained event
  if g:vimade_running
    call g:vimade_active_renderer.softInvalidateBuffer()
  endif
  call vimade#DeferredCheckWindows()
endfunction

function! vimade#UpdateEvents()
  augroup vimade
      au!
      au VimLeave * call vimade#Disable()
      au FocusGained * call vimade#FocusGained()
      au FocusLost * call vimade#FocusLost()
      " TODO neovim is broken in many scenarios in v0.10. Python logic is not
      " executed properly when called directly off and autoevent. This is
      " easily reproduceable when using netrw...
      " Using async here should work fine even in legacy.
      au WinEnter,BufEnter * call vimade#DeferredCheckWindows()
      au OptionSet diff call vimade#DeferredCheckWindows()
      au ColorScheme * call vimade#Redraw()
      au FileChangedShellPost * call vimade#softInvalidateBuffer(expand("<abuf>"))
      if g:vimade.usecursorhold
        au CursorHold,CursorHoldI * call vimade#DeferredCheckWindows()
        au VimResized * call vimade#DeferredCheckWindows()
      endif
  augroup END
endfunction

function! vimade#ExtendState()
  for prop in g:vimade_defaults_keys
    if !has_key(g:vimade, prop)
      let g:vimade[prop] = g:vimade_defaults[prop]
    endif
  endfor
endfunction

function! vimade#UpdateState()
  if !exists('g:vimade')
    let g:vimade = {}
  endif
  if !has_key(g:vimade, '$extended')
    call vimade#ExtendState()
  endif
  if g:vimade.normalid == "" || g:vimade.normalid == 0
    let g:vimade.normalid = hlID('Normal')
  endif
  if g:vimade_features.has_nvim && (g:vimade.normalncid == "" || g:vimade.normalncid == 0)
    let g:vimade.normalncid = hlID('NormalNC')
  endif
  if g:vimade.usecursorhold != g:vimade_last.usecursorhold
    let g:vimade_last.usecursorhold = g:vimade.usecursorhold
    if g:vimade.usecursorhold
      call vimade#StopTimer()
    else
      call vimade#StartTimer()
    endif
    call vimade#UpdateEvents()
  endif
  if g:vimade.checkinterval != g:vimade_last.checkinterval
    let g:vimade_last.checkinterval = g:vimade.checkinterval
    call vimade#StopTimer()
    call vimade#StartTimer()
  endif
  if g:vimade.detecttermcolors != g:vimade.detecttermcolors
    let g:vimade_last.detecttermcolors = g:vimade.detecttermcolors
    if g:vimade.detecttermcolors
      call vimade#DetectTermColors()
    endif
  endif
  let g:vimade.__background = &background
  let g:vimade.__colorscheme = exists('g:colors_name') ? g:colors_name : ""
  let g:vimade.__termguicolors = &termguicolors
  call vimade#SetupRenderer()
endfunction

function! vimade#Tick(num)
  try
    call vimade#CheckWindows()
  catch
    let g:vimade_error_count += 1
    if g:vimade_error_count >= 3
      let g:vimade_error_count = 0
      try
        VimadeDisable
      catch
        let g:vimade_running = 0
      endtry
    endif
    throw 'Vimade Error='.g:vimade_error_count . '\n' . v:exception
  endtry
endfunction

function! vimade#FadeActive()
  "immediately fade current buffer
  let g:vimade_fade_active=1
  call vimade#DeferredCheckWindows()
endfunction

function! vimade#UnfadeActive()
  let g:vimade_fade_active=0
  call vimade#DeferredCheckWindows()
endfunction

function! vimade#GetNvimHi(id)
  let tid = synIDtrans(a:id)
  if tid > 0
    let norgb = nvim_get_hl_by_id(tid, 0)
    let rgb = nvim_get_hl_by_id(tid, 1)
    return [get(norgb, 'foreground', -1), get(norgb, 'background', -1), get(rgb, 'foreground', -1), get(rgb, 'background', -1), get(rgb, 'special', -1)]
  endif
  return [-1,-1,-1,-1,-1]
endfunction

function! vimade#GetHi(id)
  "resolve root linkedTo id
  let tid = synIDtrans(a:id)
  return [synIDattr(tid, 'fg#'), synIDattr(tid, 'bg#'), synIDattr(tid, 'sp#')]
endfunction

function! vimade#GetVisibleRows(startRow, endRow)
  let l:row = a:startRow
  let l:result = []
  let l:rows = 0
  let l:target_rows = a:endRow - a:startRow
  while l:rows <= l:target_rows
    let l:fold = foldclosedend(l:row)
    call add(l:result, [l:row, l:fold])
    if l:fold == -1
      let l:row += 1
    else
      let l:row = l:fold + 1
    endif
    let l:rows += 1
  endwhile
  return l:result
endfunction

function! vimade#StartTimer()
  "timer is disabled when usecursorhold=1
  if !g:vimade.usecursorhold && !exists('g:vimade_timer') && g:vimade_running
    let g:vimade_timer = timer_start(g:vimade.checkinterval, 'vimade#Tick', {'repeat': -1})
  endif
endfunction
function! vimade#StopTimer()
  if exists('g:vimade_timer')
    call timer_stop(g:vimade_timer)
    unlet g:vimade_timer
  endif
endfunction

function! vimade#Init()
  let l:already_running = 0
  if exists('g:vimade_init')
    let l:already_running = 1
  endif
  let g:vimade_init = 1
  call vimade#CreateGlobals()
  call vimade#GetFeatures()
  call vimade#GetDefaults()
  call vimade#ExtendState()
  call vimade#UpdateEvents()

  let g:vimade_last = extend({}, g:vimade)

  if g:vimade.detecttermcolors
    call vimade#DetectTermColors()
  endif

  "check immediately
  if l:already_running == 0
    call vimade#DeferredCheckWindows()
  else
    call vimade#Redraw()
  endif
  call vimade#StartTimer()

  "run the timer once during startup
  "we use try here to possibly support vim 7
  if g:vimade.usecursorhold
    try
      call timer_start(g:vimade.checkinterval, 'vimade#Tick')
    catch
    endtry
  endif
endfunction

" Variables
let g:vimade_eval_ret = []
let g:vimade_active_renderer = 0
let g:vimade_python_setup = 0

"Empty Renderer START
let s:empty_renderer = {
    \ 'name': 'empty',
    \ 'detectTermColors': function('vimade#Empty'),
    \ 'getInfo': function('vimade#Empty'),
    \ 'recalculate': function('vimade#Empty'),
    \ 'redraw': function('vimade#Empty'),
    \ 'unfadeAll': function('vimade#Empty'),
    \ 'update': function('vimade#Empty'),
    \ 'softInvalidateBuffer': function('vimade#Empty'),
    \ 'softInvalidateSigns': function('vimade#Empty'),
    \ }
"Empty Renderer END
"
let g:vimade_active_renderer = s:empty_renderer 


" Lua Renderer START
function! s:DetectTermColors_Lua()
  " empty
endfunction
function! s:Recalculate_Lua()
  lua require('vimade').redraw()
endfunction
function! s:Redraw_Lua()
  lua require('vimade').redraw()
endfunction
function! s:UnfadeAll_Lua()
  lua require('vimade').unfadeAll()
endfunction
function! s:Update_Lua()
  lua require('vimade').update()
endfunction
function! s:Animate_Lua()
  lua require('vimade').animate()
endfunction
function! s:SoftInvalidateBuffer_Lua()
  lua require('vimade').softInvalidateBuffer()
endfunction
function! s:SoftInvalidateSigns_Lua()
  " empty
endfunction
function! s:GetInfo_Lua()
  lua vim.g.vimade_renderer_info = require('vimade').getInfo()
endfunction
let s:lua_renderer = {
  \ 'name': 'lua',
  \ 'animate': function('s:Animate_Lua'),
  \ 'detectTermColors': function('s:DetectTermColors_Lua'),
  \ 'getInfo': function('s:GetInfo_Lua'),
  \ 'recalculate': function('s:Recalculate_Lua'),
  \ 'redraw': function('s:Redraw_Lua'),
  \ 'unfadeAll': function('s:UnfadeAll_Lua'),
  \ 'update': function('s:Update_Lua'),
  \ 'softInvalidateBuffer': function('s:SoftInvalidateBuffer_Lua'),
  \ 'softInvalidateSigns': function('s:SoftInvalidateSigns_Lua'),
  \ }
" Lua Renderer END

" Python Renderer START
function! s:DetectTermColors_Python()
  " empty
endfunction
function! s:GetInfo_Python()
  exec g:vimade_py_cmd "from vimade.v2 import bridge; import vim; vim.vars['vimade_renderer_info'] = bridge.getInfo()"
endfunction
function! s:Recalculate_Python()
  exec g:vimade_py_cmd "from vimade.v2 import bridge; bridge.recalculate()"
endfunction
function! s:Redraw_Python()
  exec g:vimade_py_cmd "from vimade.v2 import bridge; bridge.unfadeAll(); bridge.recalculate()"
  call vimade#CheckWindows()
endfunction
function! s:UnfadeAll_Python()
  exec g:vimade_py_cmd "from vimade.v2 import bridge; bridge.unfadeAll()"
endfunction
function! s:Update_Python()
  exec g:vimade_py_cmd "from vimade.v2 import bridge; bridge.update()"
endfunction
function! s:Animate_Python()
  exec g:vimade_py_cmd "from vimade.v2 import bridge; bridge.animate()"
endfunction
function! s:SoftInvalidateBuffer_Python()
  exec g:vimade_py_cmd "from vimade.v2 import bridge; bridge.invalidate()"
endfunction
function! s:SoftInvalidateSigns_Python()
  exec g:vimade_py_cmd "from vimade.v2 import bridge; bridge.invalidate()"
endfunction
let s:python_renderer = {
  \ 'name': 'python',
  \ 'animate': function('s:Animate_Python'),
  \ 'detectTermColors': function('s:DetectTermColors_Python'),
  \ 'getInfo': function('s:GetInfo_Python'),
  \ 'recalculate': function('s:Recalculate_Python'),
  \ 'redraw': function('s:Redraw_Python'),
  \ 'unfadeAll': function('s:UnfadeAll_Python'),
  \ 'update': function('s:Update_Python'),
  \ 'softInvalidateBuffer': function('s:SoftInvalidateBuffer_Python'),
  \ 'softInvalidateSigns': function('s:SoftInvalidateSigns_Python'),
  \ }
" Python Renderer END

" PythonLegacy Renderer START
function! s:DetectTermColors_PythonLegacy()
  exec g:vimade_py_cmd "from vimade import bridge; bridge.detectTermColors()"
endfunction
function! s:GetInfo_PythonLegacy()
  exec g:vimade_py_cmd "from vimade import bridge; import vim; vim.vars['vimade_renderer_info'] = bridge.getInfo()"
endfunction
function! s:Recalculate_PythonLegacy()
  exec g:vimade_py_cmd "from vimade import bridge; bridge.recalculate()"
endfunction
function! s:Redraw_PythonLegacy()
  exec g:vimade_py_cmd "from vimade import bridge; bridge.unfadeAll(); bridge.recalculate()"
  call vimade#CheckWindows()
endfunction
function! s:UnfadeAll_PythonLegacy()
  exec g:vimade_py_cmd "from vimade import bridge; bridge.unfadeAll()"
endfunction
function! s:Update_PythonLegacy()
  exec g:vimade_py_cmd "from vimade import bridge; bridge.update({'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."'})"
endfunction
function! s:SoftInvalidateBuffer_PythonLegacy()
  exec g:vimade_py_cmd "from vimade import bridge; bridge.softInvalidateBuffer('".a:bufnr."')"
endfunction
function! s:SoftInvalidateSigns_PythonLegacy()
  exec g:vimade_py_cmd "from vimade import bridge; bridge.softInvalidateSigns()"
endfunction
let s:python_legacy_renderer = {
  \ 'name': 'python_legacy',
  \ 'animate': function('vimade#Empty'),
  \ 'detectTermColors': function('s:DetectTermColors_PythonLegacy'),
  \ 'getInfo': function('s:GetInfo_PythonLegacy'),
  \ 'recalculate': function('s:Recalculate_PythonLegacy'),
  \ 'redraw': function('s:Redraw_PythonLegacy'),
  \ 'unfadeAll': function('s:UnfadeAll_PythonLegacy'),
  \ 'update': function('s:Update_PythonLegacy'),
  \ 'softInvalidateBuffer': function('s:SoftInvalidateBuffer_PythonLegacy'),
  \ 'softInvalidateSigns': function('s:SoftInvalidateSigns_PythonLegacy'),
  \ }
" PythonLegacy Renderer END


call vimade#Init()

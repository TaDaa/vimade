if exists('g:vimade_loaded')
  finish
endif
if !exists('g:vimade_running')
  let g:vimade_running = 1
endif
let g:vimade_loaded = 1
if !exists('g:vimade_usecursorhold')
  let g:vimade_usecursorhold = has('gui_running') && !has('nvim') && execute('version')=~"GUI version"
endif
if !exists('g:vimade_detect_term_colors')
  let g:vimade_detect_term_colors = 1
endif

let defaults = {
  \ "normalid": '',
  \ "basefg": '',
  \ "basebg": '',
  \ "fadelevel": 0.4,
  \ "colbufsize": 30,
  \ "rowbufsize": 30,
  \ "checkinterval": 32,
\ }
if exists('g:vimade')
  let g:vimade = extend(defaults, g:vimade)
else
  let g:vimade = defaults
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

let g:vimade_plugin_current_directory = resolve(expand('<sfile>:p:h').'/../lib')
exec g:vimade_py_cmd  join([
    \ "import vim",
    \ "sys.path.append(vim.eval('g:vimade_plugin_current_directory'))",
\ ], "\n")


command! VimadeEnable call vimade#Enable()
command! VimadeDisable call vimade#Disable()
command! VimadeToggle call vimade#Toggle()
command! VimadeInfo echo json_encode(vimade#GetInfo())
command! VimadeRedraw call vimade#Redraw()

if v:vim_did_enter
  call vimade#Init()
endif

augroup vimade 
    au!
    au VimEnter * call vimade#Init()
    au VimLeave * call vimade#Disable()
    au BufLeave * call vimade#FadeCurrentBuffer()
    au BufEnter * call vimade#UnfadeCurrentBuffer()
    au OptionSet diff call vimade#DiffToggled()
    if g:vimade_usecursorhold
      au CursorHold * call vimade#CheckWindows(0)
      au VimResized * call vimade#CheckWindows(0)
    endif
augroup END

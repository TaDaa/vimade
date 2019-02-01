if exists('g:vimade_loaded')
  finish
endif
if !exists('g:vimade_running')
  let g:vimade_running = 1
endif
let g:vimade_loaded = 1
let g:vimade_error_count = 0

let g:vimade_defaults = {
  \ "normalid": '',
  \ "basefg": '',
  \ "basebg": '',
  \ "fadelevel": 0.4,
  \ "colbufsize": 15,
  \ "rowbufsize": 15,
  \ "checkinterval": 100,
  \ 'usecursorhold': has('gui_running') && !has('nvim') && execute('version')=~"GUI version",
  \ 'detecttermcolors': 1,
  \ '$extended': 1,
\ }
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


command! VimadeEnable call vimade#Enable()
command! VimadeDisable call vimade#Disable()
command! VimadeToggle call vimade#Toggle()
command! VimadeInfo echo json_encode(vimade#GetInfo())
command! VimadeRedraw call vimade#Redraw()
command! -nargs=1 VimadeFadeLevel call vimade#FadeLevel(<q-args>)

if v:vim_did_enter
  call vimade#Init()
endif

call vimade#UpdateEvents()

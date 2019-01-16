if exists('g:vimade_loaded')
  finish
endif
if !exists('g:vimade_running')
  let g:vimade_running = 1
endif
let g:vimade_loaded = 1
let g:vimade_gvim = has('gui_running') && !has('nvim') && execute('version')=~"GUI version"

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

if g:vimade.normalid == "" || g:vimade.normalid == 0
  let i = 0
  while i < 400
      if synIDattr(i, 'name') == 'Normal'
          let g:vimade.normalid = i
          break
      endif
      let i += 1
  endwhile
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

augroup vimade 
    au!
    au VimEnter * call vimade#Init()
    au BufLeave * call vimade#FadeCurrentBuffer()
    au BufEnter * call vimade#UnfadeCurrentBuffer()
    au OptionSet diff call vimade#DiffToggled()
    if g:vimade_gvim
      au CursorHold * call vimade#CheckWindows(0)
      au VimResized * call vimade#CheckWindows(0)
    endif
augroup END

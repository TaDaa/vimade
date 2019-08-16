
function! vimade#Enable()
  "enable vimade
  let g:vimade_running = 1
  call vimade#CheckWindows()
  call vimade#StartTimer()
endfunction

function! vimade#WinEnable()
  unlet w:vimade_disabled
  call vimade#CheckWindows()
endfunction

function! vimade#WinDisable()
  let w:vimade_disabled=1
  call vimade#CheckWindows()
endfunction

function! vimade#BufEnable()
  unlet b:vimade_disabled
  call vimade#CheckWindows()
endfunction

function! vimade#BufDisable()
  let b:vimade_disabled=1
  call vimade#CheckWindows()
endfunction

function! vimade#Disable()
  "disable vimade
  let g:vimade_running = 0
  call vimade#StopTimer()

  if exists('g:vimade_py_cmd')
    exec g:vimade_py_cmd join([
        \ "from vimade import bridge",
        \ "bridge.unfadeAll()",
    \ ], "\n")
  endif
endfunction

function! vimade#DetectTermColors()
  exec g:vimade_py_cmd join([
      \ "from vimade import bridge",
      \ "bridge.detectTermColors()",
  \ ], "\n")
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
  hi! link Folded vimade_0
endfunction

function! vimade#FocusGained()
  let g:vimade_paused=0
  call vimade#InvalidateSigns()
  if g:vimade.enablefocusfading
    call vimade#UnfadeActive()
  endif
endfunction
function! vimade#FocusLost()
  if g:vimade.enablefocusfading
    call vimade#FadeActive()
  endif
  let g:vimade_paused=1
endfunction
function! vimade#InvalidateSigns()
  if g:vimade_running && g:vimade_paused == 0
    exec g:vimade_py_cmd join([
        \ "from vimade import bridge",
        \ "bridge.softInvalidateSigns()",
    \ ], "\n")

    call vimade#CheckWindows()
  endif
endfunction

function! vimade#Recalculate()
  if g:vimade_running && g:vimade_paused == 0
    exec g:vimade_py_cmd join([
        \ "from vimade import bridge",
        \ "bridge.recalculate()",
    \ ], "\n")
  endif
endfunction

function! vimade#Redraw()
  if g:vimade_running && g:vimade_paused == 0
    exec g:vimade_py_cmd join([
        \ "from vimade import bridge",
        \ "bridge.unfadeAll()",
        \ "bridge.recalculate()",
    \ ], "\n")
    call vimade#CheckWindows()
  endif
endfunction


function! vimade#GetInfo()
  "get debug info
  exec g:vimade_py_cmd join([
      \ "from vimade import bridge",
      \ "import vim",
      \ "vim.vars['vimade_python_info'] = bridge.getInfo()",
  \ ], "\n")
  return {
      \ 'version': '0.0.5',
      \ 'config': g:vimade,
      \ 'python': g:vimade_python_info,
      \ 'other': {
        \ 'normal_id': g:vimade.normalid,
        \ 'normal_hi': vimade#GetHi(g:vimade.normalid),
        \ 'syntax': &syntax,
        \ 'colorscheme': execute(':colorscheme'),
        \ 'background': &background,
        \ 'has_python': has('python'),
        \ 'has_python3': has('python3'),
        \ 'has_gui': has('gui'),
        \ 'has_nvim': g:vimade_is_nvim,
        \ 'has_gui_running': has('gui_running'),
        \ 'vimade_py_cmd': g:vimade_py_cmd,
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
  call vimade#CheckWindows()
endfunction

function! vimade#CheckWindows()
  call vimade#UpdateState()
  if g:vimade_running && g:vimade_paused == 0
    exec g:vimade_py_cmd join([
        \ "from vimade import bridge",
        \ "bridge.update({'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."'})",
    \ ], "\n")
  endif
endfunction

function! vimade#softInvalidateBuffer(bufnr)
  "Don't check paused condition because the application may have not been regained and triggered FocusGained event
  if g:vimade_running
    exec g:vimade_py_cmd join([
        \ "from vimade import bridge",
        \ "bridge.softInvalidateBuffer('".a:bufnr."')",
    \ ], "\n")
  endif
  call vimade#CheckWindows()
endfunction

function! vimade#UpdateEvents()
  augroup vimade
      au!
      au VimEnter * call vimade#Init()
      au VimLeave * call vimade#Disable()
      au FocusGained * call vimade#FocusGained()
      au FocusLost * call vimade#FocusLost()
      au BufEnter * call vimade#CheckWindows()
      au OptionSet diff call vimade#CheckWindows()
      au ColorScheme * call vimade#CheckWindows()
      au FileChangedShellPost * call vimade#softInvalidateBuffer(expand("<abuf>"))
      if g:vimade.usecursorhold
        au CursorHold * call vimade#Tick(0)
        au VimResized * call vimade#Tick(0)
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
  if g:vimade.normalid == "" || g:vimade.normalid == 0
    let g:vimade.normalid = hlID('Normal')
  endif
  if g:vimade_is_nvim && (g:vimade.normalncid == "" || g:vimade.normalncid == 0)
    let g:vimade.normalncid = hlID('NormalNC')
  endif
  if !has_key(g:vimade, '$extended')
    call vimade#ExtendState()
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
    call vimade#CheckWindows()
endfunction

function! vimade#UnfadeActive()
    let g:vimade_fade_active=0
    call vimade#CheckWindows()
endfunction

function! vimade#GetHi(id)
  "resolve root linkedTo id
  let tid = synIDtrans(a:id)
  return [synIDattr(tid, 'fg#'), synIDattr(tid, 'bg#')]
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

  if g:vimade.detecttermcolors
    call vimade#DetectTermColors()
  endif

  "check immediately
  call vimade#CheckWindows()
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

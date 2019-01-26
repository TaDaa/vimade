function! vimade#Enable()
  "enable vimade
  let g:vimade_running = 1
  call vimade#CheckWindows()
  call vimade#ScheduleTick()
endfunction
function! vimade#Disable()
  "disable vimade
  let g:vimade_running = 0
  if exists('g:vimade_timer')
    call timer_stop(g:vimade_timer)
    unlet g:vimade_timer
  endif
  exec g:vimade_py_cmd join([
      \ "import vimade",
      \ "vimade.unfadeAll()",
  \ ], "\n")
endfunction
function! vimade#DetectTermColors()
  exec g:vimade_py_cmd join([
      \ "import vimade",
      \ "vimade.detectTermColors()",
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
function! vimade#Redraw()
  if g:vimade_running
    let tmp = g:vimade.fadelevel
    let g:vimade.fadelevel = 0
    call vimade#CheckWindows()
    let g:vimade.fadelevel = l:tmp 
    call vimade#CheckWindows()
  endif
endfunction

function! vimade#GetInfo()
  "get debug info
  exec g:vimade_py_cmd join([
      \ "import vimade",
      \ "import vim",
      \ "vim.vars['vimade_python_info'] = vimade.getInfo()",
  \ ], "\n")
  return {
      \ 'version': '0.0.1', 
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
        \ 'has_nvim': has('nvim'),
        \ 'has_gui_running': has('gui_running'),
        \ 'vimade_py_cmd': g:vimade_py_cmd,
        \ 'vimade_running': g:vimade_running,
        \ 'vimade_timer': g:vimade_timer,
        \ 'vimade_usecursorhold': g:vimade_usecursorhold,
        \ 'vimade_loaded': g:vimade_loaded,
        \ 't_Co': &t_Co,
      \ }
  \ }
endfunction

function! vimade#CheckWindows()
  if g:vimade_running
    exec g:vimade_py_cmd join([
        \ "import vimade",
        \ "vimade.updateState({'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."'})",
    \ ], "\n")
  endif
endfunction

function! vimade#Tick(num)
  if exists('g:vimade_timer')
    unlet g:vimade_timer
  endif
  call vimade#CheckWindows()
  call vimade#ScheduleTick()
endfunction

function! vimade#FadeCurrentBuffer()
    "immediately fade current buffer
    if g:vimade_running
      exec g:vimade_py_cmd join([
          \ "import vimade",
          \ "vimade.updateState({'activeBuffer': -1, 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."'})",
      \ ], "\n")
    endif
endfunction

function! vimade#UnfadeCurrentBuffer()
    "immediately unfade current buffer
    if g:vimade_running
      exec g:vimade_py_cmd join([
          \ "import vimade,vim",
          \ "vimade.updateState({'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."'})",
      \ ], "\n")
    endif
endfunction

function! vimade#DiffToggled()
    "let python vimade know that diff was enabled on window
    let winid = win_getid(winnr())
    if g:vimade_running
      exec g:vimade_py_cmd join([
          \ "import vimade,vim",
          \ "vimade.updateState({'diff': {'winid':".winid.",'value':".&diff."}, 'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".winid. "'})",
      \ ], "\n")
  endif
endfunction

function! vimade#GetHi(id)
  "resolve root linkedTo id
  let tid = synIDtrans(a:id)
  return [synIDattr(tid, 'fg#'), synIDattr(tid, 'bg#')]
endfunction

function! vimade#ScheduleTick()
  "timer is disabled when usecursorhold=1
  if !g:vimade_usecursorhold && !exists('g:vimade_timer') && g:vimade_running
    let g:vimade_timer = timer_start(g:vimade.checkinterval, 'vimade#Tick')
  endif
endfunction

function! vimade#Init()
  "get the normal id
  if g:vimade.normalid == "" || g:vimade.normalid == 0
    let g:vimade.normalid = hlID('Normal')
  endif

  if g:vimade_detect_term_colors
    call vimade#DetectTermColors()
  endif

  "check immediately
  call vimade#CheckWindows()
  call vimade#ScheduleTick()

  "run the timer once during startup
  "we use try here to possibly support vim 7
  if g:vimade_usecursorhold
    try
      call timer_start(g:vimade.checkinterval, 'vimade#Tick')
    catch
    endtry
  endif
endfunction

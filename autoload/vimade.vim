function! vimade#Enable()
  let g:vimade_running = 1
  call vimade#CheckWindows(0)
endfunction
function! vimade#Disable()
  let g:vimade_running = 0
  exec g:vimade_py_cmd join([
      \ "import vimade",
      \ "vimade.unfadeAll()",
  \ ], "\n")
endfunction
function! vimade#Toggle()
  if g:vimade_running
    call vimade#Disable()
  else
    call vimade#Enable()
  endif
endfunction

function! vimade#CheckWindows(num)
  if !g:vimade_gvim
    unlet g:vimade_timer
  endif
  if g:vimade_running
    exec g:vimade_py_cmd join([
        \ "import vimade",
        \ "vimade.updateState({'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."'})",
    \ ], "\n")
  endif
  call vimade#ScheduleCheckWindows()
endfunction

function! vimade#FadeCurrentBuffer()
    if g:vimade_running
      exec g:vimade_py_cmd join([
          \ "import vimade",
          \ "vimade.updateState({'activeBuffer': -1, 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."'})",
      \ ], "\n")
    endif
endfunction

function! vimade#UnfadeCurrentBuffer()
    if g:vimade_running
      exec g:vimade_py_cmd join([
          \ "import vimade,vim",
          \ "vimade.updateState({'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."'})",
      \ ], "\n")
    endif
endfunction

function! vimade#DiffToggled()
    let winid = win_getid(winnr())
    if g:vimade_running
      exec g:vimade_py_cmd join([
          \ "import vimade,vim",
          \ "vimade.updateState({'diff': {'winid':".winid.",'value':".&diff."}, 'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".winid. "'})",
      \ ], "\n")
  endif
endfunction

function! vimade#GetHi(id)
  let tid = synIDtrans(a:id)
  return [synIDattr(tid, 'fg#'), synIDattr(tid, 'bg#')]
endfunction

function! vimade#ScheduleCheckWindows()
  if !g:vimade_gvim && !exists('g:vimade_timer')
    let g:vimade_timer = timer_start(g:vimade.checkinterval, 'vimade#CheckWindows')
  endif
endfunction

function! vimade#Init()
  if g:vimade.normalid == "" || g:vimade.normalid == 0
    let i = 0
    let g:vimade.normalid = hlID('Normal')
  endif

  call vimade#ScheduleCheckWindows()
  exec g:vimade_py_cmd join([
      \ "import vimade",
      \ "vimade.updateState({'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."'})",
  \ ], "\n")
endfunction

function! vimade#GetInfo()
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
        \ 'vimade_gvim': g:vimade_gvim,
        \ 'vimade_loaded': g:vimade_loaded,
      \ }
  \ }
endfunction

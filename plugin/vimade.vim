if exists('g:vimade_loaded')
  finish
endif
let g:vimade_loaded = 1
let s:IS_WIN32 = has('win32') && has('gui_running') && !has('nvim')

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

function! vimade#ScheduleCheckWindows()
  if !s:IS_WIN32 && !exists('g:vimade_timer')
    let g:vimade_timer = timer_start(g:vimade.checkinterval, 'vimade#CheckWindows')
  endif
endfunction

function! vimade#Init()
  call vimade#ScheduleCheckWindows()
  exec g:vimade_py_cmd join([
      \ "import vimade",
      \ "vimade.updateState({'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."', 'background': '".&background."'})",
  \ ], "\n")
endfunction

function! vimade#CheckWindows(num)
  if !s:IS_WIN32
    unlet g:vimade_timer
  endif
  exec g:vimade_py_cmd join([
      \ "import vimade",
      \ "vimade.updateState({'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."', 'background':'".&background."'})",
  \ ], "\n")
  call vimade#ScheduleCheckWindows()
endfunction

function! vimade#FadeCurrentBuffer()
    exec g:vimade_py_cmd join([
        \ "import vimade",
        \ "vimade.updateState({'activeBuffer': -1, 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."', 'background':'".&background."'})",
    \ ], "\n")
endfunction

function! vimade#UnfadeCurrentBuffer()
    exec g:vimade_py_cmd join([
        \ "import vimade,vim",
        \ "vimade.updateState({'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".win_getid(winnr())."', 'background':'".&background."'})",
    \ ], "\n")
endfunction

function! vimade#DiffToggled()
    let winid = win_getid(winnr())
    exec g:vimade_py_cmd join([
        \ "import vimade,vim",
        \ "vimade.updateState({'diff': {'winid':".winid.",'value':".&diff."}, 'activeBuffer': str(vim.current.buffer.number), 'activeTab': '".tabpagenr()."', 'activeWindow': '".winid. "', 'background':'".&background."'})",
    \ ], "\n")
endfunction

function! vimade#GetHi(id)
  let tid = synIDtrans(a:id)
  return [synIDattr(tid, 'fg#'), synIDattr(tid, 'bg#')]
endfunction

let g:vimade_plugin_current_directory = resolve(expand('<sfile>:p:h').'/../lib')
exec g:vimade_py_cmd  join([
    \ "import vim",
    \ "sys.path.append(vim.eval('g:vimade_plugin_current_directory'))",
\ ], "\n")

augroup vimade 
    au!
    au VimEnter * call vimade#Init()
    au BufLeave * call vimade#FadeCurrentBuffer()
    au BufEnter * call vimade#UnfadeCurrentBuffer()
    au OptionSet diff call vimade#DiffToggled()
    if s:IS_WIN32
      au CursorHold * call vimade#CheckWindows(0)
      au VimResized * call vimade#CheckWindows(0)
    endif
augroup END

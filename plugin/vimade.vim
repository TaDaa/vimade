if exists('g:vimade_loaded')
  finish
endif

let g:vimade_loaded = 1

if !exists('g:vimade')
  let g:vimade = {}
endif


let g:vimade_plugin_current_directory = resolve(expand('<sfile>:p:h').'/../lib')


""Enables Vimade
command! VimadeEnable call vimade#Enable()

""Unfades all buffers, signs, and disables Vimade
command! VimadeDisable call vimade#Disable()

""Disables the current window
command! VimadeWinDisable call vimade#WinDisable()

""Disables the current buffer
command! VimadeBufDisable call vimade#BufDisable()

""Fades the current buffer
command! VimadeFadeActive call vimade#FadeActive()
"
""Unfades the current buffer
command! VimadeUnfadeActive call vimade#UnfadeActive()

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

""Changes vimade_fadepriority to the {value} specified.  This can be useful
"when combining Vimade with other plugins that also highlight using matches
command! -nargs=1 VimadeFadePriority call vimade#FadePriority(<q-args>)

""Overrides the Folded highlight by creating a link to the Vimade base fade.
"This should produce acceptable results for colorschemes that include Folded
"highlights that are distracting in faded windows.
command! VimadeOverrideFolded call vimade#OverrideFolded()

""EXPERIMENTAL -- Overrides the SignColumn highlight by creating a link to the Vimade base fade.
"This should produce acceptable results for colorschemes that include Folded
"highlights that are distracting in faded windows.
command! VimadeOverrideSignColumn call vimade#OverrideSignColumn()

""EXPERIMENTAL -- Overrides the LineNr highlight by creating a link to the Vimade base fade.
"This should produce acceptable results for colorschemes that include Folded
"highlights that are distracting in faded windows.
command! VimadeOverrideLineNr call vimade#OverrideLineNr()

""EXPERIMENTAL -- Overrides the VertSplit highlight by creating a link to the Vimade base fade.
"This should produce acceptable results for colorschemes that include Folded
"highlights that are distracting in faded windows.
command! VimadeOverrideSplits call vimade#OverrideVertSplit()

""EXPERIMENTAL -- Overrides the NonText highlight by creating a link to the Vimade base fade.
"This should produce acceptable results for colorschemes that include Folded
"highlights that are distracting in faded windows.
command! VimadeOverrideNonText call vimade#OverrideNonText()

""EXPERIMENTAL -- Overrides static highlights by creating a link to the Vimade base fade.
"This should produce acceptable results for colorschemes that include Folded
"highlights that are distracting in faded windows.
command! VimadeOverrideAll call vimade#OverrideAll()

if (!exists('g:vimade_running') || g:vimade_running != 0)
  if v:vim_did_enter 
    call vimade#Empty()
  else
    augroup vimade
      au!
      au VimEnter * call vimade#Empty()
    augroup END
  endif
endif

""
"@section Intro
"@order intro contributing support config commands custom-fades normalnc help
"Vimade is an eye catching plugin that fades your inactive buffers.  You can think of Vimade as 
"2-dimensional infinite syntax list that adjusts itself by reacting to color changes (background, foreground, NormalNC, and colorscheme),
"word wrap, diff groups.  Vimade also implements its own 256 color based fading that does its best to preserve colors instead 
"of rounding to greys.

""@section Contributing
"Open a bug report at 'https://github.com/TaDaa/vimade'.  Please include
"'VimadeInfo' in the report and the more
"information the better, but I will gladly look into everything (even just
"general slowness).

""
"@section Support
"Vim/NVIM support:
"* Vim 8+
"* NVIM
"* GUI
"* terminals (256 color and 'set termguicolors')
"* tmux
"
"Terminal support:
"* All terminals are supported when at least 256 colors are active and a background highlight has been specified.
"
"Terminals with background detection:
"- (Vimade can detect the background color inherited from terminal settings)
"* iTerm
"* Tilix
"* Kitty
"* Gnome
"* Rxvt
"* Other terminals that support the ansi codes \033]11;?\007 or \033]11;?\033\\

""
"@section custom-fades
"Vimade allows you to specify custom tints using basebg.  You can alter this
"value to any hex code or rgb array (e.g '#ff0000' or [255,0,0]) and the text
"of inactive buffers will fade towards the specified color.  You may need to
"adjust the VimadeFadeLevel for favorable results.
"
"For example:
">
"   let vimade.basebg='#ff00000'
"   VimadeFadeLevel 0.6
"<
"Will change the tint to red and favor/mix with the original syntax colors

""@section normalnc
"If you are using NVIM and enable NormalNC ('hi NormalNC guibg=[color]'),
"Vimade will fade using the NormalNC color, which means you can make a pretty
"sleek looking Vim experience.  It might take some effort, but I find the best
"experience to be with background colors that produce lower contrast levels. 


""
"@section FAQ/Help, help
"I am using GVIM and my mappings are not working
"- *Add `let g:vimade.usecursorhold=1` to your vimrc*
"
"What about Vim < 8?
"- *Vim 7.4 is currently untested/experimental, but may work if you add `let g:vimade.usecursorhold=1` to your vimrc*
"My colors look off in terminal mode!
"- *Make sure that you either use a supported terminal or colorscheme or manually define the fg and bg for 'Normal'.  You can also manually define the tint in your vimade config (g:vimade.basebg and g:vimade.basefg)*
"
"Tmux is not working!
"- *Vimade only works in 256 color mode and by default TMUX may set t_Co to 8.   it is recommended that you set `export TERM=xterm-256color` before starting vim.  You can also set `set termguicolors` inside vim if your term supports it for an even more accurate level of fading.*

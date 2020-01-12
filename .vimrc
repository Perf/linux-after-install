
" Powerline
python3 from powerline.vim import setup as powerline_setup
python3 powerline_setup()
python3 del powerline_setup

" Always show statusline
set laststatus=2

" Always display the tabline, even if there is only one tab
set showtabline=2
 
" Hide the default mode text (e.g. -- INSERT -- below the statusline)
set noshowmode
 
" Use 256 colours (Use this setting only if your terminal supports 256 colours)
set t_Co=256


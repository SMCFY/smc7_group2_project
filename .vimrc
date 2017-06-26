source $VIMRUNTIME/macros/matchit.vim 
filetype indent on
source $VIMRUNTIME/macros/matchit.vim
autocmd BufEnter *.m    compiler mlint
:colorscheme matlablight

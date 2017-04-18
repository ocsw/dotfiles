" *********************
" *** global / meta ***
" *********************

" vim, not vi
set nocompatible

" pathogen; load from ~/.vim/bundle
execute pathogen#infect()

" no modelines
set modelines=0

" leader key
let mapleader = "\<Space>"

" command-line tab completion
set wildmode=list:longest,list:full   " with list, longest then cycle


" ***********************
" *** buffer contents ***
" ***********************

" encoding
set encoding=utf-8  " default

" tabs
set shiftwidth=2    " spaces per indent
set tabstop=2       " spaces per tab when displaying
set softtabstop=2   " spaces per tab when inserting
set expandtab       " substitute spaces for tabs


" ****************************
" *** editing and movement ***
" ****************************

" line beginnings/endings
set autoindent      " carry indent over to new lines
set backspace=indent,eol,start  " backspace over everything

" cleanup whitespace
nnoremap <leader>W :%s/\s\+$//<CR>:let @/=''<CR>

" insert-mode tab completion
set completeopt=longest,menu,preview  " longest match, menu, extra info

" scrolling
set scrolljump=5    " scroll five lines at a time vertically
set sidescroll=10   " minumum columns to scroll horizontally

" search
set incsearch       " search with typeahead
set ignorecase      " ignore case when searching
set smartcase       " unless we have at least 1 cap

" history, undo
set history=50      " keep 50 lines of command line history
set undolevels=1000   " number of undos stored

" temp files
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp   " swap files
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp   " backups
set backup          " keep backups


" ***************
" *** display ***
" ***************

" window
set title           " set title when running in term
set noerrorbells    " no bells in terminal

" vim meta
set showcmd         " show normal mode commands as they are entered
set showmode        " show editing mode in status (-- INSERT --)

" buffer meta
set ruler           " show cursor position
set nonumber        " hide line numbers
set laststatus=2    " 2 status lines
set statusline=%t[%{strlen(&fenc)?&fenc:'none'},%{&ff}]%h%y\ Buf\ %n\ %m%r
set statusline+=%=%c,%l/%L\ %P\ 

" in buffer
set list listchars=tab:»·,trail:·   " show tabs and trailing spaces
set showmatch       " flash matching delimiters

" colors
set t_Co=256        " 256 colors
"set background=dark
"colorscheme solarized

" highlighting
if (&t_Co > 2 || has("gui_running"))
  syntax on         " syntax highlighting
  set hlsearch      " persist search highlighting
  " Press space to turn off highlighting and clear any message already
  " displayed.
  :nnoremap <leader> <leader> :nohlsearch<Bar>:echo<CR>
else
  syntax off        " no syntax highlighting
  set nohlsearch    " don't persist search highlighting
endif

" 80-column marking
if (&t_Co > 2 || has("gui_running"))
  highlight OverLength ctermbg=red ctermfg=white guibg=#592929
  match OverLength /\%81v.\+/
  """set colorcolumn=81
endif


" ***************
" *** plugins ***
" ***************

" Flake8
let g:flake8_cmd="/usr/local/bin/flake8"
autocmd FileType python autocmd BufWritePost <buffer> call Flake8()
let g:flake8_show_in_gutter=1
let g:flake8_show_in_file=1

" command-t
let g:CommandTFileScanner='watchman'


" ***********
" *** WIP ***
" ***********

" comment command
" whitespace on save

" paste mode
"set pastetoggle=<leader>p
"set cursorline


" *************
" *** local ***
" *************

let s:vimrc_local = $HOME . "/.vimrc.local"
if filereadable(s:vimrc_local)
  execute "source " . s:vimrc_local
endif

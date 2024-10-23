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
set wildmode=list:longest,list:full  " with list, longest then cycle


" ***********************
" *** buffer contents ***
" ***********************

" encoding
set encoding=utf-8  " default

" tabs
set shiftwidth=4    " spaces per indent
set tabstop=4       " spaces per tab when displaying
set softtabstop=4   " spaces per tab when inserting
set expandtab       " substitute spaces for tabs
set smarttab        " tab inserts indents instead of tabs at begining of line
set textwidth=79    " for wrapping; e.g. gggqG

if has("autocmd")
    autocmd FileType make setl noexpandtab
endif


" ****************************
" *** editing and movement ***
" ****************************

" line beginnings/endings
set autoindent                  " carry indent over to new lines
set backspace=indent,eol,start  " backspace over everything

" cleanup whitespace at end of line
noremap <Leader>w :%s/\s\+$//<CR>:let @/=''<CR>

" paste mode
set pastetoggle=<F2>

" insert-mode tab completion
set completeopt=longest,menu,preview  " longest match, menu, extra info

" scrolling
set scrolljump=5     " scroll five lines at a time vertically
set sidescroll=10    " minumum columns to scroll horizontally

" search
set incsearch        " search with typeahead
set ignorecase       " ignore case when searching
set smartcase        " unless we have at least 1 cap

" history, undo
set history=50       " keep 50 lines of command line history
set undolevels=1000  " number of undos stored

" temp files
set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp  " swap files
set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp  " backups
set backup           " keep backups


" ***************
" *** display ***
" ***************

" window
set title         " set title when running in term
set noerrorbells  " no bells in terminal

" vim meta
set showcmd       " show normal mode commands as they are entered
set showmode      " show editing mode in status (-- INSERT --)

" buffer meta
set ruler         " show cursor position
set nonumber      " hide line numbers
set laststatus=2  " 2 status lines
set statusline=%t[%{strlen(&fenc)?&fenc:'none'},%{&ff}]%h%y\ Buf\ %n\ %m%r
set statusline+=%=%c,%l/%L\ %P\ 

" in buffer
set list listchars=tab:»·,trail:·  " show tabs and trailing spaces
set showmatch     " flash matching delimiters

" colors
set t_Co=256      " 256 colors
"set background=dark
"colorscheme solarized

" highlighting
if (&t_Co > 2 || has("gui_running"))
    " syntax highlighting
    syntax on

    " persist search highlighting
    set hlsearch
    " clear current highlighting
    nnoremap <Leader><Space> :nohlsearch<Bar>:echo<CR>

    " 80-column marking
    highlight OverLength ctermbg=Red ctermfg=White guibg=Red
    match OverLength /\%81v.\+/
    """set colorcolumn=81

    " cursor-line highlighting
    if (&t_Co >= 256)
        " see http://vim.wikia.com/wiki/Xterm256_color_names_for_console_Vim
        highlight CursorLine cterm=NONE ctermbg=236 guibg=#303030
    else
        highlight CursorLine cterm=NONE ctermbg=DarkGray guibg=#303030
    endif
    set cursorline
    " toggle
    nnoremap <Leader>h :set cursorline!<CR>
    " for current window only
    " (see http://vim.wikia.com/wiki/Highlight_current_line)
    """ augroup CursorLine
    """     au!
    """     au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
    """     au WinLeave * setlocal nocursorline
    """ augroup END

else
    syntax off        " no syntax highlighting
    set nohlsearch    " don't persist search highlighting
    set nocursorline  " no cursor-line highlighting
endif


" ***************
" *** plugins ***
" ***************

" Flake8
let g:flake8_cmd = $HOME . "/bin/flake8"
autocmd FileType python autocmd BufWritePost <buffer> call Flake8()
let g:flake8_show_in_gutter=1
let g:flake8_show_in_file=1

" command-t
let g:CommandTFileScanner='watchman'


" ***********
" *** WIP ***
" ***********

" whitespace on save

"set cursorline

"if has("autocmd")
"    augroup redhat
"    autocmd!
"    " When editing a file, always jump to the last cursor position
"    autocmd BufReadPost *
"    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
"    \   exe "normal! g'\"" |
"    \ endif
"    augroup END
"endif


" *******************
" *** sub-scripts ***
" *******************

let s:vimrc_extra = $HOME . "/.vimrc.d"
let file_list = split(globpath(s:vimrc_extra, "*.vim"), "\n")
for file in file_list
    execute "source " . fnameescape(file)
endfor


" *************
" *** local ***
" *************

let s:vimrc_local = $HOME . "/.vimrc.local"
if filereadable(s:vimrc_local)
    execute "source " . fnameescape(s:vimrc_local)
endif

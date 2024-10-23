" [from the Facebook dotfile collection, with tweaks]

" A little function (and associated binding) for toggling commenting.
" To use it, put 'source /path/to/toggle_comment.vim' in your .vimrc,
" then type C in command mode to comment a line, or highlight some text
" and type C to comment the whole block.
"
" @author dreiss

" Some machines don't have Vim 7.
if v:version < 700
    finish
endif

function! HelperCommentLine(indent)
    let lc = getline(".")
    " Just do it unconditionally.  Detecting comments is too tricky.
    "if lc !~ (' \{'.indent.'\}\V' . b:comment_prefix)
    let lc = repeat(" ", a:indent) . b:comment_prefix . lc[a:indent : ]
    call setline(line("."), lc)
endfunction

function! HelperUncommentLine()
    let ln = line(".")
    let re = '^\( *\)\V' . b:comment_prefix
    call setline(ln, substitute(getline(ln), re, '\1', ""))
endfunction

function! ToggleComment() range
    if !exists("b:comment_prefix")
        echo "b:comment_prefix is not defined."
        return
    endif

    let min_indent = 200  " If you indent more, you have bigger problems
    let all_comment = 1
    let comm_re = '^\( *\)\V' . b:comment_prefix

    for ln in range(a:firstline, a:lastline)
        if getline(ln) =~ '^\s*$'
            call setline(ln, "")
            continue
        endif
        let indent = len(matchstr(getline(ln), '^ *'))
        let min_indent = min([min_indent, indent])
        let all_comment = all_comment && match(getline(ln), comm_re) >= 0
    endfor

    for ln in range(a:firstline, a:lastline)
        if getline(ln) =~ '^\s*$'
            continue
        endif
        if all_comment
            execute ln . "call HelperUncommentLine()"
        else
            execute ln . "call HelperCommentLine(" . min_indent . ")"
        endif
    endfor
endfunction

autocmd BufReadPost *.thrift let b:comment_prefix = "//"
autocmd BufReadPost *.phpt   let b:comment_prefix = "//"
autocmd BufReadPost *.php    let b:comment_prefix = "//"
autocmd BufReadPost *.py     let b:comment_prefix = "# "
autocmd BufReadPost *.cpp    let b:comment_prefix = "//"
autocmd BufReadPost *.cc     let b:comment_prefix = "//"
autocmd BufReadPost *.c      let b:comment_prefix = "//"
autocmd BufReadPost *.h      let b:comment_prefix = "//"
autocmd BufReadPost *.hs     let b:comment_prefix = "--"
autocmd BufReadPost *.hsc    let b:comment_prefix = "--"
autocmd BufReadPost *.vim    let b:comment_prefix = "\""
autocmd BufReadPost *.vimrc  let b:comment_prefix = "\""
autocmd BufReadPost *.go     let b:comment_prefix = "//"
autocmd BufReadPost go.mod   let b:comment_prefix = "//"
autocmd BufReadPost go.sum   let b:comment_prefix = "//"
autocmd BufReadPost *.sh     let b:comment_prefix = "# "
autocmd BufReadPost Makefile let b:comment_prefix = "# "
autocmd BufReadPost *.mk     let b:comment_prefix = "# "

noremap <Leader>c :call ToggleComment()<CR>

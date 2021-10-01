fun! s:lazy()
    echo 'hi'
endfun

autocmd BufNewFile * call s:lazy()

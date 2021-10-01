let s:fileType = {
            \   'vim': {a, b -> s:vim(a, b)},
            \}

fun! Lazy()
    let fileType = expand('%:e')
    let Func = get(s:fileType, fileType, 0)
    if Func != 0
        let sw = exists('*shiftwidth') ? shiftwidth() : &l:shiftwidth
        let indent = (&l:expandtab || &l:tabstop !=# sw) ? repeat(' ', sw) : "\t"
        call Func(fileType, indent)
    endif
endfun

fun! s:count(string)
    let i = 0
    for char in split(a:string, '\zs')
        if char == " "
            let i += 1
        else
            break
        endif
    endfor
    return i
endfun

fun! s:vim(fileType, indent)
    let line = getline('.')
    let spaces = s:count(line)
    let parts = split(line, ' ')
    let linePtn = line('.')
    if parts[0] == 'fun'
        let args = []
        for arg in parts[2:-1]
            let args = add(args, arg)
        endfor
        call setline(linePtn, repeat(" ", spaces) . "fun! " . parts[1] . "(" . join(args, ', ') . ")")
        call append(linePtn, [repeat(" ", spaces) . a:indent, repeat(" ", spaces) . "endfun"])
        call cursor(linePtn + 1, spaces + len(a:indent))
    elseif parts[0] == 'if'
        let cods = []
        let cod = ['if']
        for arg in parts[1:-1]
            if arg == "ef"
                let cods = add(cods, cod)
                let cod = ['elseif']
            elseif arg == "el"
                let cods = add(cods, cod)
                let cods = add(cods, ['else'])
            else
                let cod = add(cod, arg)
            endif
        endfor
        call setline(linePtn, repeat(" ", spaces) . join(cods[0], " "))
        call append(linePtn, repeat(" ", spaces) . a:indent)
        let save = linePtn
        let linePtn += 1
        for cod in cods[1:-1]
            call append(linePtn, [repeat(" ", spaces) . join(cod, " "), repeat(" ", spaces) . a:indent])
            let linePtn += 2
        endfor
        call append(linePtn, repeat(" ", spaces) . "endif")
        call cursor(save + 1, spaces + len(a:indent))
    elseif parts[0] == 'wle'
        call setline(linePtn, repeat(" ", spaces) . "while " . join(parts[1:-1], " "))
        call append(linePtn, [repeat(" ", spaces) . a:indent, repeat(" ", spaces) . "endwhile"])
        call cursor(linePtn + 1, spaces + len(a:indent))
    elseif parts[0] == 'if'
    elseif parts[0] == 'for'
        if len(parts) == 2
            return
        elseif len(parts) == 3
            return
        elseif parts[2] == "in"
            return
        elseif parts[2] == "of"
            return
        endif
    endif
endfun

imap <C-l> <Esc>:call Lazy()<CR>a
vmap <C-l> :call Lazy()<CR>a
nmap <C-l> :call Lazy()<CR>a


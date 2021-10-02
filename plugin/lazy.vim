let s:fileType = {
            \    'py': {a, b, c -> s:py(a, b, c)},
            \   'vim': {a, b, c -> s:vim(a, b, c)},
            \}
let s:indent = ""

fun! Lazy()
    let Func = get(s:fileType, expand('%:e'), 0)
    if Func != 0
        let sw = exists('*shiftwidth') ? shiftwidth() : &l:shiftwidth
        let s:indent = (&l:expandtab || &l:tabstop !=# sw) ? repeat(' ', sw) : "\t"
        let line = getline('.')
        let spaces = s:count(line)
        let line = split(line, ' ')
        let linePtn = line('.')
        call Func(line, linePtn, spaces)
    endif
endfun

fun! s:count(string)
    let i = 0
    for char in split(a:string, '\zs')
        if char == " "
            let i += 1
        else
            return i
        endif
    endfor
endfun

fun! s:for(linePtn, spaces, var, args, braces)
    let args = len(a:args) == 1 ? a:args[0] : join(a:args, ', ')
    call setline(a:linePtn, repeat(" ", a:spaces) . "for " . a:var . " in range(" . args . ")" . a:braces[0])
    let for = [repeat(" ", a:spaces) . s:indent]
    if a:braces[1] != ""
        let for = add(for, repeat(" ", a:spaces) . a:braces[1])
    endif
    call append(a:linePtn, for)
    call cursor(a:linePtn + 1, a:spaces + len(s:indent))
endfun

fun! s:py(line, linePtn, spaces)
    if a:line[0] == 'fun'
        return
    elseif a:line[0] == 'if'
        
    elseif a:line[0] == 'wle'
        call setline(a:linePtn, repeat(" ", a:spaces) . "while " . join(a:line[1:-1], " ") . ":")
        call append(a:linePtn, repeat(" ", a:spaces) . s:indent)
        call cursor(a:linePtn + 1, a:spaces + len(s:indent))
    elseif a:line[0] == 'for'
        if len(a:line) == 2
            let args = split(a:line[1], ">")
            call s:for(a:linePtn, a:spaces, "i", args, [":", ""])
        elseif len(a:line) == 3
            let args = split(a:line[2], ">")
            call s:for(a:linePtn, a:spaces, a:line[1], args, [":", ""])
        elseif a:line[2] == "in"
            call setline(a:linePtn, repeat(" ", a:spaces) . "for " . a:line[1] . " in " . a:line[3] . ":")
            call append(a:linePtn, repeat(" ", a:spaces) . s:indent)
        elseif a:line[2] == "of"
            call setline(a:linePtn, repeat(" ", a:spaces) . "for " . a:line[1] . " in range(len(" . a:line[3] . ")):")
            call append(a:linePtn, repeat(" ", a:spaces) . s:indent)
        endif
    elseif a:line[0] == 'cls'
        
    endif
endfun

fun! s:vim(line, linePtn, spaces)
    if a:line[0] == 'fun'
        let args = []
        for arg in a:line[2:-1]
            let args = add(args, arg)
        endfor
        call setline(a:linePtn, repeat(" ", a:spaces) . "fun! " . a:line[1] . "(" . join(args, ', ') . ")")
        call append(a:linePtn, [repeat(" ", a:spaces) . s:indent, repeat(" ", a:spaces) . "endfun"])
        call cursor(a:linePtn + 1, a:spaces + len(s:indent))
    elseif a:line[0] == 'if'
        let cods = []
        let cod = ['if']
        for arg in a:line[1:-1]
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
        call setline(a:linePtn, repeat(" ", a:spaces) . join(cods[0], " "))
        call append(a:linePtn, repeat(" ", a:spaces) . s:indent)
        let save = a:linePtn + 1
        for cod in cods[1:-1]
            call append(save, [repeat(" ", a:spaces) . join(cod, " "), repeat(" ", a:spaces) . s:indent])
            let save += 2
        endfor
        call append(save, repeat(" ", a:spaces) . "endif")
        call cursor(a:linePtn + 1, a:spaces + len(s:indent))
    elseif a:line[0] == 'wle'
        call setline(a:linePtn, repeat(" ", a:spaces) . "while " . join(a:line[1:-1], " "))
        call append(a:linePtn, [repeat(" ", a:spaces) . s:indent, repeat(" ", a:spaces) . "endwhile"])
        call cursor(a:linePtn + 1, a:spaces + len(s:indent))
    elseif a:line[0] == 'for'
        if len(a:line) == 2
            let args = split(a:line[1], ">")
            call s:for(a:linePtn, a:spaces, "i", args, ["", "endfor"])
        elseif len(a:line) == 3
            let args = split(a:line[2], ">")
            call s:for(a:linePtn, a:spaces, a:line[1], args, ["", "endfor"])
        elseif a:line[2] == "in"
            call append(a:linePtn, [repeat(" ", a:spaces) . s:indent, repeat(" ", a:spaces) . "endfun"])
        elseif a:line[2] == "of"
            call setline(a:linePtn, repeat(" ", a:spaces) . "for " . a:line[1] . " in range(len(" . a:line[3] . "))")
            call append(a:linePtn, [repeat(" ", a:spaces) . s:indent, repeat(" ", a:spaces) . "endfun"])
        endif
    endif
endfun

imap <C-l> <Esc>:call Lazy()<CR>a
vmap <C-l> :call Lazy()<CR>a
nmap <C-l> :call Lazy()<CR>a

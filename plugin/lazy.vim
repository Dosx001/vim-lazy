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

fun! s:forLoop(line, linePtn, spaces, braces)
    if len(a:line) == 2
        let args = split(a:line[1], ">")
        call s:for(a:linePtn, a:spaces, "i", args, a:braces)
    elseif len(a:line) == 3
        let args = split(a:line[2], ">")
        call s:for(a:linePtn, a:spaces, a:line[1], args, a:braces)
    elseif a:line[2] == "in"
        call s:for(a:linePtn, a:spaces, a:line[1], a:line[3], a:braces)
    elseif a:line[2] == "of"
        call s:for(a:linePtn, a:spaces, a:line[1], "range(len(" . a:line[3] . "))", a:braces)
    endif
endfun

fun! s:for(linePtn, spaces, var, args, braces)
    if type(a:args) == 3
        let args = len(a:args) == 1 ? a:args[0] : join(a:args, ', ')
        call setline(a:linePtn, repeat(" ", a:spaces) . "for " . a:var . " in range(" . args . ")" . a:braces[0])
    else
        call setline(a:linePtn, repeat(" ", a:spaces) . "for " . a:var . " in " . a:args . a:braces[0])
    endif
    let for = [repeat(" ", a:spaces) . s:indent]
    if a:braces[1] != ""
        let for = add(for, repeat(" ", a:spaces) . a:braces[1])
    endif
    call append(a:linePtn, for)
    call cursor(a:linePtn + 1, a:spaces + len(s:indent))
endfun

fun! s:whileLoop(line, linePtn, spaces, braces)
    call setline(a:linePtn, repeat(" ", a:spaces) . "while " . join(a:line[1:-1], " ") . a:braces[0])
    call append(a:linePtn, [repeat(" ", a:spaces) . s:indent, repeat(" ", a:spaces) . a:braces[1]])
    call cursor(a:linePtn + 1, a:spaces + len(s:indent))
endfun

fun! s:msg(lang)
    echohl WarningMsg
    echo a:lang "does not support "
    echohl Type
    echon "Classes"
    echohl None
endfun

fun! s:py(line, linePtn, spaces)
    if a:line[0] == 'fun'
        
    elseif a:line[0] == 'if'
        
    elseif a:line[0] == 'wle'
        call s:whileLoop(a:line, a:linePtn, a:spaces, [":", ""])
    elseif a:line[0] == 'for'
        call s:forLoop(a:line, a:linePtn, a:spaces, [":", ""])
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
        call s:whileLoop(a:line, a:linePtn, a:spaces, ["", "endwhile"])
    elseif a:line[0] == 'for'
        call s:forLoop(a:line, a:linePtn, a:spaces, ["", "endfor"])
    elseif a:line[0] == "cls"
        call s:msg("Vimscript")
    endif
endfun

imap <C-l> <Esc>:call Lazy()<CR>a
vmap <C-l> :call Lazy()<CR>a
nmap <C-l> :call Lazy()<CR>a

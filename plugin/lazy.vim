let s:fileType = {
            \    'py': {a -> s:py(a)},
            \   'vim': {a -> s:vim(a)},
            \}
let s:indent = ""
let s:line = []
let s:linePtn = 0
let s:spaces = 0

fun! Lazy()
    let Func = get(s:fileType, expand('%:e'), 0)
    if Func != 0
        let sw = exists('*shiftwidth') ? shiftwidth() : &l:shiftwidth
        let s:indent = (&l:expandtab || &l:tabstop !=# sw) ? repeat(' ', sw) : "\t"
        let s:line = getline('.')
        let s:spaces = s:count(s:line)
        let s:line = split(s:line, ' ')
        if !empty(s:line)
            let s:linePtn = line('.')
            call Func(s:line[0])
        endif
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

fun! s:ifElse(brace, elif, end)
    let cods = []
    let cod = ['if']
    for arg in s:line[1:-1]
        if arg == "ef"
            let cod[-1] = cod[-1] . a:brace
            let cods = add(cods, cod)
            let cod = [a:elif]
        elseif arg == "el"
            let cod[-1] = cod[-1] . a:brace
            let cods = add(cods, cod)
            let cods = add(cods, ['else' . a:brace])
        else
            let cod = add(cod, arg)
        endif
    endfor
    let line = repeat(" ", s:spaces)
    if empty(cods)
        let line = line . join(cod, " ") . a:brace
    else
        let line = line . join(cods[0], " ")
    endif
    call setline(s:linePtn, line)
    call append(s:linePtn, repeat(" ", s:spaces) . s:indent)
    let save = s:linePtn + 1
    for cod in cods[1:-1]
        call append(save, [repeat(" ", s:spaces) . join(cod, " "), repeat(" ", s:spaces) . s:indent])
        let save += 2
    endfor
    if !empty(a:end)
        call append(save, repeat(" ", s:spaces) . a:end)
    endif
    call cursor(s:linePtn + 1, s:spaces + len(s:indent))
endfun

fun! s:function(key, braces)
    let args = []
    for arg in s:line[2:-1]
        let args = add(args, arg)
    endfor
    call setline(s:linePtn, repeat(" ", s:spaces) . a:key . " " . s:line[1] . "(" . join(args, ', ') . ")" . a:braces[0])
    let line = [repeat(" ", s:spaces) . s:indent]
    if !empty(a:braces[1])
        let line = add(line, repeat(" ", s:spaces) . a:braces[1])
    endif
    call append(s:linePtn, line)
    call cursor(s:linePtn + 1, s:spaces + len(s:indent))
endfun

fun! s:forLoop(braces)
    if len(s:line) == 2
        let args = split(s:line[1], ">")
        call s:for("i", args, a:braces)
    elseif len(s:line) == 3
        let args = split(s:line[2], ">")
        call s:for(s:line[1], args, a:braces)
    elseif s:line[2] == "in"
        call s:for(s:line[1], s:line[3], a:braces)
    elseif s:line[2] == "of"
        call s:for(s:line[1], "range(len(" . s:line[3] . "))", a:braces)
    endif
endfun

fun! s:for(var, args, braces)
    if type(a:args) == 3
        let args = len(a:args) == 1 ? a:args[0] : join(a:args, ', ')
        call setline(s:linePtn, repeat(" ", s:spaces) . "for " . a:var . " in range(" . args . ")" . a:braces[0])
    else
        call setline(s:linePtn, repeat(" ", s:spaces) . "for " . a:var . " in " . a:args . a:braces[0])
    endif
    let for = [repeat(" ", s:spaces) . s:indent]
    if !empty(a:braces[1])
        let for = add(for, repeat(" ", s:spaces) . a:braces[1])
    endif
    call append(s:linePtn, for)
    call cursor(s:linePtn + 1, s:spaces + len(s:indent))
endfun

fun! s:whileLoop(braces)
    call setline(s:linePtn, repeat(" ", s:spaces) . "while " . join(s:line[1:-1], " ") . a:braces[0])
    call append(s:linePtn, [repeat(" ", s:spaces) . s:indent, repeat(" ", s:spaces) . a:braces[1]])
    call cursor(s:linePtn + 1, s:spaces + len(s:indent))
endfun

fun! s:msg(lang)
    echohl WarningMsg
    echo a:lang "does not support "
    echohl Type
    echon "Classes"
    echohl None
endfun

fun! s:py(key)
    if a:key == 'fun'
        call s:function("def", [":", ""])
    elseif a:key == 'if'
        call s:ifElse(":", "elif", "")
    elseif a:key == 'wle'
        call s:whileLoop([":", ""])
    elseif a:key == 'for'
        call s:forLoop([":", ""])
    elseif a:key == 'cls'
        
    endif
endfun

fun! s:vim(key)
    if a:key == 'fun'
        call s:function("fun!", ["", "endfun"])
    elseif a:key == 'if'
        call s:ifElse("", "elseif", "endif")
    elseif a:key == 'wle'
        call s:whileLoop(["", "endwhile"])
    elseif a:key == 'for'
        call s:forLoop(["", "endfor"])
    elseif a:key == "cls"
        call s:msg("Vimscript")
    endif
endfun

imap <C-l> <Esc>:call Lazy()<CR>a
vmap <C-l> :call Lazy()<CR>a
nmap <C-l> :call Lazy()<CR>a

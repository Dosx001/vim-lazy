let s:fileType = {
            \   'cpp': {a -> s:cpp(a)},
            \    'py': {a -> s:py(a)},
            \   'vim': {a -> s:vim(a)},
            \}
let s:ind = ""
let s:line = []
let s:linePtn = 0
let s:spaces = ""

fun! Lazy()
    let Func = get(s:fileType, &ft, 0)
    if Func != 0
        let sw = exists('*shiftwidth') ? shiftwidth() : &l:shiftwidth
        let s:ind = (&l:expandtab || &l:tabstop !=# sw) ? repeat(' ', sw) : "\t"
        let s:line = getline('.')
        let i = -1
        for char in split(s:line, '\zs')
            if char == " " || char == "	"
                let i += 1
            else
                break
            endif
        endfor
        let s:spaces = i != -1 ? s:line[0:i] : ""
        let s:line = split(s:line[i + 1: -1], " ")
        if !empty(s:line)
            let s:linePtn = line('.')
            call Func(s:line[0])
        endif
    endif
endfun

fun! s:indent(num)
    return s:spaces . repeat(s:ind, a:num)
endfun

fun! s:cursor()
    call cursor(s:linePtn + 1, len(s:spaces) + len(s:ind))
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
    let line = s:indent(0)
    if empty(cods)
        let line = line . join(cod, " ") . a:brace
    else
        let line = line . join(cods[0], " ")
    endif
    call setline(s:linePtn, line)
    call append(s:linePtn, s:indent(1))
    let save = s:linePtn + 1
    for cod in cods[1:-1]
        call append(save, [s:indent(0) . join(cod, " "), s:indent(1)])
        let save += 2
    endfor
    if !empty(a:end)
        call append(save, s:indent(0) . a:end)
    endif
    call s:cursor()
endfun

fun! s:function(key, braces)
    let args = []
    for arg in s:line[2:-1]
        let args = add(args, arg)
    endfor
    call setline(s:linePtn, s:indent(0) . a:key . " " . s:line[1] . "(" . join(args, ', ') . ")" . a:braces[0])
    let line = [s:indent(0)]
    if !empty(a:braces[1])
        let line = add(line, s:indent(0) . a:braces[1])
    endif
    call append(s:linePtn, line)
    call s:cursor()
endfun

fun! s:forLoop(type, braces)
    if len(s:line) == 2
        let args = split(s:line[1], ">")
        if a:type == 0
            call s:for("i", args, a:braces)
        else
            if len(args) == 1
                call s:forC("i", [0, args[0], 1], a:braces)
            elseif len(args) == 2
                call s:forC("i", [args[0], args[1], 1], a:braces)
            else
                call s:forC("i", [args[0], args[1], args[2]], a:braces)
            endif
        endif
    elseif len(s:line) == 3
        let args = split(s:line[2], ">")
        if a:type == 0
            call s:for(s:line[1], args, a:braces)
        else
            if len(args) == 1
                call s:forC(s:line[1], [0, args[0], 1], a:braces)
            elseif len(args) == 2
                call s:forC(s:line[1], [args[0], args[1], 1], a:braces)
            else
                call s:forC(s:line[1], [args[0], args[1], args[2]], a:braces)
            endif
        endif
    elseif s:line[2] == "in"
        call s:for(s:line[1], s:line[3], a:braces)
    elseif s:line[2] == "of"
        call s:for(s:line[1], "range(len(" . s:line[3] . "))", a:braces)
    endif
endfun

fun! s:for(var, args, braces)
    if type(a:args) == 3
        let args = len(a:args) == 1 ? a:args[0] : join(a:args, ', ')
        call setline(s:linePtn, s:indent(0) . "for " . a:var . " in range(" . args . ")" . a:braces[0])
    else
        call setline(s:linePtn, s:indent(0) . "for " . a:var . " in " . a:args . a:braces[0])
    endif
    let for = [s:indent(1)]
    if !empty(a:braces[1])
        let for = add(for, s:indent(0) . a:braces[1])
    endif
    call append(s:linePtn, for)
    call s:cursor()
endfun

fun! s:forC(var, args, key)
    let line = s:indent(0) . "for (" . a:key . " " . a:var . " = " . a:args[0] . "; "
    if 0 < a:args[2]
        let line = line . a:var . " < " . a:args[1] . "; " . a:var
    else
        let line = line . a:args[1] . " < " . a:var . "; " . a:var
    endif
    if a:args[2] == 1
        let line = line . "++) {"
    elseif a:args[2] == -1
        let line = line . "--) {"
    elseif 0 < a:args[2]
        let line = line . " += " . a:args[2] . ") {"
    else
        let line = line . " -= " . a:args[2] . ") {"
    endif
    call setline(s:linePtn, line)
    call append(s:linePtn, [s:indent(1), s:indent(0) . "}"])
endfun

fun! s:whileLoop(braces)
    call setline(s:linePtn, s:indent(0) . "while " . join(s:line[1:-1], " ") . a:braces[0])
    let lines = [s:indent(1)]
    if !empty(a:braces[1])
        let lines = add(lines, s:indent(0) . a:braces[1])
    endif
    call append(s:linePtn, lines)
    call s:cursor()
endfun

fun! s:msg(lang)
    echohl WarningMsg
    echo a:lang "does not support "
    echohl Type
    echon "Classes"
    echohl None
endfun

fun! s:cpp(key)
    if a:key == 'fun'
        
    elseif a:key == 'if'
        
    elseif a:key == 'wle'
        
    elseif a:key == 'for'
        call s:forLoop(1, "int")
    endif
endfun

fun! s:py(key)
    if a:key == 'fun'
        call s:function("def", [":", ""])
    elseif a:key == 'if'
        call s:ifElse(":", "elif", "")
    elseif a:key == 'wle'
        call s:whileLoop([":", ""])
    elseif a:key == 'for'
        call s:forLoop(0, [":", ""])
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
        call s:forLoop(0, ["", "endfor"])
    elseif a:key == "cls"
        call s:msg("Vimscript")
    endif
endfun

imap <C-l> <Esc>:call Lazy()<CR>a
vmap <C-l> :call Lazy()<CR>a
nmap <C-l> :call Lazy()<CR>a

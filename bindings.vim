func! s:pair(area, commands)
    if has_key(s:pair, a:commands)
        return s:search_pairings(a:area, a:commands[0]=='a', s:pair[a:commands])
    endif
    return []
endfunc

func! s:quote(area, commands)
    if has_key(s:quote, a:commands)
        return s:search_quote(a:area, a:commands[0]=='a', s:quote[a:commands])
    endif
    return []
endfunc
let s:p = function('s:pair')
let s:q = function('s:quote')
let s:pair = {}    
let s:quote = {}    
func! s:add_maps(keys, map)
    for key in a:keys
        let s:pair['i'.key] = a:map
        let s:pair['a'.key] = a:map
        let g:multi_bindings.area.textobject['i'.key] = s:p
        let g:multi_bindings.area.textobject['a'.key] = s:p
    endfor
endfunc
func! s:add_quotes(keys, map)
    for key in a:keys
        let s:quote['i'.key] = a:map
        let s:quote['a'.key] = a:map
        let g:multi_bindings.area.textobject['i'.key] = s:q
        let g:multi_bindings.area.textobject['a'.key] = s:q
    endfor
endfunc
call s:add_maps(["b","(",")"], ["(",")"])
call s:add_maps(["B","{","}"], ["{","}"])
call s:add_maps(["<",">"], ["<",">"])
call s:add_maps(["[","]"], ['\[',']'])
call s:add_quotes(['"'], '"')
call s:add_quotes(["'"], "'")

" \@!
func! s:search_pairings(area, inclusive, pairs)
    let start = a:pairs[0]
    let middle = ""
    let end = a:pairs[1]
    let result = []

    call setpos(".", a:area.left)
    let [line, col] = searchpos(start, "cW")
    if !a:inclusive
        let col += 1
    endif
    if line == 0 || line == -1
        return result
    endif
    let reg = getreg('"')
    while 1
        let pos = [0, line, col, 0]
        let left = pos
        let [line, col] = searchpairpos(start, middle, end, "W")
        if line == -1 || line == 0
            break
        endif
        if !a:inclusive
            let col -= 1
        endif
        let right = [0, line, col, 0]
        if  multi#compare_pos(right, a:area.right) < 1
            if multi#compare_pos(left, right) == -1
                call add(result, {
                   \"isVisual": 1,
                   \"cursor":   pos,
                   \"left":     left,
                   \"right":    right,
                   \"reg":      reg,
                   \})
            endif
        else
            break
        endif
        let [line, col] = searchpos(start, "W")
        if line == -1 || line == 0 || multi#compare_pos(right, a:area.right) != -1
            break
        endif
        if !a:inclusive
            let col += 1
        endif
    endwhile
    return result
endfunc
func! s:search_quote(area, inclusive, quote)
    let result = []

    call setpos(".", a:area.left)
    let [line, col] = searchpos(a:quote, "cW")
    if !a:inclusive
        let col += 1
    endif
    if line == 0 || line == -1
        return result
    endif
    let reg = getreg('"')
    while 1
        let pos = [0, line, col, 0]
        let left = pos
        let [line, col] = searchpos('\\\@<!'.a:quote.'\|\%(\\\\\)\@<='.a:quote, "W")
        if line == -1 || line == 0
            break
        endif
        if !a:inclusive
            let col -= 1
        endif
        let right = [0, line, col, 0]
        if  multi#compare_pos(right, a:area.right) < 1
            call add(result, {
               \"isVisual": 1,
               \"cursor":   pos,
               \"left":     left,
               \"right":    right,
               \"reg":      reg,
               \})
        else
            break
        endif
        let [line, col] = searchpos(a:quote, "W")
        if line == -1 || line == 0 || multi#compare_pos(right, a:area.right) != -1
            break
        endif
        if !a:inclusive
            let col += 1
        endif
    endwhile
    return result
endfunc

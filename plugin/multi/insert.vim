function! multi#insert#setup(input, type)
    let s:changes = 0
    let g:multi#command#insert.undo_count = 0
    if a:type == 'normal'
        call g:multi#state_manager.apply(g:multi#command#insert, 'prime_normal', a:input, 1)
    else
        call g:multi#state_manager.apply(g:multi#command#insert, 'prime_visual', a:input, 1)
    endif
    call g:multi#state_manager.redraw()
    let insert_input = ""
    while 1
        let s:first = s:changes
        let s:changes = 1
        " echo "-- INSERT --"
        let c = getchar()
        if type(c) == 0
            let s = nr2char(c)
        else
            let s = c
        endif
        let insert_input .= s
        if s == "\<Esc>"
            break
        endif
        unlet c
        call g:multi#state_manager.apply(g:multi#command#insert, 'normal', s, 1)
        call g:multi#state_manager.redraw()
    endwhile
    if len(insert_input) > 0
        let g:multi#state_manager.state.repeat_command = a:input . insert_input
    endif
endfunction

let multi#command#insert = {'undo_count':0}
function multi#command#insert.prime_visual(area, command)
    let tick = b:changedtick
    if self.undo_count > 1
        undojoin | call multi#util#apply_visual(a:area, a:command)
    else
        call multi#util#apply_visual(a:area, a:command)
    endif
    if g:multi#state_manager.state.tick != b:changedtick
        let self.undo_count += 1
    endif
    let new_area = multi#util#new_area("normal")
    let new_area[2] = getpos("'^")[2] - 1
    if new_area[2] == 0
        let new_area[2] = 1
        let new_area.col_0 = 1
    else
        let new_area.col_0 = 0
    endif
    return [new_area]
endfunction
function multi#command#insert.prime_normal(area, command)
    call multi#util#setup(a:area.cursor)
    if self.undo_count > 1
        undojoin | exec "silent norm " . a:command
    else
        exec "silent norm " . a:command
    endif
    if g:multi#state_manager.state.tick != b:changedtick
        let self.undo_count += 1
    endif
    let new_area = multi#util#new_area("normal")
    let new_area[2] = getpos("'^")[2] - 1
    if new_area[2] == 0
        let new_area[2] = 1
        let new_area.col_0 = 1
    else
        let new_area.col_0 = 0
    endif
    return [new_area]
endfunction
function multi#command#insert.normal(area, command)
    call setpos(".", a:area.cursor)
    let insert_direction =  a:area.col_0 == 0 ? 'a' : 'i'
    " echo b:changedtick
    " call getchar()
    if self.undo_count > 0
        undojoin | execute "norm! ".insert_direction.a:command
        let self.undo_count = 1
    else
        execute "norm ".insert_direction.a:command
    endif
    let new_area = multi#util#new_area("normal")
    let new_area[2] = getpos("'^")[2] - 1
    if new_area[2] == 0
        let new_area[2] = 1
        let new_area.col_0 = 1
    else
        let new_area.col_0 = 0
    endif
    return [new_area]
endfunction


" function multi#command#insert.normal(area, command)
"     call multi#util#setup(a:area.cursor)
"     if self.undo_count > 1
"         undojoin | silent norm .
"     else
"         silent norm .
"     endif
"     if g:multi#state_manager.state.tick != b:changedtick
"         let self.undo_count += 1
"     endif
"     return [multi#util#new_area('normal')]
" endfunction
" function! Update_insert()
"     redraw
" endfunction

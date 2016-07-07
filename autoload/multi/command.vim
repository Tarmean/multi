func! s:apply_pos(pos, command, visual)
    call setpos(".", a:pos)
    if a:command == "."
        silent norm .
        " if !multi#successful()
        "     return
        " endif
    else
        exec "norm ".a:command
        call multi#update_pos_vars()
    endif
    return multi#new_area(a:visual)
endfunc
func! multi#command#apply_command(area, command)
    call multi#setup(a:area.cursor)
    if a:area.isVisual
        if a:command == "."
            norm .
            if !multi#successful()
                return
            endif
        else
            call setpos("'<", a:area.left)
            call setpos("'>", a:area.right)
            exec "norm gv".a:command
        endif
        call multi#update_pos_vars()
        return [multi#new_area(0)]
    else
        return [s:apply_pos(a:area.cursor, a:command, 0)]
    endif
endfunc
func! multi#command#apply_motion(area, motion)
    if a:area.isVisual
        let side = !has_key(a:area, "side") || !a:area.side
        if side
            let cur = "right"
            let alt = "left"
        else
            let cur = "left"
            let alt = "right"
        endif
        call multi#setup(a:area[cur])
        let new_area = s:apply_pos(a:area[cur], a:motion, 1)
        let shift = multi#compare_pos(a:area[alt], new_area.cursor)
        if side && shift < 1 || !side && shift > -1
            let new_area[alt] = a:area[alt]
            let cmp =multi#compare_pos(new_area.cursor, new_area[cur])
            let new_area[cur] =  cmp == -1 ? new_area[cur] : new_area.cursor
            let new_area.cursor = new_area[cur]
            let new_area.side = !side
        else
            let new_area[cur] = a:area[alt]
            let cmp = multi#compare_pos(new_area.cursor, new_area[alt])
            let new_area[alt] = cmp == -1 ? new_area[alt] : new_area.cursor
            let new_area.cursor = new_area[alt]
            let new_area.side = side
        endif
        return [new_area]
    else
        call multi#setup(a:area.cursor)
        return [s:apply_pos(a:area.cursor, a:motion, 0)]
    endif
endfunc

func! multi#command#bind_motion(area, motion)
    if a:area.isVisual
        let cur_pos = a:area.left
        let result = []
        while 1
            let old_pos = cur_pos
            call multi#setup(cur_pos)
            let new_area = s:apply_pos(cur_pos, a:motion, 0)
            let cur_pos = new_area.cursor
            if  multi#compare_pos(cur_pos, a:area.right) < 1 &&
               \multi#compare_pos(old_pos, cur_pos) == -1
               call add(result, new_area)
            else
                if len(result) > 0
                    return result
                else
                    return [new_area]
                endif
            endif
        endwhile
    else
        return [s:apply_pos(a:area.cursor, a:motion, 0)]
    endif
endfunc

func! multi#command#apply_textobject(area, text_object)
    call multi#setup(a:area.cursor)
    if a:area.isVisual
        let cur_pos = a:area.left
        let result = []
        while 1
            let old_pos = cur_pos
            let new_area = s:apply_pos(cur_pos, "g@".a:text_object, 1)
            let cur_pos = s:add_pos(new_area.right)
            let cmp = multi#compare_pos(new_area.cursor, a:area.right)
            if  cmp < 1 && 
                \multi#compare_pos(old_pos, cur_pos) == -1
               call add(result, new_area)
            else
                return result
            endif
        endwhile
    else
        return [s:apply_pos(a:area.cursor, "g@".a:text_object, 1)]
    endif
endfunc

func! s:add_pos(pos)
    let pos = deepcopy(a:pos)
    let pos[2] += 1
    if pos[2] > col([pos[1], "$"])
        let pos[1] += 1
        let pos[2] = 1
    endif
    return pos
endfunc

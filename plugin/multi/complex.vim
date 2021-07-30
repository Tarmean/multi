let multi#command#complex_motion = {}
function multi#command#complex_motion.normal(area, command)
    call multi#util#setup(a:area.cursor)
    silent norm .
    return [g:multi#state_manager.state.new]
endfunction
function multi#command#complex_motion.visual(area, command)
    let side = !has_key(a:area, "side") || !a:area.side
    if side                 
        let cur = "right"
        let alt = "left"
    else
         let cur = "left"
        let alt = "right"
    endif

    call multi#util#setup(a:area[cur], 1)
    silent norm .
    let new_area = g:multi#state_manager.state.new

    let shift = multi#util#compare_pos(a:area[alt], new_area.cursor)
    if side && shift < 1 || !side && shift > -1
        let new_area[alt] = a:area[alt]
        " let cmp = multi#util#compare_pos(new_area.cursor, new_area[cur])
        " let new_area[cur] =  cmp == -1 ? new_area[cur] : new_area.cursor
        let new_area[cur] =  new_area.cursor
        let new_area.side = !side
    else
        let new_area[cur] = a:area[alt]
        " let cmp = multi#util#compare_pos(new_area.cursor, new_area[alt])
        let new_area[alt] = new_area.cursor
        let new_area.side = side
    endif
    return [new_area]
endfunction
function multi#command#complex_motion.bind(area, command)
    call multi#util#setup_op()
    let op_command = 'g@v' . a:command
    call feedkeys(op_command, 'ix!')
    if a:area.visual == "visual_line"
        let right_border = deepcopy(a:area.right)
        let right_border[2] = 2147483647
    else
        let right_border = a:area.right
    endif

    let cur_pos = a:area.left
    let result = []
    if multi#command#check_self_movement(a:area, "norm! .")
        call add(result,multi#util#new_area('normal'))
    endif
    while 1
        let old_pos = cur_pos

        call multi#util#setup(cur_pos)
        norm! .
        let new_area = g:multi#state_manager.state.new
        let cur_pos = new_area.cursor
        echom cur_pos

        let check_in_area = multi#util#compare_pos(cur_pos[0:3], right_border) < 1
        let check_not_recursive = multi#util#compare_pos(old_pos[0:3], cur_pos[0:3]) == -1
        if  check_in_area && check_not_recursive
           call add(result, new_area)
        else
            if len(result) > 0
                return result
            else
                return [new_area]
            endif
        endif
    endwhile
endfunction

function multi#command#complex_motion.post()
    call multi#util#clean_op()
endfunction

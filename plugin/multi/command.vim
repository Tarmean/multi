let multi#command#overwrite = {}

let multi#command#simple_motion = {}
function multi#command#simple_motion.normal(area, command)
    call setpos('.', a:area.cursor)
    execute "silent norm " . a:command
    return [multi#util#new_area('normal')]
endfunction
function multi#command#simple_motion.visual(area, command)
    let side = !has_key(a:area, "side") || !a:area.side
    if side
        let cur = "right"
        let alt = "left"
    else
        let cur = "left"
        let alt = "right"
    endif

    call setpos('.', a:area[cur])
    execute "silent norm " . a:command
    let new_area = multi#util#new_area(a:area.visual)

    let shift = multi#util#compare_pos(a:area[alt], new_area.cursor)
    if side && shift < 1 || !side && shift > -1
        let new_area[alt] = a:area[alt]
        let new_area[cur] =  deepcopy(new_area.cursor)
        let new_area.side = !side
    else
        let new_area[cur] = a:area[alt]
        let new_area[alt] = deepcopy(new_area.cursor)
        let new_area.side = side
    endif

    return [new_area]
endfunction
function multi#command#simple_motion.bind(area, command)
    let cur_pos = a:area.left
    let result = []
    if multi#command#check_self_movement(a:area, "norm " . a:command)
        call add(result,multi#util#new_area('normal'))
    endif
    while 1
        let old_pos = cur_pos

        call setpos('.', cur_pos)
        exec "silent norm " . a:command
        let new_area = multi#util#new_area('normal')
        let cur_pos = new_area.cursor

        if a:area.visual == "visual_line"
            let right_border = deepcopy(a:area.right)
            let right_border[2] = 2147483647
        else
            let right_border = a:area.right
        endif

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
function! multi#command#check_self_movement(area, command)
    let start_pos = a:area.left
    function! s:movement_check() closure
        exec a:command
    endfunction
    call s:ensure_before_pos(start_pos, funcref("s:movement_check"))
    if start_pos  == getpos(".")
        return 1
    endif
    " call s:ensure_above_pos(start_pos, function("s:movement_check"))
    " if start_pos == getpos(".")
    "     return 1
    " endif
    return 0
endfunc
function! s:ensure_before_pos(pos, f)
    if a:pos[2] == 1
        let old_line = getline(a:pos[1])
        silent! undojoin|call setline(a:pos[1], " " . old_line)
    endif
    let lpos = copy(a:pos)
    if lpos[2] > 1
        let lpos[2] -= 1
    endif
    call multi#util#setup(lpos)
    let o = a:f()
    if a:pos[2] == 1
        silent! undojoin|call setline(a:pos[1], old_line)
        let curpos = g:multi#state_manager.state.moved ? g:multi#state_manager.state.new.cursor : getpos(".")
        let curpos[2] -= 1
        let curpos[3] -= 1
        call setpos('.', curpos)
    endif
    return o
endfunc
function! s:ensure_above_pos(pos, f)
    if a:pos[1] == 1
        let old_line = ""
    else
        let old_line = getline(a:pos[1]-1)
    endif
    let diff = a:pos[2] - len(old_line)
    if diff > 0
        if a:pos[1] == 1
            call append(a:pos[1]-1, repeat(" ", diff))|undojoin
        else
            call setline(a:pos[1]-1, old_line + repeat(" ", diff))|undojoin
        endif
    endif
    let lpos = copy(a:pos)
    if lpos[1] > 1
        let lpos[1] -= 1
    endif
    call multi#util#setup(lpos)
    let o = a:f()
    if diff > 0
        if a:pos[1] > 1
            call setline(a:pos[1]-1, old_line)|undojoin
        else
            0d|undojoin
        endif
    endif
    return o
endfunc

let multi#command#command = {"undo_count": 0}
function multi#command#command.pre(command)
    let g:multi#state_manager.state.repeat_command = a:command
    let self.undo_count = 0
endfunction
function multi#command#command.normal(area, command)
    call multi#util#setup(a:area.cursor)
    if self.undo_count > 1
        undojoin | exec "silent norm " . a:command
    else
        exec "silent norm " . a:command
    endif
    if g:multi#state_manager.state.tick != b:changedtick
        let self.undo_count += 1
    endif
    return [multi#util#new_area('normal')]
endfunction
function multi#command#command.visual(area, command)
    let tick = b:changedtick
    if self.undo_count > 1
        undojoin | call multi#util#apply_visual(a:area, a:command)
    else
        call multi#util#apply_visual(a:area, a:command)
    endif
    if g:multi#state_manager.state.tick != b:changedtick
        let self.undo_count += 1
    endif
    return [multi#util#new_area('normal')]
endfunction

let multi#command#textobj = {}
function multi#command#textobj.pre(command)
    call multi#util#setup_op()
endfunc
function multi#command#textobj.post()
    call multi#util#clean_op()
endfunc
function multi#command#textobj.normal(area, command)
    call multi#util#setup(a:area.cursor, 1)
    call multi#util#apply_op(a:command, 0, 0)
    return [g:multi#state_manager.state.new]
endfunction
function multi#command#textobj.visual(area, command)
    call multi#util#setup(a:area.cursor, 1)
    call multi#util#apply_op(a:command, 0, 0)
    return [g:multi#state_manager.state.new]
endfunction
function multi#command#textobj.bind(area, command)
    call multi#util#setup(a:area.cursor)
    let cur_pos = a:area.left
    let result = []
    while 1
        let old_pos = cur_pos

        call multi#util#setup(cur_pos, 1)
        call multi#util#apply_op(a:command, 0, 0)
        let new_area = g:multi#state_manager.state.new
        let cur_pos = deepcopy(new_area.cursor)
        let cur_pos[2] += 2
        if cur_pos[2] > col([cur_pos[1], "$"])
            let cur_pos[1] += 1
            let cur_pos[2] = 1
        endif

        if  multi#util#compare_pos(new_area.right, a:area.right) < 1 &&
            \multi#util#compare_pos(old_pos, cur_pos) == -1
           call add(result, new_area)
        else
            return result
        endif
    endwhile
endfunction

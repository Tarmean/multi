let multi#command#overwrite = {}

let multi#command#simple_motion = {}
function multi#command#simple_motion.normal(area, command)
    call setpos('.', a:area.cursor)
    execute "silent norm " . a:command
    return [multi#util#new_area(0)]
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
    let new_area = multi#util#new_area(1)

    let shift = multi#util#compare_pos(a:area[alt], new_area.cursor)
    if side && shift < 1 || !side && shift > -1
        let new_area[alt] = a:area[alt]
        let new_area[cur] =  new_area.cursor
        let new_area.side = !side
    else
        let new_area[cur] = a:area[alt]
        let new_area[alt] = new_area.cursor
        let new_area.side = side
    endif
    return [new_area]
endfunction
function multi#command#simple_motion.bind(area, command)
    let cur_pos = a:area.left
    let result = []
    while 1
        let old_pos = cur_pos

        call setpos('.', cur_pos)
        exec "silent norm " . a:command
        let new_area = multi#util#new_area(0)
        let cur_pos = new_area.cursor

        if  multi#util#compare_pos(cur_pos[0:3], a:area.right) < 1 &&
           \multi#util#compare_pos(old_pos[0:3], cur_pos[0:3]) == -1
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

let multi#command#command = {}
function multi#command#command.normal(area, command)
    call multi#util#setup(a:area.cursor)
    silent norm .
    return [multi#util#new_area(0)]
endfunction
function multi#command#command.visual(area, command)
    let tick = b:changedtick
    call setpos("'<", a:area.left)
    call setpos("'>", a:area.right)
    norm `<v`>
    exec "silent norm ".a:command
    return [multi#util#new_area(0)]
endfunction

let multi#command#textobj = {}
function multi#command#textobj.normal(area, command)
    call multi#util#setup(a:area.cursor, 1)
    silent norm .
    return [g:multi#state_manager.state.new]
endfunction
function multi#command#textobj.visual(area, command)
    call multi#util#setup(a:area.cursor)
    let cur_pos = a:area.left
    let result = []
    while 1
        let old_pos = cur_pos

        call multi#util#setup(cur_pos, 1)
        silent norm .
        let new_area = g:multi#state_manager.state.new
        let cur_pos = deepcopy(new_area.cursor)
        let cur_pos[2] += 1
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

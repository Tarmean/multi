function! multi#util#setup(old_pos, ...)
    if len(a:old_pos) == 4
        let g:multi#state_manager.state.old     = add(a:old_pos, a:old_pos[2])
    else
        let g:multi#state_manager.state.old     = a:old_pos
    endif
    call setpos('.', g:multi#state_manager.state.old)

    let g:multi#state_manager.state.moved         = 0
    let g:multi#state_manager.state.tick          = b:changedtick
    let g:multi#state_manager.state.expect_visual = a:0 ? a:1 : 0
endfunction

function! multi#util#new_area(visual)
    return {
           \"visual":   a:visual,
           \"cursor":   getcurpos(),
           \"left":     getpos("'["),
           \"right":    getpos("']"),
           \"reg":      getreg('"'),
           \}
endfunction

function! multi#util#test_op(type)
    let state = g:multi#state_manager.state
    if !state.expect_visual
        let mode = 'normal'
    else
        let mode = 'visual_' . a:type
    endif
    let state.new = multi#util#new_area(mode)
    if state.old == state.new.cursor
        let state.new.cursor = add(state.new.right, state.new.right[2])
    endif
    if a:type == 'char'
        let state.moved = multi#util#compare_pos(state.new.left, state.new.right) < 1 ? 1 : -1
    else
        let state.moved = 1
    endif
    " let g:a  = a:type ." ".string(state.old)." ". string(state.new) ." ".string(state.moved)
endfunction


function! multi#util#compare_pos(a, b)
    if a:a[1] < a:b[1]
        return -1
    elseif a:a[1] > a:b[1]
        return 1
    else
        return a:a[2] < a:b[2] ? -1 : a:a[2] == a:b[2] ? 0 : 1
    endif
endfunction

function! multi#util#in_block(a, b)
endfunction

function! multi#util#get_type()
    if g:multi#state_manager.cursors.visual != 'normal' &&
      \g:multi#state_manager.cursors.bind
      let type = 'bind'
    else
        let type = g:multi#state_manager.cursors.visual
    endif
    return type
endfunction

function! multi#util#apply_visual(area, command)
    if a:area.visual == 'visual_line'
        let visual_command = 'V'
    elseif a:area.visual == 'visual_block'
        let visual_command = ''
    else
        let visual_command = 'v'
    endif
    exec 'norm! ' . visual_command . "\<Esc>"
    call setpos("'<", a:area.left)
    call setpos("'>", a:area.right)
    exec 'silent norm gv'. a:command
endfunction
function! multi#util#setup_op()
    call setpos(".", g:multi#state_manager.cursors.cursors[0].left)
    let s:repeat_tick = g:repeat_tick
    let s:old_op = &opfunc
    set opfunc=g:multi#util#test_op
endfunction

function! multi#util#apply_op(command, interactive, inclusive)
    let op_command = 'g@' . (a:inclusive ? 'v' : '') . a:command
    if a:interactive
        call feedkeys(op_command, 'ix!')
    else
        exec "silent! norm ".op_command
    endif
endfunction
function! multi#util#clean_op()
    let g:repeat_tick = s:repeat_tick
    let &opfunc = s:old_op
endfunction


function! multi#util#cleanup()
    call multi#draw#reset()
endfunction

function! multi#util#callback(op)
    call g:multi#command#command.pre(".")
    call g:multi#state_manager.apply(g:multi#command#command, 'normal', '.', 0)
    call g:multi#state_manager.redraw()
    call multi#run()
endfunc
function! multi#util#phantom(f)
    let old_tick = b:changedtick
    let out = a:f()
    if old_tick != b:changedtick
        norm! u
    endif
    return out
endfunc

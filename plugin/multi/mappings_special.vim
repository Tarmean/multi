let multi#command#overwrite["j"] = {}
function multi#command#overwrite['j'].bind(area, command)
    let result = []
    for i in range(a:area.left[1], a:area.right[1])
        let cur = deepcopy(a:area)
        let cur.visual = 'normal'
        let cur.cursor = deepcopy(a:area.left)
        let cur.cursor[1] = i
        call add(cur.cursor, cur.cursor[2])
        call add(result, cur)
    endfor
    return result
endfunction

let multi#command#overwrite["o"] = {}
function! multi#command#overwrite['o'].visual(area, command)
    if has_key(a:area, "side")
        let a:area.side = !a:area.side
    else
        let a:area.side = 1
    endif
    return [a:area]
endfunction

let multi#command#overwrite['v'] = {'skip':1}
function multi#command#overwrite['v'].normal(area, command)
    let a:area.left   = deepcopy(a:area.cursor)
    let a:area.right  = deepcopy(a:area.cursor)
    let a:area.visual = 'visual_char'
    let a:area.side   = 0
    return [a:area]
endfunction
function multi#command#overwrite['v'].visual(area, command)
    if a:area.visual == 'visual_char'
        let a:area.cursor = deepcopy(a:area.left)
        let a:area.visual = 'normal'
    else
        let a:area.visual = 'visual_char'
    endif
    return [a:area]
endfunction

let multi#command#overwrite['V'] = {'skip':1}
function multi#command#overwrite['V'].normal(area, command)
    let a:area.left  = deepcopy(a:area.cursor)
    let a:area.right = deepcopy(a:area.cursor)
    let a:area.visual = 'visual_line'
    return [a:area]
endfunction
function multi#command#overwrite['V'].visual(area, command)
    if a:area.visual == 'visual_line'
        let a:area.cursor = deepcopy(a:area.left)
        let a:area.visual = 'normal'
    else
        let a:area.visual = 'visual_line'
    endif
    return [a:area]
endfunction

let multi#command#overwrite[''] = {'skip':1}
function multi#command#overwrite[''].normal(area, command)
    let a:area.left  = deepcopy(a:area.cursor)
    let a:area.right = deepcopy(a:area.cursor)
    let a:area.visual = 'visual_block'
    return [a:area]
endfunction

function multi#command#overwrite[''].visual(area, command)
    if a:area.visual == 'visual_block'
        let a:area.cursor = deepcopy(a:area.left)
        let a:area.visual = 'normal'
    else
        let a:area.visual = 'visual_block'
    endif
    return [a:area]
endfunction

" let multi#command#overwrite['f'] = multi#command#complex_motion
let multi#command#overwrite['/'] = deepcopy(multi#command#complex_motion)

let multi#command#overwrite['J'] = multi#command#command


" function! multi#command#overwrite['/'].post()
"     call multi#util#clean_op()
"     noh
" endfunction


let multi#command#overwrite['.'] = {'skip':1, "side_effect":1}
function multi#command#overwrite['.'].pre(command)
    if g:multi#state_manager.cursors.visual != 'normal'
        let self.skip = 1
        let g:multi#state_manager.cursors.bind = !g:multi#state_manager.cursors.bind
        return 2
    else
        " echo b:changedtick g:repeat_tick string(&opfunc) g:repeat_sequence
        let self.skip = 0
    endif
endfunction
" function multi#command#overwrite['.'].post()
"     " let g:repeat_tick = b:changedtick
" endfunction
function multi#command#overwrite['.'].normal(area, command)
    call setpos(".", a:area.cursor)
    execute "norm ".g:multi#state_manager.state.repeat_command
    return [a:area]
endfunction
let multi#command#overwrite['u'] = {'skip': 1}
function multi#command#overwrite['u'].pre(command)
    if g:multi#state_manager.cursors.visual == 'normal'
        norm! u
    endif
endfunction
function! multi#command#overwrite['u'].normal(area, command)
    let col = max([col([a:area.cursor[1], "$"]) - 1, 1])
    if a:area.cursor[2] > col
        let a:area.cursor[2] = col
    endif
    return [a:area]
endfunction

let multi#command#overwrite[''] = {'skip': 1}
function multi#command#overwrite[''].pre(command)
    norm! 
endfunction

let multi#command#overwrite[''] = {'skip': 1}
function multi#command#overwrite[''].pre(command)
    if g:multi#state_manager.cursors.bind == 1
        let g:multi#state_manager.cursors.bind = 0
        let self.keep_cur = 1
    else
        let self.keep_cur = 0
    endif
    let self.reg = ''
    let self.reg_stash = []
endfunction
function multi#command#overwrite[''].normal(area, command)
    if self.keep_cur
        return [a:area]
    endif
    call add(self.reg_stash, a:area.reg)
    if a:area.reg[len(a:area.reg)-1] != "\n"
        let a:area.reg .= "\n"
    endif
    let self.reg .= a:area.reg
    return []
endfunction
function multi#command#overwrite[''].visual(area, command)
    if self.keep_cur
        return [a:area]
    endif
    let a:area.cursor = a:area.left
    let a:area.visual = 'normal'
    return [a:area]
endfunction
function multi#command#overwrite[''].post()
    call setreg('"', self.reg)
    let g:multi#state_manager#yank_stash = self.reg_stash
endfunction

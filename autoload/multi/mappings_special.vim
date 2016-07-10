let multi#command#overwrite['o'] = {}
function multi#command#overwrite['o'].visual(area, command)
    if has_key(a:area, "side")
        let a:area.side = !a:area.side
    else
        let a:area.side = 1
    endif
    return [a:area]
endfunction

let multi#command#overwrite['v'] = {'skip':1}
function multi#command#overwrite['v'].normal(area, command)
    let a:area.left   = a:area.cursor
    let a:area.right  = a:area.cursor
    let a:area.visual = 1
    let a:area.side   = 0
    return [a:area]
endfunction
function multi#command#overwrite['v'].visual(area, command)
    let a:area.cursor = a:area.left
    let a:area.visual = 0
    return [a:area]
endfunction

let multi#command#overwrite['V'] = {'skip':1}
function multi#command#overwrite['V'].normal(area, command)
    let a:area.left   = [0, a:area.cursor[1], 1, 0]
    let a:area.right   = [0, a:area.cursor[1], 2147483647, 0]
    let a:area.visual = 1
    return [a:area]
endfunction
function multi#command#overwrite['V'].visual(area, command)
    let a:area.left   =  [0, a:area.left[1], 1, 0]
    let a:area.right   = [0, a:area.right[1], 2147483647, 0]
    return [a:area]
endfunction

let multi#command#overwrite['/'] = {}
let multi#command#overwrite['/'].normal = multi#command#complex_motion.normal
let multi#command#overwrite['/'].visual = multi#command#complex_motion.visual
let multi#command#overwrite['/'].bind = multi#command#complex_motion.bind
function multi#command#overwrite['/'].pre()
    call feedkeys('g@v/', 'ix')
endfunction


let multi#command#overwrite['.'] = {'skip': 1}
function multi#command#overwrite['.'].pre()
    let g:multi#state_manager.cursors.bind = !g:multi#state_manager.cursors.bind
endfunction

let multi#command#overwrite['u'] = {'skip': 1}
function multi#command#overwrite['u'].pre()
    norm! u
endfunction


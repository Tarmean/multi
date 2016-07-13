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

let multi#command#overwrite['f'] = multi#command#complex_motion
let multi#command#overwrite['/'] = multi#command#complex_motion
let multi#command#overwrite['y'] = {}
let multi#command#overwrite['y'].visual = multi#command#command.visual


let multi#command#overwrite['.'] = {'skip': 1}
function multi#command#overwrite['.'].pre(command)
    let g:multi#state_manager.cursors.bind = !g:multi#state_manager.cursors.bind
endfunction

let multi#command#overwrite['u'] = {'skip': 1}
function multi#command#overwrite['u'].pre(command)
    norm! u
endfunction

let multi#command#overwrite[''] = {'skip': 1}
function multi#command#overwrite[''].pre(command)
    norm! 
endfunction

let multi#command#overwrite[''] = {'skip': 1}
function multi#command#overwrite[''].pre(command)
    let self.reg = ''
endfunction
function multi#command#overwrite[''].normal(area, command)
    if a:area.reg[len(a:area.reg)-1] != "\n"
        let a:area.reg .= "\n"
    endif
    let self.reg .= a:area.reg
    return []
endfunction
function multi#command#overwrite[''].visual(area, command)
    let a:area.cursor = a:area.left
    let a:area.visual = 'normal'
    return [a:area]
endfunction
function multi#command#overwrite[''].post()
    call setreg('"', self.reg)
endfunction

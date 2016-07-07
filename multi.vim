function! multi#new_cursor(area)
    let result = {
                \"apply": function('multi#apply'),
                \"update": function('multi#update_cursor'),
                \}
    call result.update(a:area)
    return result
endfunction

function! multi#setup(old_pos)
    let s:stack.old = a:old_pos
    let s:stack.moved = 0
    let s:stack.changed = 0
endfunction

function! multi#draw(area)
    let top = line("w0")
    let bottom = line("w$")
    if a:area.isVisual
        let top_on_screen = a:area.left[1] >= top
        let bottom_on_screen = a:area.right[1] <= bottom
        if top_on_screen || bottom_on_screen
            call s:draw_range(a:area.left, a:area.right)
        endif
    else
        if top <= a:area.cursor[1] && a:area.cursor[1] <= bottom
            call add(s:stack.matches, matchaddpos(s:normal_group, [[a:area.cursor[1], a:area.cursor[2]]]))
        endif
    endif
endfunction
function! multi#reset_visual()
    for entry in s:stack.matches
        silent! call matchdelete(entry)
    endfor
    let s:stack.matches = []
endfunction
let s:visual_group = 'Visual'
let s:normal_group = 'Cursor'
function! s:draw_range(left, right)
    " fuck vimscript
    let diff = a:right[1] - a:left[1]
    if diff == 0
        let id = matchaddpos(s:visual_group, [[a:left[1], a:left[2], a:right[2]-a:left[2]+1]])
        call add(s:stack.matches, id)
    else
        let id = matchaddpos(s:visual_group, [[a:left[1], a:left[2], 2147483647-a:left[2]]])
        call add(s:stack.matches, id)
        if diff > 1
            for i in range(a:left[1]+1, a:right[1]-1)
                let id = matchaddpos(s:visual_group, [i])
                call add(s:stack.matches, id)
            endfor
        endif
        let id = matchaddpos(s:visual_group, [[a:right[1], 1, a:right[2]]])
        call add(s:stack.matches, id)
    endif
endfunction

function! multi#compare_pos(a, b)
    if a:a[1] < a:b[1]
        return -1
    elseif a:a[1] > a:b[1]
        return 1
    else
        return a:a[2] < a:b[2] ? -1 : a:a[2] == a:b[2] ? 0 : 1
    endif
endfunction

function! multi#update_pos_vars(...)
    if a:0
        let s:stack.left    = getpos("'<")
        let s:stack.right   = getpos("'>")
    else
        let s:stack.left    = getpos("'[")
        let s:stack.right   = getpos("']")
    endif
    let s:stack.pos     = getpos(".")
    let s:stack.changed = s:stack.tick != b:changedtick
endfunc

function! multi#test_op(type)
    call multi#update_pos_vars()
    if s:stack.old == s:stack.pos
        let s:stack.pos = s:stack.right
        " if s:stack.old[1] == s:stack.right[1]
        "     let s:stack.pos[2] = min([s:stack.pos[2]+1, col([s:stack.pos[1], "$"])-1])
        " endif
    endif
    let s:stack.moved = multi#compare_pos(s:stack.left, s:stack.right) 
    let s:stack.moved = s:stack.moved == -1 ? 1 : 2
endfunc

"Cases:
" simple action, x                -> feed keys
" operator, d                     -> release control until buffer changed or cursor
"                                    halt, then repeat
" interactive action, easy align  -> release control until cursor halt then
"                                    repeat
" simple movement, l              -> capture command, run in dummy operator and reapeat after cursor
"                                    moved
" interactive movement, vim sneak -> release control until cursor halt or
"                                    moved and repeat
let g:multi_bindings = {
                        \"cursor": {
                                   \"command":{},
                                   \"motion":{"ö":1, "/":1},
                                   \"textobject":{},
                                   \},
                        \"area":   {
                                   \"command":{},
                                   \"motion":{"ö":1, "/":1},
                                   \"textobject":{},
                                   \},
                        \}


func! s:has_special()
    let vis = s:stack.stacks[-1].cursors[0].isVisual
    if vis
        let base = g:multi_bindings.area
    else
        let base = g:multi_bindings.cursor
    endif

    if has_key(base.command, s:stack.command)
        let C = base.command[s:stack.command]
        let input = s:stack.command
        let Default = s:apply_command
    elseif has_key(base.textobject, s:stack.command)
        let C = base.textobject[s:stack.command]
        let input = s:stack.command
        let Default = s:apply_textobject
    elseif has_key(base.motion, s:stack.command)
        let s:stack.moved = 0
        let C = base.motion[s:stack.command]
        let input = "g@v".s:stack.command
        if s:bind
            let Default = s:bind_motion
        else
            let Default = s:apply_motion
        endif
    else
        return 0
    endif

    if type(C) == 0
        call feedkeys(input, "ix")
        if s:stack.moved
            let s:stack.command = "."
            return Default
        else
            let s:stack.command = ""
            return 1
        endif
    elseif type(C) == 2
        return C
    elseif type(C) == 4
        if has_key(C, 'on_input')
            let result = C.on_input(s:stack)
        endif
        if has_key(C, 'on_map')
            return C.on_map
        else
            return result
        endif
   endif
endfunc
function! multi#new_area(isVisual)
    return {
           \"isVisual": a:isVisual,
           \"cursor":   s:stack.pos,
           \"left":     s:stack.left,
           \"right":    s:stack.right,
           \"reg":      getreg('"'),
           \}
endfunction
func! multi#successful()
    return s:stack.moved || s:stack.tick != b:changedtick
endfunc
func! multi#callback()
    set updatetime=4000
    augroup CursorFeedback
        au!
    augroup END
    call s:stack.apply(s:func)
    let s:stack.command = ""
    call Head()
endfunc
func! multi#init(...)
    call s:stack.init(a:0?a:1:0)
    call Head()
endfunc

let s:apply_command    = function("multi#command#apply_command")
let s:apply_textobject = function("multi#command#apply_textobject")
let s:apply_motion     = function("multi#command#apply_motion")
let s:bind_motion      = function("multi#command#bind_motion")


func! Head()
    call s:stack.redraw()
    set opfunc=multi#test_op
    let s:stack.command = ""
    let s:bind = 0
    set nohlsearch
    while 1
        let g:repeat_tick = -1
        echo s:bind? ". ":"" .s:stack.command
        let s = getchar()
        let s:stack.command .= nr2char(s)
        if s:stack.command == "."
            let s:stack.command = ""
            let s:bind = 1
            continue
        endif
        if s:stack.command == "" || s:stack.command == ""
            silent call multi#reset_visual()
            call setpos(".", s:stack.stacks[-1].cursors[-1].cursor)
            return
        endif

        let Res = s:has_special()
        if type(Res) == 2
            let Func = Res
        elseif Res == 1
            unlet Res
            continue
        else
            let s:stack.moved = 0
            " we need to be able to differentiate between movements,
            " textobjects and commands. Do this by first trying movements only
            " and then check if they start with a or i
            exec "norm g@".s:stack.command
            if s:stack.moved == 0
                unlet Res
                continue
            else

                if s:stack.command[0] == 'i'||s:stack.command[0] == 'a'
                    let Func = s:apply_textobject
                else
                    if !s:bind
                        let Func = s:apply_motion
                    else
                        let Func = s:bind_motion
                    endif
                endif
                " let s:stack.tick = b:changedtick
                " if s:stack.isVisual()
                "     exec "norm " . s:stack.command
                " else
                "     exec "norm gv" . s:stack.command
                " endif
                " call multi#update_pos_vars()
                " if s:stack.changed
                "     call feedkeys("u", "ix")
                "     call s:stack.apply(s:apply_command, s:stack.command, 1)
                " endif
            endif
        endif
        call s:stack.apply(Func, s:stack.command, 0)
        let s:bind = 0
        call s:stack.redraw()
        redraw!
        let s:stack.command = ""
        unlet Res

        " redraw!
    endwhile
endfunc
function! multi#get_command()
    return s:stack.command
endfunction
xnoremap . :call multi#init(1)<cr>
" onoremap . <esc>:call multi#init(0)
let s:stack = multi#stack_manager#new()

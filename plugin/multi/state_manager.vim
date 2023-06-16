let g:multi#state_manager = {
          \"matches": [],
          \"cursors": {},
          \"state": {
              \ 'tick':         -1,
              \ 'moved':         0,
              \ 'expect_visual': 0,
              \ 'new':          {},
              \ 'old':          [],
              \ 'yank':          {'yanked':0},
              \ 'finished': 0,
          \}
          \}
func! multi#state_manager.new()
   return deepcopy(self)
endfunc
func! multi#state_manager.to_normal()
    let self.cursors.visual = 'n'
    for c in self.cursors.cursors
        let c.visual = 0
    endfor
endfunc


func! multi#state_manager.init(...)
    let visual = a:0 ? a:1 : 'n'
    let area = {
           \"visual":   visual,
           \"cursor":   getcurpos(),
           \"left":     getpos("'<"),
           \"right":    getpos("'>"),
           \"reg":      getreg('"'),
           \}
    let self.cursors = multi#cursors#new()   " reset cursorss
    call multi#cursors#add(self.cursors, area, visual) " add initial cursor
    call self.redraw()
endfunc

func! multi#state_manager.test_command_failed(input)
    let self.state.finished = 0
    " Some inputs cause an error that would drop all future inputs
    " When found, clear the input queue
    " This is a heuristic that drops some inputs which could be completed into
    " something valid.
    " l - movement that completes user-operators
    "  - cancel pending inputs, getchar, etc
    " \<Plug>MultiFinished - sentinel, if this input survives we are still live
    " try
    "     call multi#util#phantom({-> feedkeys(a:input . "l\<Plug>MultiFinished", 'x') })
    "  endtry
    call multi#util#phantom({-> feedkeys(a:input . "\<Plug>MultiFinished", 'x') })
    redraw!
    return self.state.finished == 0
endfunc
noremap <silent> <Plug>MultiFinished :call g:multi#state_manager.set_finished()<cr>
func! multi#state_manager.set_finished()
    let self.state.finished = 1
endfunc
func! multi#state_manager.apply(func, type, motion, backwards)
    call clearmatches()
    let result = multi#cursors#new()
    " Go down, left to right for motions because that makes them easier to chain
    " Go up, right to left for commands because that makes it easier to avoid overlaps
    if a:backwards
        let range = range(len(self.cursors.cursors)-1, 0, -1)
    else
        let range = range(0, len(self.cursors.cursors)-1)
    endif
    let old_line = -1
    let cur_line_cursors = []
    let old_max_col = -1
    let old_max_line = line("$")

    for i in range
        call setreg('"', self.cursors.cursors[i].reg)
        let new_areas = a:func[a:type](self.cursors.cursors[i], a:motion)
        " When a cursor is on the same line as other cursors and inserts or
        " deletes characters we have to fix the columns of all cursors to its
        " right. This is essentially a very simplistic reimplementation of marks
        "
        " this requires that commands with side effect can't chain to create
        " multiple cursors, which so far holds true
        if a:backwards && len(new_areas) > 0
            let line = new_areas[0].cursor[1]
            let changed_line_flag = 0
            if line("$") != old_max_line
                " bottom to top. If a cursor adds a new line,
                " push all existing cursors down a line
                let delta = line("$") - old_max_line
                for cursor in result.cursors
                    let cursor.cursor[1] += delta
                    let cursor.left[1]   += delta
                    let cursor.right[1]  += delta
                endfor
            endif
            if self.cursors.cursors[i].cursor[1] == line && old_line == line
                " right to left, same line. If a cursor adds
                " characters, push the existing cursors on the same line to the right
                let new_col  = col([self.cursors.cursors[i].cursor[1], "$"])
                let delta = new_col - old_max_col
                if  delta != 0
                    for cursor in result.cursors
                        if cursor.cursor[1] == line
                            let cursor.cursor[2] += delta
                            let cursor.cursor[4] += delta
                        endif
                        if cursor.left[1] == line
                            let cursor.left[2]   += delta
                        endif
                        if cursor.right[1] == line
                            let cursor.right[2]  += delta
                        endif
                    endfor
                    let old_max_col = new_col
                endif

                if new_areas[-1].cursor[1] != line
                    let changed_line_flag = 1
                endif
            else
                let changed_line_flag = 1
            endif
            if changed_line_flag
                " at least one cursor changed the line, keep track of the new
                " cursors on this line
                let old_line = new_areas[-1].cursor[1]
                let old_max_col = col([new_areas[-1].cursor[1], "$"])
            endif
            let old_max_line = line("$")
            call reverse(new_areas)
        endif
        for area in new_areas
            " XXX: for commands this currently doesn't merge overlapping
            " cursors. Join and reverse first, then merge?
            call multi#cursors#add(result, area, area.visual, a:backwards)
        endfor
    endfor
    if a:backwards
        " to avoid side effect overlap we went up, right to left and the
        " cursors are ordered in reverse
        call reverse(result.cursors)
    endif
    let self.cursors = result
    if !empty(g:multi#state_manager#yank_stash)
        let lold = len(g:multi#state_manager#yank_stash)
        let lnew = len(self.cursors.cursors)
        for i in range(min([lnew, lold]))
            let self.cursors.cursors[i].reg = g:multi#state_manager#yank_stash[i]
        endfor
        if lnew > lold && lold != 1
            for i in range(lold, lnew-1)
                let self.cursors.cursors[i].reg = ""
            endfor
        endif
        let g:multi#state_manager#yank_stash = []
    endif
endfunc

func! multi#state_manager.redraw()
    call multi#draw#reset()
    call setpos(".", [0, 0, 0, 0])
    let visual = self.cursors.visual
    for cursor in self.cursors.cursors
        if visual ==# 'visual_char'
                call multi#draw#area(cursor.left, cursor.right)
        elseif visual ==# 'visual_line'
                call multi#draw#line(cursor.left, cursor.right)
        elseif visual ==# 'visual_block'
                call multi#draw#block(cursor.left, cursor.right)
        else
            call multi#draw#cursor(cursor.cursor)
        endif
    endfor
    call setpos(".", self.cursors.cursors[-1].cursor)
    redraw
endfunc
let g:multi#state_manager#yank_stash = []

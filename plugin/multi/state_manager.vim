func! multi#state_manager#new()
   return {
          \"matches": [],
          \"cursors": {},
          \"state": {
              \"tick":         -1,
              \"moved":         0,
              \"expect_visual": 0,
              \"new":          {},
              \"old":          [],
              \"yank":          {'yanked':0},
          \},
          \"init":   function('g:multi#state_manager#init'),
          \"apply":  function('g:multi#state_manager#apply'),
          \"redraw": function('g:multi#state_manager#redraw'),
          \}
endfunc
              " \"changed":       0,

func! multi#state_manager#init(...) dict
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

func! multi#state_manager#apply(func, type, motion, backwards) dict
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
            if old_line == line
                " at least one new cursor was on the previous line - fixing time
                let new_col  = col([self.cursors.cursors[i].cursor[1], "$"])
                let delta = new_col - old_max_col
                if  delta != 0
                    " the line length changed, we go right to left so shift
                    " everything right of the new cursor delta columns to the right
                    for cursor in cur_line_cursors
                        let cursor.cursor[2] += delta
                        let cursor.cursor[4] += delta
                        let cursor.left[2]   += delta
                        let cursor.right[2]  += delta
                    endfor
                    let old_max_col = new_col
                endif

                if new_areas[-1].cursor[1] == line
                    " all new cursors are still on the same line, just track
                    " them as well
                    call extend(cur_line_cursors, new_areas)
                else
                    let changed_line_flag = 1
                endif
            else
                let changed_line_flag = 1
            endif
            if changed_line_flag
                " at least one cursor started a new line, so check which
                " cursors we now have to track instead
                let old_line = new_areas[-1].cursor[1]
                let cur_line_cursors = []
                for entry in new_areas
                    if entry.cursor[1] == old_line
                        call add(cur_line_cursors, entry)
                    endif
                endfor
                let old_max_col = col([new_areas[-1].cursor[1], "$"])
            endif
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
endfunc

func! multi#state_manager#redraw() dict
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

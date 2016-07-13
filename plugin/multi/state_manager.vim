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
    if a:backwards
        let range = range(len(self.cursors.cursors)-1, 0, -1)
    else
        let range = range(0, len(self.cursors.cursors)-1)
    endif
    for i in range
        call setreg('"', self.cursors.cursors[i].reg)
        let new_areas = a:func[a:type](self.cursors.cursors[i], a:motion)
        for area in new_areas
            call multi#cursors#add(result, area, area.visual, a:backwards)
        endfor
    endfor

    if a:backwards
        call reverse(result.cursors)
    endif
    let self.cursors = result
    if len(self.cursors.cursors) > 0
        call self.redraw()
    endif
endfunc

func! multi#state_manager#redraw() dict
    call multi#draw#reset()
    " let top = line("w0")
    " let bottom = line("w$")
    call setpos(".", [0, 0, 0, 0])
    let visual = self.cursors.visual
    for cursor in self.cursors.cursors
        if visual ==# 'visual_char'
            " let top_fits    = cursor.left[1] >= top
            " let bottom_fits = cursor.right[1] <= bottom
            " if top_fits || bottom_fits
                call multi#draw#area(cursor.left, cursor.right)
            " endif
        elseif visual ==# 'visual_line'
                call multi#draw#line(cursor.left, cursor.right)
        elseif visual ==# 'visual_block'
                call multi#draw#block(cursor.left, cursor.right)
        else
            " if top <= cursor.cursor[1] && cursor.cursor[1] <= bottom
            call multi#draw#cursor(cursor.cursor)
            " endif
        endif
    endfor
    call setpos(".", self.cursors.cursors[-1].cursor)
    redraw!
endfunc

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
let g:multi#state_manager = multi#state_manager#new()

func! multi#state_manager#init(...) dict
    let visual = a:0 ? a:1 : 0
    let area = {
           \"visual": visual,
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
    let result = multi#cursors#new()
    if a:backwards
        let range = range(len(self.cursors.cursors)-1, 0, -1)
    else
        let range = range(0, len(self.cursors.cursors)-1)
    endif
    for i in range
        let new_areas = a:func[a:type](self.cursors.cursors[i], a:motion)
        for area in new_areas
            call multi#cursors#add(result, area, area.visual)
        endfor
    endfor
    let self.cursors = result
    call self.redraw()
endfunc

func! multi#state_manager#redraw() dict
    call multi#draw#reset()
    call setpos(".", [0, 0, 0, 0])
    let top = line("w0")
    let bottom = line("w$")
    let visual = self.cursors.visual
    for cursor in self.cursors.cursors
        if visual
            let top_fits    = cursor.left[1] >= top
            let bottom_fits = cursor.right[1] <= bottom
            if top_fits || bottom_fits
                call multi#draw#area(cursor.left, cursor.right)
            endif
        else
            if top <= cursor.cursor[1] && cursor.cursor[1] <= bottom
                call multi#draw#cursor(cursor.cursor)
            endif
        endif
    endfor
    redraw!
endfunc

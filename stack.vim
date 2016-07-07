func! multi#stack#new()
    return {
                \"update":  function('multi#stack#apply'),
                \"apply":   function('multi#stack#apply'),
                \"add":     function('multi#stack#add'),
                \"draw":     function('multi#stack#draw'),
                \"cursors": [],
                \"isVisual": 0,
                \}
endfunc

let MOTION = 0
let TEXT_OBJECT = 1
let FUNCTION = 2
let COMMAND = 3

func! multi#stack#apply(func, motion, backwards) dict
    let result = multi#stack#new()
    if a:backwards
        let range = range(len(self.cursors)-1, 0, -1)
    else
        let range = range(0, len(self.cursors)-1)
    endif
    for i in range
        let new_areas = a:func(self.cursors[i], a:motion)
        for area in new_areas
            call result.add(area)
        endfor
    endfor
    return result
endfunc
func! multi#stack#draw() dict
    for cursor in self.cursors
        call multi#draw(cursor)
    endfor
endfunc

func! multi#stack#add(area) dict
        let self.isVisual = self.isVisual || a:area.isVisual
    if len(self.cursors) == 0 
        call add(self.cursors, a:area)
        return
    endif

    let highest = self.cursors[-1]
    if !a:area.isVisual
        " let notVis_vis = highest.isVisual && multi#compare_pos(highest.right, a:area.cursor) == -1
        if !highest.isVisual && multi#compare_pos(highest.cursor, a:area.cursor) == -1
            call add(self.cursors, a:area)
        endif
    else
        " let vis_notVis = !highest.isVisual && && multi#compare_pos(highest.cursor, a:area.left) == -1
        " if vis_notVis 
        "     call add(self.cursors, a:area)
        " endif
        if highest.isVisual
            if multi#compare_pos(highest.right, a:area.left) == -1
                call add(self.cursors, a:area)
            elseif multi#compare_pos(highest.right, a:area.right) == -1
                let highest.right = a:area.right
            endif
        endif
    endif
endfunc

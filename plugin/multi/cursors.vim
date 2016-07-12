func! multi#cursors#new()
    return {
                \"cursors": [],
                \"visual": 0,
                \"bind": 0,
                \}
endfunc

func! multi#cursors#add(cursors, area, visual, ...)
    let skip_check = a:0 ? a:1 : 0
    let a:cursors.visual = a:cursors.visual || a:visual
    if len(a:cursors.cursors) == 0 || skip_check
        call add(a:cursors.cursors, a:area)
        return
    endif

    let highest = a:cursors.cursors[-1]
    if !a:cursors.visual
        if multi#util#compare_pos(highest.cursor, a:area.cursor) == -1
            call add(a:cursors.cursors, a:area)
        endif
    else
        if multi#util#compare_pos(highest.right, a:area.left) == -1
            call add(a:cursors.cursors, a:area)
        elseif multi#util#compare_pos(highest.right, a:area.right) == -1
            let highest.right = a:area.right
        endif
    endif
endfunc

function! multi#draw#reset()
    for entry in g:multi#state_manager.matches
        silent! call matchdelete(entry)
    endfor
    let g:multi#state_manager.matches = []
endfunction

let s:visual_group = 'WildMenu'
let s:normal_group = 'Cursor'
let s:visual_newline_group = 'DiffChange'
" let s:visual_newline_group = 'CursorLine'
" '#665c54'
function! multi#draw#area(left, right)
    let upper_line = a:left[1]
    let lower_line = a:right[1]

    if lower_line == upper_line
        call add(g:multi#state_manager.matches, matchaddpos("DiffAdd", [[lower_line, a:left[2], a:right[2]-a:left[2]+1]]))
    else
        if a:left[2] != 1
            call add(g:multi#state_manager.matches, matchaddpos("DiffText", [[upper_line, a:left[2], 2147483647-a:left[2]]]))
            let upper_line += 1
        endif
        if a:right[2] != 2147483647
            " breaks on empty lines only when starting at 1
            call add(g:multi#state_manager.matches, matchaddpos(s:visual_group, [[lower_line, 1, a:right[2]]]))
            let lower_line -= 1
        endif
        if upper_line <= lower_line
            " XXX: is it faster to match the area with \%< and \%> only or to do
            " it in one go like this?
            let pattern_1 = '\%>' . (upper_line-1) . 'l\%<' . (lower_line+1).'l'
            call add(g:multi#state_manager.matches, matchadd('ErrorMsg', pattern_1))
        endif
        let newline_pattern = '\n\%>' . a:left[1] . 'l\%<'.(a:right[1]+1) .'l'
        call add(g:multi#state_manager.matches, matchadd(s:visual_newline_group, newline_pattern))
    endif
endfunction

function! multi#draw#cursor(cursor)
    call add(g:multi#state_manager.matches, matchaddpos(s:normal_group, [[a:cursor[1], a:cursor[2]]]))
endfunction

let g:multi#state_manager = multi#state_manager#new()

function! multi#init(visual)
    set opfunc=multi#util#test_op
    set nohlsearch
    call g:multi#state_manager.init(a:visual)
    call multi#run()
endfunction

function! multi#run()
    let input = ""
    while 1
        echo g:multi#state_manager.cursors.bind? ". ":"" .input
        let c = getchar()
        let input .= nr2char(c)

        let type = multi#util#get_type()

        let fallback  = 1
        if has_key(g:multi#command#overwrite, input)
            let command = g:multi#command#overwrite[input]
            let direction = has_key(command, 'side_effect') ? command.side_effect : 0
            if has_key(command, 'pre')
                call command.pre()
            endif
            if has_key(command, type)
                let fallback = 0
            elseif has_key(command, 'skip') && command.skip
                let input = ''
                continue
            endif
        endif

        if fallback
            call multi#util#setup(g:multi#state_manager.cursors.cursors[0].cursor)
            exec "norm g@".input
            if g:multi#state_manager.state.moved == -1
                let input = ""
                continue
            elseif g:multi#state_manager.state.moved == 1
                let direction = 0
                if input[0] == 'i' || input[0] == 'a'
                    let command = g:multi#command#textobj
                else
                    let command = g:multi#command#simple_motion
                endif
            else
                let g:multi#state_manager.state.tick = b:changedtick
                exec "norm ".input
                if b:changedtick != g:multi#state_manager.state.tick
                    norm! u
                    let direction = 1
                    let command = g:multi#command#command
                else
                    redraw
                    continue
                endif
            endif
        endif

        call g:multi#state_manager.apply(command, type, input, direction)

        if has_key(command, 'post')
            call command['post']()
        endif
        let input = ""
    endwhile
endfunction



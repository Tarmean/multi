let g:multi#state_manager = multi#state_manager#new()

function! multi#init(visual)
    set nohlsearch
    call g:multi#state_manager.init(a:visual)
    call multi#run()
    augroup MultiChecks
        au!
        au InsertEnter * let g:multi#state_manager.state.insert_enter = 1
    augroup END
endfunction

function! multi#run()
    let input = ""
    while 1
        set opfunc=multi#util#test_op
        echo g:multi#state_manager.cursors.bind? ". ":"" .input
        let c = getchar()
        let input .= nr2char(c)

        let type = multi#util#get_type()

        let fallback  = 1
        if has_key(g:multi#command#overwrite, input)
            let command = g:multi#command#overwrite[input]
            if has_key(command, 'pre')
                let end =  command.pre(input)
                if end == 1
                    return
                endif
            endif
            let direction = has_key(command, 'side_effect') ? command.side_effect : 0
            if has_key(command, type)
                let fallback = 0
            elseif match(type, 'visual_') == 0 && has_key(command, 'visual')
                let type = 'visual'
                let fallback = 0
            elseif has_key(command, 'skip') && command.skip
                let input = ''
                call g:multi#state_manager.redraw()
                continue
            endif
        endif

        if fallback
            let old_tick = b:changedtick
            let movement = 0
            let g:multi#state_manager.state.insert_enter = 0
            if type == 'bind'
                let g:multi#state_manager.state.moved = 0
                exec 'norm g@'.input
                if g:multi#state_manager.state.moved != 0
                    let movement = 1
                endif
            else
                if type == 'normal'
                    let old = [getcurpos(), getreg('"')]
                    exec "norm ".input
                    let new = [getcurpos(), getreg('"')]
                else
                    norm v
                    let old = [getpos("'<"), getpos("'>"), getreg('"')]
                    exec "norm v".input
                    norm 
                    let new = [getpos("'<"), getpos("'>"), getreg('"')]
                endif
                let movement =  old != new
            endif
            let new_tick = b:changedtick
            if g:multi#state_manager.state.insert_enter
                if old_tick != new_tick
                    norm! u
                endif
                call multi#insert#setup(input, type)
                let input = ""
                continue
            endif

            if old_tick != new_tick
                norm! u
                let direction = 1
                let command = g:multi#command#command
            elseif movement
                let direction = 0
                if input[0] == 'i' || input[0] == 'a'
                    let command = g:multi#command#textobj
                else
                    let command = g:multi#command#simple_motion
                endif
            else
                call g:multi#state_manager.redraw()
                continue
            endif
            if has_key(command, 'pre')
                call command.pre(input)
            endif
            if match(type, 'visual_') == 0 && !has_key(command, type)
                let type = 'visual'
            endif
        endif

        call g:multi#state_manager.apply(command, type, input, direction)

        if has_key(command, 'post')
            call command['post']()
        endif
        let input = ""
        if len(g:multi#state_manager.cursors.cursors) == 0
            call multi#util#cleanup()
            break
        endif
    endwhile
endfunction



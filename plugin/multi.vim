vnoremap <silent> . <c-c>: call multi#init(visualmode() ==# 'v' ? 'visual_char' : visualmode() ==# 'V' ? 'visual_line' : 'visual_block')<cr>.
" nnoremap . :call multi#init('normal')

let g:multi#state_manager = multi#state_manager.new()

function! multi#init(visual)
    let g:multi#state_manager.state.repeat_command = '.'
    call g:multi#state_manager.init(a:visual)
    augroup MultiChecks
        au!
        if has("nvim")
            au TextYankPost * let g:multi#state_manager.state.yank.yanked = 1|let g:multi#state_manager#yank_stash = []
        endif
        au InsertEnter * let g:multi#state_manager.state.insert_enter = 1
    augroup END
    try
        call multi#run()
    finally
        call multi#util#cleanup()
    endtry
endfunction

function! multi#run()
    let input = ""
    while 1
        let g:repeat_tick = -1
        echo g:multi#state_manager.cursors.bind? ". " . input :"" .input
        " echo b:changedtick
        " echo g:repeat_tick
        let c = getchar()
        if l:input != '' && nr2char(c) == "\<esc>"
            let input = ""
            redraw!
            continue
        endif
        let input .= nr2char(c)

        let type = multi#util#get_type()

        let fallback  = 1
        if has_key(g:multi#command#overwrite, input)
            let command = g:multi#command#overwrite[input]
            let end = 0
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
            elseif type=='bind' && has_key(command, 'normal')
                let type = 'normal'
            elseif has_key(command, 'skip') && command.skip || end == 2
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
                let g:repeat_tick=-1
                let g:multi#state_manager.state.moved = 0
                call multi#util#setup_op()
                call multi#util#apply_op(input, 0, 0)
                call multi#util#clean_op()
                if g:multi#state_manager.state.yank.yanked
                    let input = ""
                    redraw
                    continue
                elseif b:changedtick != old_tick
                    let input = ""
                    let g:multi#state_manager.cursors.bind = 0
                    norm! u
                    redraw
                    continue
                else
                    let movement = g:multi#state_manager.state.moved
                endif
            else
                let g:multi#state_manager.state.yank.yanked = 0
                if type == 'normal'
                    let old = getcurpos()
                    let old_sel = [getpos("'["), getpos("']")]
                    exec "norm ".input
                    " check that there wasn't a failed text object that moved
                    " the cursor
                    let new_sel = [getpos("'["), getpos("']")]
                    let new = getcurpos()
                    let movement =  old != new && old_sel == new_sel
                else
                    norm v
                    let old = [getpos("'<"), getpos("'>"), getreg('"')]
                    exec "norm v".input
                    norm! 
                    let new = [getpos("'<"), getpos("'>"), getreg('"')]
                    let movement =  old != new
                endif
            endif
            let new_tick = b:changedtick
            if g:multi#state_manager.state.insert_enter
                if old_tick != new_tick
                    norm! u
                endif
                call multi#insert#setup(input, type)
                let input = ""
                redraw
                continue
            endif

            if old_tick != new_tick
                norm! u
                let direction = 1
                let command = g:multi#command#command
                if type == 'normal' && exists("g:repeat_tick") && g:repeat_tick == new_tick 
                    " see [NOTE: repeat.vim]
                    "
                    let input = g:repeat_sequence
                endif
            elseif g:multi#state_manager.state.yank.yanked
                let command = g:multi#command#command
            elseif movement
                let direction = 0
                if input[0] == 'i' || input[0] == 'a'
                    let command = g:multi#command#textobj
                else
                    let command = g:multi#command#simple_motion
                endif
            else
                " if g:multi#state_manager.test_command_failed(input)
                "     let input = ""
                " endif
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
        else
            call g:multi#state_manager.redraw()
        endif
    endwhile
endfunction




" [NOTE: repeat.vim]
"
" Example:
"
"     w|ord
"     > ysiwf      - surround in word function
"     > function: foo        - text input for function name
"     |foo(word)
"
" This is a custom operator that records its own interactive inputs. The
" timeline is
"
" - We record 'ysiwf'
" - surround.vim takes over and records 'foo'
" - on replay, we repeat 'ysiwf' and surround.vim asks the user for a seperate function
"   names on each cursor
"
"   This isn't what we wanted! But there is no good userspace way to record this input,
"   macros break in a myriad use cases. Solution: Many plugins already stash their
"   recorded input in repeat.vim so the normal '.' for repeat works. Check if there is
"   an (up-to-date) repeat.vim recording, and try to replay that instead.

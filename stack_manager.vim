func! multi#stack_manager#new()
   return {
          \"stacks": [],
          \"old": [],
          \"matches": [],
          \"tick": -1,
          \"moved": 0,
          \"changed": 0,
          \"init":   function('multi#stack_manager#init'),
          \"apply":  function('multi#stack_manager#apply'),
          \"redraw":  function('multi#stack_manager#redraw'),
          \"isVisual":  function('multi#stack_manager#is_visual'),
          \}
endfunc

func! multi#stack_manager#init(...) dict
    let visual = a:0 ? a:1 : 0
    call multi#update_pos_vars(visual)
    let self.stacks = [multi#stack#new()]   " reset stacks
    let area = multi#new_area(visual)
    let self.stacks[0].add(area) " add initial cursor
endfunc
func! multi#stack_manager#apply(func, motion, backwards) dict
    let self.stacks[0] = self.stacks[-1].apply(a:func, a:motion, a:backwards)
endfunc
func! multi#stack_manager#redraw() dict
    call multi#reset_visual()
    call self.stacks[-1].draw()
    redraw!
endfunc
func! multi#stack_manager#is_visual() dict
    return len(self.stacks) == 0 ? 0 :self.stacks[0].isVisual
endfunc

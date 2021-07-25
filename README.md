# Multi.vim

Experimental multiple cursor plugin for vim.   

- Place a multi-cursor on each motion target in a selection
- Use all of vim with multi-cursors (unless this specific part of vim breaks in obscure and impossible to fix ways)


[![Multi.vim](https://img.youtube.com/vi/2XLL16MUl3Q/0.jpg)](https://www.youtube.com/watch?v=2XLL16MUl3Q)

`.` in visual mode is for-each. Here are some usage examples:

#### Basic Usage

    V.f/r\

- `V`  - select line
- `.`  - for each
- `f/` - '/'-character
- `r\` - replace-with '\\'

So `.` is an operator in visual mode. It accepts a movement (or text-object), and places a cursor on each target of this movement in the selected area.

This plugin does not re-implement vim for multi-cursor-mode. Instead it just executes what you type on the first cursor, tries to guess what kind of input this is (change buffer/move cursor/etc), and repeats it for each cursor.

This means that many inputs, including plugins like surround.vim, just work out of the box with multiple cursors.

#### Other Plugins and Text Objects

    vip.a"cs"'

- `vip` - select in paragraph
- `.a"` - foreach around " (selects each "-pair)
- `cs"'` - change surrounding " to '

#### Place cursors on pattern

    vip./foo<cr>~

- `vip` - select in paragraph
- `./foo<cr>` - foreach occurence `foo`
- `~` - make first character upper-case



#### Notes

Insert mode works, but auto-complete doesn't. This isn't fundamental but the naive implementation caused performance issues. An alternative would be to mirror block-mode so that the result is copied to all cursors after leaving insert mode, or to abuse autocommands in ways that could get in the way of other plugins. Please leave an issue if the lack of autocomplete causes problems.

There are various fundamental restrictions. For example, plugins that consume their own arbitrary-length input do not repeat well without repeat.vim, especially in visual mode.  
surround.vim has a `<tag></tag>` surround action. In normal mode, repeat.vim can be used so we only have to enter the tag name once. But in visual mode repeat.vim does not work and the user must type the tag name for each cursor.  
This restriction is mirrored elsewhere - generally interactive commands are either awkward or repeated for each cursor.

It is a bit tricky to recognize if the first character in a region should be targeted by a motion. We can try to execute the motion one character before the region, but what if it's the start of the line/file? The current trick is to briefly mutate the buffer to add a space and hide the undo-node. But directly after the user used 'undo', this unfortunately doesn't work. As a result vim marks the file as dirty and creates a noop undo node.


Occasionally the input gets stuck, for instance if you 'fy' without a 'y' on the same line. This type of soft-failure is hard to detect without breaking various stateful plugins so the test is currently disabled. Press '<esc>' to clear the input queue.

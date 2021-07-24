Multi.vim is a loop which accepts input and executes two steps:

- turn the input into a command
- apply the command to each cursor

The following command types exist:

- Custom command based on configured mapping
- The following heuristics produce different commands
  - input enters insert mode
  - input changes the buffer and uses repeat.vim
  - input changes the buffer
  - input yanks text
  - input moves the cursor
  - during 'bind' mode, command completes a text-object 
  - input is stuck, e.g. executing it causes an error that would swallow future inputs

If your command doesn't cleanly fit in these heuistics you probably need to configure a custom mapping.


Cursors are simulated via syntax highlighting regexes

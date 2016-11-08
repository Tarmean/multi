# Multi.vim

Experimental multiple cursor plugin for vim.   

`.` in visual mode toggles multi mode. Motions and text objects in multi mode place cursor on all objects. Heuristics act as a fallback for unknown actions so even interactive plugins like vim-surround are automatically supported.

It depends on multiple rarely used Vim features and has to work around a multitude of bugs. This plugin generally works with the newest Vim version and can break in obscure and hard to fix ways if some patch is missing. Also note that neovim is required to track yank events.

[![Multi.vimj](https://img.youtube.com/vi/2XLL16MUl3Q/0.jpg)](https://www.youtube.com/watch?v=2XLL16MUl3Q)

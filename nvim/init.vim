set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

" Fix Neovim 0.11 issue https://github.com/nvim-lualine/lualine.nvim/issues/1312
highlight StatusLine cterm=NONE gui=NONE
highlight StatusLineNC cterm=NONE gui=NONE
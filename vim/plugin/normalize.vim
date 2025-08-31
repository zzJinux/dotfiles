if !has('nvim')
  " From Neovim 0.4.4 *nvim-defaults*
  if has('syntax') && !exists('g:syntax_on')
    syn enable
  endif
  if has('autocmd')
    filetype plugin indent on
  endif
  se autoindent
  se autoread
  se background=dark
  se backspace=indent,eol,start
  se belloff=all
  se nocompatible
  se complete-=i
  se cscopeverbose
  se display=lastline
  se encoding=utf-8
  se fillchars=vert:│,fold:·
  se formatoptions=tcqj
  se fsync
  se history=10000
  se hlsearch
  se incsearch
  se langnoremap
  se nolangremap
  se laststatus=2
  se listchars=tab:>\ ,trail:-,nbsp:+
  se nrformats=bin,hex
  se ruler
  se sessionoptions-=options
  se shortmess-=S
  se shortmess+=F
  se showcmd
  se sidescroll=1
  se smarttab
  se tabpagemax=50
  se tags=./tags;,tags
  se ttimeoutlen=10
  se ttyfast
  se viminfo+=!
  se wildmenu
  se wildoptions=tagfile
  runtime! ftplugin/man.vim
  packadd! matchit

endif

se mouse=a

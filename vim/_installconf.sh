#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(script_dir)"

ohai vim:installconf
execute mkdir -p ~/.vim
execute symlink_safe "$SCRIPT_DIR/vimdir/normalize.vim" ~/.vim/normalize.vim
execute symlink_safe "$SCRIPT_DIR/gvimrc" ~/.gvimrc
execute symlink_safe "$SCRIPT_DIR/vimrc" ~/.vimrc

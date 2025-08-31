#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(script_dir)"

ohai vim:installconf
execute mkdir -p ~/.vim ~/.vim/plugin
execute symlink_safe "$SCRIPT_DIR/gvimrc" ~/.gvimrc
execute symlink_safe "$SCRIPT_DIR/vimrc" ~/.vimrc
execute symlink_safe "$SCRIPT_DIR/plugin/drafts.vim" ~/.vim/plugin/drafts.vim
execute symlink_safe "$SCRIPT_DIR/plugin/normalize.vim" ~/.vim/plugin/normalize.vim

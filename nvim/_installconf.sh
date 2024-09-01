#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(script_dir)"

ohai nvim:installconf
execute mkdir -p ~/.config/nvim
execute symlink_safe "$SCRIPT_DIR/init.vim" ~/.config/nvim/init.vim

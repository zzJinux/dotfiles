#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(_script_dir)"

ohai jetbrains:installconf
symlink_safe "$SCRIPT_DIR/ideavimrc" ~/.ideavimrc

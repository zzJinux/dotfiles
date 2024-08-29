#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(script_dir)"

ohai tmux:installconf
execute mkdir -p ~/.config/tmux
execute symlink_safe "$SCRIPT_DIR/tmux.conf" ~/.config/tmux/tmux.conf

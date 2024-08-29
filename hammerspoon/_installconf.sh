#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(script_dir)"

ohai hammerspoon:installconf
execute mkdir -p ~/.hammerspoon
execute symlink_safe "$SCRIPT_DIR/init.lua" ~/.hammerspoon/init.lua

#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(script_dir)"

ohai karabiner:installconf
execute mkdir -p ~/.config/karabiner/assets
execute symlink_safe "$SCRIPT_DIR/complex_mods" ~/.config/karabiner/assets/complex_modifications

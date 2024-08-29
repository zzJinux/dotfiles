#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(script_dir)"

ohai macos:installconf
execute mkdir -p ~/Library/KeyBindings && \
  execute symlink_safe "$SCRIPT_DIR/DefaultKeyBinding.dict" ~/Library/KeyBindings/DefaultKeyBinding.dict
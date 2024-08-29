#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(script_dir)"

ohai git:installconf
execute mkdir -p ~/.config/git
for f in config ignore; do
  execute symlink_safe "$SCRIPT_DIR/$f" ~/.config/git/"$f"
done

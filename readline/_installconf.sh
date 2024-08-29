#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(script_dir)"

ohai readline:installconf
execute symlink_safe "$SCRIPT_DIR"/inputrc ~/.inputrc

#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(script_dir)"

ohai terraform:installconf
execute mkdir -p ~/.terraform.d/plugin-cache
execute touch ~/.terraform.d/plugin-cache/.placeholder
execute symlink_safe "$SCRIPT_DIR/terraformrc" ~/.terraformrc

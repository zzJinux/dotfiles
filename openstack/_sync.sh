#!/usr/bin/env bash
set -eu

SCRIPTS_DIR=$(_script_dir)

mkdir -p ~/.config/openstack &&
  symlink_safe "$SCRIPTS_DIR/configconv" ~/.config/openstack/configconv &&
  :
mkdir -p ~/.local/share/bash-completion/completions &&
  symlink_safe "$SCRIPTS_DIR/completion.bash" ~/.local/share/bash-completion/completions/osc &&
  symlink_safe "$SCRIPTS_DIR/completion.bash" ~/.local/share/bash-completion/completions/osce &&
  :
mkdir -p ~/.local/bin &&
  symlink_safe "$SCRIPTS_DIR/bin/openstack" ~/.local/bin/openstack &&
  symlink_safe "$SCRIPTS_DIR/bin/os" ~/.local/bin/os &&
  :
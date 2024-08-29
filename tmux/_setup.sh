#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"

ohai 'tmux:setup Install tpm plugins'
if [ -e ~/.config/tmux/plugins/tpm ]; then
  execute git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
  execute ~/.config/tmux/plugins/tpm/bin/install_plugins
fi

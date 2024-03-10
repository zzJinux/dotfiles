#!/usr/bin/env bash
: "${SCRIPTS_DIR:="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"}"

mkdir -p ~/.config/openstack \
  && ln -sf "$SCRIPTS_DIR/configconv" ~/.config/openstack/configconv
mkdir -p ~/.local/share/bash-completion/completions \
  && ln -sf "$SCRIPTS_DIR/completion.bash" ~/.local/share/bash-completion/completions/osc \
  && ln -sf "$SCRIPTS_DIR/completion.bash" ~/.local/share/bash-completion/completions/osce
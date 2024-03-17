#!/usr/bin/env bash
set -eu

: "${SCRIPT_DIR:="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"}"

extra_configs=()
if [ -e "$SCRIPT_DIR/private_includes" ]; then
  read -r -d '' -a extra_configs < <(cat "$SCRIPT_DIR/private_includes") || [ "$extra_configs" ]
fi

mkdir -p "$DOTFILES/.staging/.config/aerospace"
cat "$SCRIPT_DIR/aerospace.toml" "${extra_configs[@]}" \
  >"$DOTFILES/.staging/.config/aerospace/aerospace.toml"
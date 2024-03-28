#!/usr/bin/env bash
set -eu

: "${DOTFILES}"

SCRIPT_DIR="$(_script_dir)"

for f in bash_logout bash_profile bashrc; do
  symlink_safe "$SCRIPT_DIR/$f" "$HOME/.$f"
done

DEST="${HOME}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

for f in bash_completion bashenv; do
  sed "s|:PH_DOTFILES:|${DOTFILES}|g" <"$SCRIPT_DIR/$f" | write_safe "$DEST/.$f"
done
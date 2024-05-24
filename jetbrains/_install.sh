#!/usr/bin/env bash
set -eu

echoerr() { echo "$@" >&2; }

create_symlink_safe() {
  local source="$1"
  local target="$2"
  if [ -e "$target" ]; then
    if [ -L "$target" ]; then
      old_src=$(readlink "$target")
      if [ "$old_src" = "$source" ]; then
        echoerr "symlink: $target already points to $source"
        return 0
      fi
      echoerr "symlink: $target points to $old_src"
      echoerr "symlink: removing existing symlink: $target"
      rm "$target"
    elif [ -f "$target" ]; then
      echoerr "symlink: backing up existing file: $target"
      mv "$target" "$target.bak"
    else
      echoerr "symlink: $target is unknown type, remove it manually"
      return 1
    fi
  fi
  ln -sv "$source" "$target"
}

: "${DOTFILES}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

for f in ideavimrc; do
  create_symlink_safe "$SCRIPT_DIR/$f" "$HOME/.$f"
done
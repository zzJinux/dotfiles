#!/usr/bin/env bash
set -eu

echoerr() { echo "$@" >&2; }

write_naive() {
  cat >"$1"
}

write_safe() {
  local dest="$1"
  if [ -e "$dest" ]; then
    if [ -L "$dest" ]; then
      old_src=$(readlink "$dest")
      echoerr "symlink: $dest points to $old_src"
      echoerr "symlink: removing existing symlink: $dest"
      rm "$dest"
    elif [ -f "$dest" ]; then
      echoerr "symlink: backing up existing file: $dest"
      mv "$dest" "$dest.bak"
    else
      echoerr "symlink: $dest is unknown type, remove it manually"
      return 1
    fi
  fi
  cat >"$dest"
}

write=write_naive
DEST="${DOTFILES}/.staging"
if [ "${1-}" = "--direct" ]; then
  write=write_safe
  DEST="${HOME}"
fi

: "${DOTFILES}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

sed "s|:PH_DOTFILES:|${DOTFILES}|g" <"$SCRIPT_DIR/zshenv" | "$write" "$DEST/.zshenv"

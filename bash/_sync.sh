#!/usr/bin/env bash
set -eu

# string formatters
if [[ -t 1 ]]
then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_bblue="$(tty_escape 94)"
tty_yellow="$(tty_escape 33)"
tty_reset="$(tty_escape 0)"
loginfo() { echo "${tty_bblue}$*${tty_reset}" >&2; }
logerror() { echo "${tty_yellow}$*${tty_reset}" >&2; }

symlink_safe() {
  local source="$1"
  local target="$2"
  if [ -e "$target" ]; then
    if [ -L "$target" ]; then
      old_src=$(readlink "$target")
      if [ "$old_src" = "$source" ]; then
        loginfo "symlink_safe: skip: $target already points to $source"
        return 0
      fi
      loginfo "symlink_safe: $target points to $old_src"
      loginfo "symlink_safe: removing existing symlink: $target"
      rm "$target"
    elif [ -f "$target" ]; then
      loginfo "symlink_safe: backing up existing file: $target"
      mv "$target" "$target.bak"
    else
      logerror "symlink_safe: $target is unknown type, remove it manually"
      return 1
    fi
  fi
  ln -sv "$source" "$target"
}

write_safe() {
  local dest="$1"
  if [ -e "$dest" ]; then
    if [ -L "$dest" ]; then
      old_src=$(readlink "$dest")
      loginfo "write_safe: $dest points to $old_src"
      loginfo "write_safe: removing existing symlink: $dest"
      rm "$dest"
    elif [ -f "$dest" ]; then
      loginfo "write_safe: backing up existing file: $dest"
      mv "$dest" "$dest.bak"
    else
      logerror "write_safe: $dest is unknown type, remove it manually"
      return 1
    fi
  fi
  echo writing to "$dest"
  cat >"$dest"
}

: "${DOTFILES}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

for f in bash_logout bash_profile bashrc; do
  symlink_safe "$SCRIPT_DIR/$f" "$HOME/.$f"
done

DEST="${HOME}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

for f in bash_completion bashenv; do
  sed "s|:PH_DOTFILES:|${DOTFILES}|g" <"$SCRIPT_DIR/$f" | write_safe "$DEST/.$f"
done
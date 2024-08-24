#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"

dir_bin() {
  echo "$1/bin"
}
dir_man1() {
  echo "$1/share/man/man1"
}
dir_man5() {
  echo "$1/share/man/man5"
}

: "${HOMEBREW_PREFIX:=$(brew --prefix)}"

local_bin=$(dir_bin ~/.local)
local_man1=$(dir_man1 ~/.local)
local_man5=$(dir_man1 ~/.local)
mkdir -p "$local_bin" "$local_man1" "$local_man5"

link_bin() {
  local name=$1
  local src_prefix=${2:-$HOMEBREW_PREFIX}
  local src_name=${3:-$name}

  symlink_safe "$src_prefix/bin/$src_name" "$local_bin/$name"
}

link_man1() {
  local name=$1
  local src_prefix=${2:-$HOMEBREW_PREFIX}
  local src_name=${3:-$name}

  symlink_safe "$src_prefix/share/man/man1/$src_name.1" "$local_man1/$name.1"
}

link_man5() {
  local name=$1
  local src_prefix=${2:-$HOMEBREW_PREFIX}
  local src_name=${3:-$name}

  symlink_safe "$src_prefix/share/man/man5/$src_name.5" "$local_man5/$name.5"
}

for name in man apropos whatis manpath; do
  link_bin $name "$HOMEBREW_PREFIX/opt/man-db" g$name
  link_man1 $name "$HOMEBREW_PREFIX/opt/man-db" g$name
done
link_man5 manpath "$HOMEBREW_PREFIX/opt/man-db" gmanpath

link_bin curl "$HOMEBREW_PREFIX/opt/curl"
link_man1 curl "$HOMEBREW_PREFIX/opt/curl"
link_bin curl-config "$HOMEBREW_PREFIX/opt/curl"
link_man1 curl-config "$HOMEBREW_PREFIX/opt/curl"

link_bin ls "$HOMEBREW_PREFIX" gls
link_man1 ls "$HOMEBREW_PREFIX" gls

link_bin date "$HOMEBREW_PREFIX" gdate
link_man1 date "$HOMEBREW_PREFIX" gdate

link_bin sed "$HOMEBREW_PREFIX" gsed
link_man1 sed "$HOMEBREW_PREFIX" gsed
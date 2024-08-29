#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(script_dir)"

ohai 'macos:setup Write defaults'
execute "$SCRIPT_DIR/defaults.sh"

ohai 'macos:setup Symlink tools from Homebrew'
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

link_bin find "$HOMEBREW_PREFIX" gfind
link_man1 find "$HOMEBREW_PREFIX" gfind
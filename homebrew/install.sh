#!/usr/bin/env bash
# shellcheck disable=SC2043
set -eu

mkdir -p ~/.local/bin
mkdir -p ~/.local/share/man/{man1,man5}

packagedir="$HOMEBREW_PREFIX/opt/man-db"

for name in man apropos whatis mandb manpath; do
  ln -sf "$packagedir/bin/g${name}" ~/.local/bin/$name
  ln -sf "$packagedir/share/man/man1/g${name}.1" ~/.local/share/man/man1/$name
done

for name in manpath; do
  ln -sf "$packagedir/share/man/man5/g${name}.1" ~/.local/share/man/man5/$name
done
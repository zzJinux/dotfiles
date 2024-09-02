#!/usr/bin/env bash

set -eu

tmpfile=$(mktemp)
rm -rf ~/.terminfo
for t in iterm2 vscode; do
  "$HOMEBREW_PREFIX/opt/ncurses/bin/infocmp" -x "$t" >> "$tmpfile"
done

/usr/bin/tic -x "$tmpfile" && rm "$tmpfile"

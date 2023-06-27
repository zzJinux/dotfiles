#!/usr/bin/env bash

app_bundle=/Applications/MacVim.app
if ! [ -e "$app_bundle" ]; then
  >&2 echo 'Please install MacVim.app'
  exit 1
fi

# MacVim executables
mkdir -p ~/.local/bin
ln -fs "$app_bundle/Contents/bin/"* ~/.local/bin/

# MacVim manpages
mkdir -p ~/.local/share/man/man1
ln -fs "$app_bundle/Contents/Resources/vim/runtime/doc/"*.1 ~/.local/share/man/man1/

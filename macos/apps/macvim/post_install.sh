#!/usr/bin/env bash

app_bundle=/Applications/MacVim.app
if ! [ -e "$app_bundle" ]; then
  >&2 echo 'Please install MacVim.app'
  exit 1
fi

# MacVim executables
mkdir -p ~/.local/bin
for path in "$app_bundle/Contents/bin/"*; do
  new_path=~/.local/bin/"$(basename "$path")"
  rm -f "$new_path"
  cat >"$new_path" <<EOF
#!/bin/sh
TERM=xterm-256color exec "$path" "\$@"
EOF
  chmod +x "$new_path"
done

# MacVim manpages
mkdir -p ~/.local/share/man/man1
ln -fs "$app_bundle/Contents/Resources/vim/runtime/doc/"*.1 ~/.local/share/man/man1/

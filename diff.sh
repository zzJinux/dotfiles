#!/usr/bin/env bash

quote() {
  builtin printf %q "$1"
}

src=.staging
dest=$HOME

find "$src" -type f -exec bash -c '! cmp --quiet "$3/${1#"$2/"}" "$1"' - '{}' "$src" "$dest" \; -print \
| fzf --ansi --preview 'f={};'"git diff --color=always --no-index $(quote "$dest")/\${f#$(quote "$src")/} {}"
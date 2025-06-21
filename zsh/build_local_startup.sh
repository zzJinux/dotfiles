#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(_script_dir)"

# Shell completion
outf="$SCRIPT_DIR/__local/completion.zsh"
if [ -f "$outf" ]; then
  mv "$outf" "$outf.bak"
fi
mkdir -p "$(dirname "$outf")"
touch "$outf"

for module_path in "$DOTFILES"/*; do
  module_name="$(basename "$module_path")"
  shell_completion="$module_path/_config/shell_completion"
  [ -x "$shell_completion" ] && {
    echo "# $module_name"
    "$shell_completion" --zsh
    echo
  } >>"$outf"
done

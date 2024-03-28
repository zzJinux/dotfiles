#!/usr/bin/env bash
set -eu

: "${DOTFILES}"

SCRIPT_DIR="$(_script_dir)"

for f in bash_logout bash_profile bashrc; do
  symlink_safe "$SCRIPT_DIR/$f" "$HOME/.$f"
done

DEST="${HOME}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

for f in bash_completion bashenv; do
  sed "s|:PH_DOTFILES:|${DOTFILES}|g" <"$SCRIPT_DIR/$f" | write_safe "$DEST/.$f"
done


# bash-completion compat scripts {{{
name_skip_list=(
  '000_bash_completion_compat.bash'
  brew
  brew-services
  git-prompt.sh
  python-argcomplete
)

name_rename_list=(
  aws aws_bash_completer
  git git-completion.bash
  hub hub.bash_completion.sh
  ninja ninja-completion.sh
)


comp_src_dir="$HOMEBREW_PREFIX/etc/bash_completion.d"
comp_dest_dir="$HOME/.local/share/bash-completion-sys"

if [ -e "$comp_dest_dir" ]; then
  rm -rf "$comp_dest_dir"
fi
mkdir -p "$comp_dest_dir"
for f in "$comp_src_dir"/*; do
  name="${f##*/}"

  for skip in "${name_skip_list[@]}"; do
    if [[ "$name" == "$skip" ]]; then
      continue 2
    fi
  done

  for ((i = 0; i < ${#name_rename_list[@]}; i += 2)); do
    cmd="${name_rename_list[i]}"
    match="${name_rename_list[i + 1]}"
    if [[ "$name" == "$match" ]]; then
      name="$cmd"
      break
    fi
  done

  symlink_safe "$f" "$comp_dest_dir/$name"
done

# homebrew completion
write_safe "$comp_dest_dir/brew" <<EOF
source "$comp_src_dir/brew"
source "$comp_src_dir/brew-services"
EOF
# }}}
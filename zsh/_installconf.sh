#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(_script_dir)"

ohai zsh:installconf
for f in zprofile zshrc zlogin zlogout zimrc p10k.zsh; do
  symlink_safe "$SCRIPT_DIR/$f" ~/".$f"
done

gen() {
  echo '# Generated by dotfiles'
  sed "s|:PH_DOTFILES:|${DOTFILES}|g" <"$SCRIPT_DIR/$1"
}

if ! grep -q '^# Generated by dotfiles' ~/.zshenv 2>/dev/null; then
  gen zshenv | write_safe ~/.zshenv
elif [[ ~/.zshenv -ot "$SCRIPT_DIR/zshenv" ]]; then
  gen zshenv >~/.zshenv
fi

#!/usr/bin/env bash

# string formatters
if [[ -t 1 ]]
then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
# tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
# tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

ohai() {
  printf "${tty_blue}build>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

execute() {
  if ! "$@"; then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"; do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

: "${SCRIPTS_DIR:="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"}"
: "${MODULES_DIR:="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"}"
DOTFILES="$MODULES_DIR"
export DOTFILES

staging_dir="${SCRIPTS_DIR}/.staging"

: "${MODULES_DIR}"/

execute rm -rf "${staging_dir}"
execute mkdir -p "${staging_dir}"
dotf_path=${PWD}
if [ "${dotf_path}" != "${dotf_path#"${HOME}"}" ]; then
  # Replace $HOME with tilde
  dotf_path='~'"${dotf_path#"${HOME}"}"
fi

ohai 'local binaries'
execute mkdir -p "${staging_dir}"/.local/bin
for f in "${MODULES_DIR}"/bin/*; do
  execute cp "$f" "${staging_dir}"/.local/bin/
done

ohai vim
execute mkdir -p "${staging_dir}"/.vim
execute cp "${MODULES_DIR}"/vim/vimdir/normalize.vim "${staging_dir}"/.vim/
execute cp "${MODULES_DIR}"/vim/gvimrc "${staging_dir}"/.gvimrc
execute cp "${MODULES_DIR}"/vim/vimrc "${staging_dir}"/.vimrc

ohai neovim
execute mkdir -p "${staging_dir}"/.config/nvim
execute cp "${MODULES_DIR}"/nvim/init.vim "${staging_dir}"/.config/nvim

ohai git
execute mkdir -p "${staging_dir}"/.config/git
execute cp "${MODULES_DIR}"/git/config "${MODULES_DIR}"/git/ignore "${staging_dir}"/.config/git/

ohai hammerspoon
execute mkdir -p "${staging_dir}"/.hammerspoon
execute cp "${MODULES_DIR}"/hammerspoon/init.lua "${staging_dir}"/.hammerspoon/

ohai jetbrains
execute cp "${MODULES_DIR}"/jetbrains/ideavimrc "${staging_dir}"/.ideavimrc

ohai karabiner
execute mkdir -p "${staging_dir}"/.config/karabiner/assets/complex_modifications
execute cp "${MODULES_DIR}"/karabiner/complex_mods/* "${staging_dir}"/.config/karabiner/assets/complex_modifications

ohai readline
execute cp "${MODULES_DIR}"/readline/inputrc "${staging_dir}"/.inputrc

source "${MODULES_DIR}/homebrew/shlogin"

ohai bash
for f in bash_profile bashrc bash_logout bashenv bash_completion; do
  cat "${MODULES_DIR}"/"bash/${f}" \
    | sed "s|:PH_DOTFILES:|${dotf_path}|g" \
    | sed "s|:PH_HOMEBREW_PREFIX:|${HOMEBREW_PREFIX}|g" \
    >".staging/.${f}"
done

ohai tmux
execute mkdir -p "${staging_dir}"/.config/tmux
execute cp "${MODULES_DIR}"/tmux/tmux.conf "${staging_dir}"/.config/tmux/tmux.conf

ohai terraform
execute mkdir -p "${staging_dir}"/.terraform.d/plugin-cache
execute touch "${staging_dir}"/.terraform.d/plugin-cache/.placeholder
execute cp "${MODULES_DIR}"/terraform/terraformrc "${staging_dir}"/.terraformrc

ohai macos
ohai macos:aerospace
execute "${MODULES_DIR}"/macos/aerospace/_build.sh
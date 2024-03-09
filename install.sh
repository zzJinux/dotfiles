#!/bin/bash

set -u

# Some functions copied from https://github.com/Homebrew/install/blob/master/install.sh

_main() {
  # Requirements: macOS Ventura, Apple Silicon, Internet available
  # This script shall be idempotent.

  # Allow inlining command substitutions
  # shellcheck disable=SC2312

  : "${SCRIPTS_DIR:="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"}"
  : "${MODULES_DIR:="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"}"
  DOTFILES="$MODULES_DIR"

  ohai 'Install dotfiles in the home directory'
  execute "$SCRIPTS_DIR/build.sh"
  execute "$SCRIPTS_DIR/apply.sh"

  have_sudo_access

  source "$MODULES_DIR/homebrew/shlogin"

  set_homebrew_prefix

  # Homebrew install
  # It will install Command Line Tools if not installed
  if ! [ -x "$HOMEBREW_PREFIX/bin/brew" ]; then
    ohai 'Install Homebrew'
    execute bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  else
    ohai 'Homebrew is already installed'
  fi
  source "$MODULES_DIR/homebrew/shlogin"
  ohai 'Install Homebrew packages'
  "$HOMEBREW_PREFIX/bin/brew" bundle --verbose --file "$MODULES_DIR/homebrew/Brewfile"

  ohai 'Install vim-plug plugins'
  if [ -e ~/.vim/autoload/plug.vim ]; then
    execute curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
  execute "$HOMEBREW_PREFIX/opt/nvim/bin/nvim" -c ':PlugInstall' -c ':qa!'

  ohai 'Install tmux plugins'
  if [ -e ~/.config/tmux/plugins/tpm ]; then
    execute git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
    execute ~/.config/tmux/plugins/tpm/bin/install_plugins
  fi

  ohai 'Tweak man.conf'
  manconf=/usr/local/etc/man.d/man.conf
  if ! [ -f "$manconf" ]; then
    execute_sudo mkdir -p "$(basename "$manconf")"
    execute_sudo touch "$manconf"
  else
    ohai "⚠️ $manconf already exists. Continue to append."
  fi

  execute_sudo sh -c "cat >>$(quote "$manconf")" < <(cat "$MODULES_DIR/etc/man.d/man.conf" | sed "s|:PH_HOMEBREW_PREFIX:|${HOMEBREW_PREFIX}|g")
  execute_sudo chmod 444 "$manconf"

  ohai 'Apply macOS defaults'
  execute "$MODULES_DIR/macos/defaults.sh"

  ohai 'DefaultKeyBinding.dict'
  execute sh -c "mkdir -p ~/Library/KeyBindings && cp $(quote "$MODULES_DIR")/macos/DefaultKeyBinding.dict ~/Library/KeyBindings/DefaultKeyBinding.dict"

  ohai 'Change the default shell'
  local homebrew_bash=${HOMEBREW_PREFIX}/opt/bash/bin/bash
  if ! grep -q "$homebrew_bash" /etc/shells; then
    execute_sudo sh -c "cat >> /etc/shells" <<<"$homebrew_bash"$'\n'
  fi
  execute_sudo chsh -s "$homebrew_bash"

  ohai "Open a new terminal window to use the new shell."

  ohai 'TODO: Install fonts'
}

if [ -t 1 ]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

abort() {
  printf "%s\n" "$@" >&2
  exit 1
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

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

ohai() {
  printf "${tty_blue}dotfiles>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

have_sudo_access() {
  if [[ ! -x "/usr/bin/sudo" ]]; then
    return 1
  fi

  local -a SUDO=("/usr/bin/sudo")
  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    SUDO+=("-A")
  elif [[ -n "${NONINTERACTIVE-}" ]]; then
    SUDO+=("-n")
  fi

  if [[ -z "${HAVE_SUDO_ACCESS-}" ]]; then
    if [[ -n "${NONINTERACTIVE-}" ]]; then
      "${SUDO[@]}" -l mkdir &>/dev/null
    else
      "${SUDO[@]}" -v && "${SUDO[@]}" -l mkdir &>/dev/null
    fi
    HAVE_SUDO_ACCESS="$?"
  fi

  if [[ "${HAVE_SUDO_ACCESS}" -ne 0 ]]; then
    abort "Need sudo access on macOS (e.g. the user ${USER} needs to be an Administrator)!"
  fi
}

execute() {
  if ! "$@"; then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

execute_sudo() {
  local -a args=("$@")
  have_sudo_access

  if [[ -n "${SUDO_ASKPASS-}" ]]; then
    args=("-A" "${args[@]}")
  fi
  ohai "/usr/bin/sudo" "${args[@]}"
  execute "/usr/bin/sudo" "${args[@]}"
}

quote() {
  builtin printf %q "$1"
}

set_homebrew_prefix() {
  if [[ -n "${HOMEBREW_PREFIX-}" ]]; then
    return
  fi

  OS="$(uname)"
  if [[ "${OS}" == "Linux" ]]; then
    : # HOMEBREW_ON_LINUX=1
  elif [[ "${OS}" == "Darwin" ]]; then
    HOMEBREW_ON_MACOS=1
  else
    abort "Homebrew is only supported on macOS and Linux."
  fi

  if [[ -n "${HOMEBREW_ON_MACOS-}" ]]; then
    UNAME_MACHINE="$(/usr/bin/uname -m)"

    if [[ "${UNAME_MACHINE}" == "arm64" ]]; then
      HOMEBREW_PREFIX="/opt/homebrew"
    else
      HOMEBREW_PREFIX="/usr/local"
    fi
  else
    HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
  fi
}

_main

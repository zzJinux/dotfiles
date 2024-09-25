#!/usr/bin/env bash
set -eu


if [[ -z ${DOTFILES:-} ]]; then
  if [[ ${#BASH_SOURCE[*]} -gt 0 ]]; then
    DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  else
    DOTFILES=$(pwd)
  fi
fi
export DOTFILES

if [[ -e "$DOTFILES/.git" ]]; then
  source "$DOTFILES/util.bash"
  source "$DOTFILES/homebrew/setvars.bash"
else
  eval "$(curl -fsSL https://raw.githubusercontent.com/zzJinux/dotfiles/master/util.bash)"
  eval "$(curl -fsSL https://raw.githubusercontent.com/zzJinux/dotfiles/master/homebrew/setvars.bash)"
fi
export HOMEBREW_PREFIX

# Some functions copied from https://github.com/Homebrew/install/blob/master/install.sh

_main() {
  local file
  # Allow inlining command substitutions
  # shellcheck disable=SC2312

  # Requirements: macOS Ventura, Apple Silicon, Internet available
  # This script shall be idempotent.

  # Homebrew install
  if ! [[ -e $HOMEBREW_PREFIX/bin/brew ]]; then
    # It will install Command Line Tools if not installed
    ohai 'Install Homebrew'
    execute /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi
  if ! [[ -e "$DOTFILES/.git" ]]; then
    ohai 'Clone the DOTFILES repository'
    git clone https://github.com/zzJinux/dotfiles.git "$DOTFILES"
  fi

  ohai 'Install Homebrew packages'
  "$HOMEBREW_PREFIX/bin/brew" bundle --verbose --file "$DOTFILES/homebrew/Brewfile"
  PATH="$HOMEBREW_PREFIX/bin:$PATH"

  ohai 'Install config files'
  for file in */_installconf.sh; do "$file"; done

  have_sudo_access

  ohai 'Setup'
  for file in */_setup.sh; do "$file"; done

  local homebrew_zsh=${HOMEBREW_PREFIX}/opt/zsh/bin/zsh
  local homebrew_bash=${HOMEBREW_PREFIX}/opt/bash/bin/bash
  if ! grep -q "$homebrew_zsh" /etc/shells; then
    execute_sudo sh -c "cat >> /etc/shells" <<<"$homebrew_zsh"$'\n'
  fi
  if ! grep -q "$homebrew_bash" /etc/shells; then
    execute_sudo sh -c "cat >> /etc/shells" <<<"$homebrew_bash"$'\n'
  fi

  ohai 'Set Homebrew zsh as the default'
  execute_sudo chsh -s "$homebrew_zsh" "$USER"

  ohai "Open a new terminal window to use the new shell."
}

_main

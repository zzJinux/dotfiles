#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
# SCRIPT_DIR="$(script_dir)"

ohai 'shell:installconf Configure sudoers env_keep'
if [ -f /etc/sudoers.d/env_keep ]; then
  echo "env_keep already configured"
  exit 0
fi
cat <<EOF | sudo EDITOR="tee -a" visudo -f /etc/sudoers.d/env_keep
Defaults env_keep += "TERM_PROGRAM TERM_PROGRAM_VERSION ITERM_PROFILE LC_TERMINAL LC_TERMINAL_VERSION"
Defaults env_keep += "ITERM_SESSION_ID TERM_SESSION_ID LOGIN_SHELL_SESSION_ID SHELL_SESSION_ID"
Defaults env_keep += "XDG_DATA_DIRS"
Defaults env_keep += "JAVA_HOME PNPM_HOME INFOPATH"
Defaults env_keep += "CLICOLOR LESS PAGER MANPAGER"
Defaults env_keep += "HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY"
EOF
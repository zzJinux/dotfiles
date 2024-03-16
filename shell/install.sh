#!/usr/bin/env bash
if [ -f /etc/sudoers.d/env_keep ]; then
  echo "env_keep already configured"
  exit 0
fi
cat <<EOF | sudo EDITOR="tee -a" visudo -f /etc/sudoers.d/env_keep
Defaults env_keep += "TERM_PROGRAM TERM_PROGRAM_VERSION ITERM_PROFILE LC_TERMINAL LC_TERMINAL_VERSION"
Defaults env_keep += "ITERM_SESSION_ID TERM_SESSION_ID LOGIN_SHELL_SESSION_ID SHELL_SESSION_ID"
Defaults env_keep += "XDG_DATA_DIRS"
Defaults env_keep += "JAVA_HOME PNPM_HOME VOLTA_HOME INFOPATH"
Defaults env_keep += "CLICOLOR PAGER OP_PLUGIN_ALIASES_SOURCED"
Defaults env_keep += "HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY"
EOF
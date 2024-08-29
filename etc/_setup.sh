#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"

ohai 'etc:setup Tweak man.conf'
manconf=/usr/local/etc/man.d/man.conf
if ! [ -f "$manconf" ]; then
  execute_sudo mkdir -p "$(basename "$manconf")"
  execute_sudo touch "$manconf"
else
  ohai "⚠️ $manconf already exists. Continue to append."
fi

execute_sudo sh -c "cat >>$(quote "$manconf")" < <(cat "$DOTFILES/etc/man.d/man.conf" | sed "s|:PH_HOMEBREW_PREFIX:|${HOMEBREW_PREFIX}|g")
execute_sudo chmod 444 "$manconf"

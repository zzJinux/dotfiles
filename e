#!/usr/bin/env bash
set -eu

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DOTFILES/util.bash"
# shellcheck disable=SC1090
source "$@"
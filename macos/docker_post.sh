#!/usr/bin/env bash

etc=/Applications/Docker.app/Contents/Resources/etc
completions=~/.local/share/bash-completion/completions
# SLOW startup: ln -s "$etc/docker.bash-completion" "$HOMEBREW_PREFIX/etc/bash_completion.d/docker"
ln -s "$(realpath fix_docker.bash-completion)" "$completions/docker"
ln -s "$etc/docker-compose.bash-completion" "$completions/docker-compose"

# bash startup slowdown
# https://gist.github.com/rkuzsma/4f8c1354a9ea67fb3ca915b50e131d1c?permalink_comment_id=4525328#gistcomment-4525328
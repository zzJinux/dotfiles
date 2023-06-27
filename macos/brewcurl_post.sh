#!/usr/bin/env bash

local_bin=~/.local/bin
mkdir -p "$local_bin"
: "${HOMEBREW_PREFIX:=$(brew --prefix)}"
ln -s "$HOMEBREW_PREFIX/opt/curl/bin/curl" "$local_bin/curl"
ln -s "$HOMEBREW_PREFIX/opt/curl/bin/curl-config" "$local_bin/curl-config"
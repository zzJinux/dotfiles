#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(_script_dir)"

ohai 'python:setup Install local Python venv'
python3 -m venv ~/.local/pytoolkit
source ~/.local/pytoolkit/bin/activate
pip install -r "$SCRIPT_DIR/requirements.txt"
python3 -m override_readline

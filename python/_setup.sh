#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(_script_dir)"

ohai 'python:install tool packages'
while IFS= read -r package; do
  ohai 'python:install tool '"$package"
  uv tool install "$package"
done < "$SCRIPT_DIR/tool_packages.txt"

ohai 'python:setup Install local Python venv'
virtualenv ~/.local/pytoolkit
source ~/.local/pytoolkit/bin/activate
pip install -r "$SCRIPT_DIR/requirements.txt"
python3 -m override_readline
deactivate

ohai 'python:link ipython config'
mkdir -p ~/.ipython/profile_default
symlink_safe "$SCRIPT_DIR/ipython_config.py" ~/.ipython/profile_default/ipython_config.py

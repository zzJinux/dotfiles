#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(_script_dir)"

ohai 'python:install pipx packages'
while IFS= read -r package; do
  ohai 'python:pipx:install '"$package"
  pipx install "$package"
done < "$SCRIPT_DIR/pipx_packages.txt"

ohai 'python:setup Install local Python venv'
virtualenv ~/.local/pytoolkit
source ~/.local/pytoolkit/bin/activate
pip install -r "$SCRIPT_DIR/requirements.txt"
python3 -m override_readline
deactivate

ohai 'python:link ipython config'
mkdir -p ~/.ipython/profile_default
symlink_safe "$SCRIPT_DIR/ipython_config.py" ~/.ipython/profile_default/ipython_config.py

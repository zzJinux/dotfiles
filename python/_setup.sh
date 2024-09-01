#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"
SCRIPT_DIR="$(_script_dir)"

ohai 'vim:setup Install local Python venv'
python3 -m venv ~/.local/pytoolkit
source ~/.local/pytoolkit/bin/activate
pip install -r "$SCRIPT_DIR/requirements.txt"
python3 -m override_readline

cat <<'EOF' > ~/.local/bin/python
#!/bin/sh
exec ~/.local/pytoolkit/bin/python "$@"
EOF

cat <<'EOF' > ~/.local/bin/python3
#!/bin/sh
exec ~/.local/pytoolkit/bin/python3 "$@"
EOF

cat <<'EOF' > ~/.local/bin/pip
#!/bin/sh
exec ~/.local/pytoolkit/bin/pip "$@"
EOF

cat <<'EOF' > ~/.local/bin/pip3
#!/bin/sh
exec ~/.local/pytoolkit/bin/pip3 "$@"
EOF

chmod +x ~/.local/bin/{python,python3,pip,pip3}
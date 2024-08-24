#!/usr/bin/env bash

python3 venv ~/.local/pytoolkit
source ~/.local/pytoolkit/bin/activate
pip install -r requirements.txt
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
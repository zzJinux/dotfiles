## Install

```
python3 venv ~/.local/pytoolkit
source ~/.local/pytoolkit/bin/activate
pip install -r requirements.txt

cat <<\EOF > ~/.local/bin/python
#!/usr/bin/env bash
exec ~/.local/pytoolkit/bin/python "$@"
EOF
cat <<\EOF > ~/.local/bin/python3
#!/usr/bin/env bash
exec ~/.local/pytoolkit/bin/python3 "$@"
EOF
chmod +x ~/.local/bin/python ~/.local/bin/python3
```
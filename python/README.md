## Make gnureadline default
```
uv run --python $python pip install --user --break-system-packages gnureadline
uv run --python $python python -m override_readline
```
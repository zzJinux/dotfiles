#!/usr/bin/env bash

# ~/.config/tmux/plugins -> tar:plugins
tar -czf tmux.tar.gz -C "$HOME/.config/tmux" plugins

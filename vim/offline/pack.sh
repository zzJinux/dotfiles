#!/usr/bin/env bash

# ~/.vim/plugged -> tar:plugged
# ~/.vim/autoload -> tar:./autoload
tar -czf vim.tar.gz -C "$HOME/.vim" plugged autoload

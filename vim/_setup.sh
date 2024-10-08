#!/usr/bin/env bash
set -eu

source "$DOTFILES/util.bash"

ohai 'vim:setup Install vim-plug plugins'
if ! [ -e ~/.vim/autoload/plug.vim ]; then
  execute curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
execute vim -es -u ~/.vimrc -i NONE -c "PlugInstall" -c "qa"
# execute nvim -es -u ~/.config/nvim/init.vim -i NONE -c "PlugInstall" -c "qa"

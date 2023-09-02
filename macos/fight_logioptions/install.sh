#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

dest=~/Library/LaunchAgents/local.fight_logioptions.plist
cp "$SCRIPT_DIR/LaunchAgent.plist" "$dest"
defaults write "$dest" ProgramArguments -array-add ~/.dotfiles/macos/fight_logioptions/force_restore
plutil -convert xml1 "$dest"
chmod 644 "$dest"
launchctl load "$dest"

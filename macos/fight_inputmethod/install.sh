#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

dest=~/Library/LaunchAgents/local.fight_inputmethod.plist
cp "$SCRIPT_DIR/LaunchAgent.plist" "$dest"
defaults write "$dest" ProgramArguments -array-add "launchctl" "kickstart" "-p" "gui/$UID/com.apple.TextInputSwitcher"
plutil -convert xml1 "$dest"
chmod 644 "$dest"
launchctl load "$dest"

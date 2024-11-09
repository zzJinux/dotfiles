#!/usr/bin/env bash

# Requires sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

plist_file="$1"
plist_file_base=$(basename "$plist_file")

cp "$plist_file" /Library/LaunchDaemons/
chown root:wheel /Library/LaunchDaemons/"$plist_file_base"
chmod 644 /Library/LaunchDaemons/"$plist_file_base"
launchctl load /Library/LaunchDaemons/"$plist_file_base"

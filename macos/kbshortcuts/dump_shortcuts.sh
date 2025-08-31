#!/usr/bin/env bash
if [ -e cur.plist ]; then
  mv cur.plist prev.plist
fi
defaults export com.apple.symbolichotkeys - > cur.plist

#!/usr/bin/env python3
import plistlib
import os
import subprocess

# com.apple.symbolichotkeys
entries = {
    # "Turn dock hiding on/off" = disable
    '52': {'enabled': False},

    # "Decrease brightness" = disable
    '53': {'enabled': False},
    # "Increase brightness" = disable
    '54': {'enabled': False},

    # Select the previous input source = Option + Space
    '60': {'enabled': True, 'value': {'parameters': [32, 49, 524288], 'type': 'standard'}},

    # Show Spotlight search = disable
    '64': {'enabled': False},

    # Turn VoiceOver on or off = disable
    '162': {'enabled': False},
    # Turn VoiceOver on or off = disable
    '59': {'enabled': False},
}

plist_path=os.path.expanduser('~/Library/Preferences/com.apple.symbolichotkeys.plist')
data = None
with open(plist_path, 'rb') as f:
    data = plistlib.load(f)
    # Patch the data with the new entries
    for k, v in entries.items():
        data['AppleSymbolicHotKeys'].setdefault(k, {})
        data['AppleSymbolicHotKeys'][k].update(v)

with open(plist_path, 'wb') as f:
    plistlib.dump(data, f)

subprocess.run(["defaults", "read", "com.apple.symbolichotkeys"], stdout=subprocess.DEVNULL)

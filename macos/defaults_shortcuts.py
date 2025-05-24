#!/usr/bin/env python3
import argparse
import os
import plistlib
import subprocess

# Parse command line arguments
parser = argparse.ArgumentParser(description="Configure macOS keyboard shortcuts")
parser.add_argument("--flush", action="store_true", help="Flush system preferences and restart relevant services")
args = parser.parse_args()

# com.apple.symbolichotkeys
entries = {
    # "Turn dock hiding on/off" = disable
    "52": {"enabled": False},
    # "Decrease brightness" = disable
    "53": {"enabled": False},
    # "Increase brightness" = disable
    "54": {"enabled": False},
    # Select the previous input source = Option + Space
    "60": {"enabled": True, "value": {"parameters": [32, 49, 524288], "type": "standard"}},
    # Show Spotlight search = disable
    "64": {"enabled": False},
    # Show Finder search window = disable
    "65": {"enabled": False},
    # Turn VoiceOver on or off = disable
    "162": {"enabled": False},
    # Turn VoiceOver on or off = disable
    "59": {"enabled": False},
    # Move left a space = disable
    "79": {"enabled": False},
    # Move right a space = disable
    "81": {"enabled": False},
}

plist_path = os.path.expanduser("~/Library/Preferences/com.apple.symbolichotkeys.plist")
data = None
with open(plist_path, "rb") as f:
    data = plistlib.load(f)
    # Patch the data with the new entries
    for k, v in entries.items():
        data["AppleSymbolicHotKeys"].setdefault(k, {})
        data["AppleSymbolicHotKeys"][k].update(v)

with open(plist_path, "wb") as f:
    plistlib.dump(data, f)

subprocess.run(["defaults", "read", "com.apple.symbolichotkeys"], stdout=subprocess.DEVNULL)


entries = {
    "NSServicesStatus": {
        "com.apple.Terminal - Open man Page in Terminal - openManPage": {
            "enabled_context_menu": False,
            "enabled_services_menu": False,
            "presentation_modes": {"ContextMenu": False, "ServicesMenu": False},
        }
    }
}

plist_path = os.path.expanduser("~/Library/Preferences/pbs.plist")
data: dict
with open(plist_path, "rb") as f:
    data = plistlib.load(f)
    d_NSServiceStatus = data.setdefault("NSServicesStatus", {})

    # Disable: "Keyboard Shortcuts > Services > Text > Open man Page in Terminal"
    k = "com.apple.Terminal - Open man Page in Terminal - openManPage"
    d_NSServiceStatus[k] = {
        "enabled_context_menu": False,
        "enabled_services_menu": False,
        "presentation_modes": {"ContextMenu": False, "ServicesMenu": False},
    }

    # Disable: "Keyboard Shortcuts > Services > Text > Search man Page Index in Terminal"
    k = "com.apple.Terminal - Search man Page Index in Terminal - searchManPages"
    d_NSServiceStatus[k] = {
        "enabled_context_menu": False,
        "enabled_services_menu": False,
        "presentation_modes": {"ContextMenu": False, "ServicesMenu": False},
    }

with open(plist_path, "wb") as f:
    plistlib.dump(data, f)

subprocess.run(["defaults", "read", "pbs"], stdout=subprocess.DEVNULL)

# Flush system preferences if requested
if args.flush:
    apps = ["Activity Monitor", "cfprefsd", "Dock", "Finder", "SystemUIServer"]

    for app in apps:
        subprocess.run(["killall", app], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    subprocess.run(
        ["/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings", "-u"]
    )

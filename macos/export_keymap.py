#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = ["pyobjc", "pyobjc-framework-ApplicationServices"]
# ///

# -*- coding: utf-8 -*-

"""
macOS keyboard shortcut exporter (menus + System Settings overrides)

- Scrapes application-defined shortcuts via Accessibility (AX).
- Reads user-defined overrides from NSUserKeyEquivalents (global + per-app).
- Produces unified JSON on stdout.

Usage examples:
  python3 export_keymap.py                  # frontmost app only
  python3 export_keymap.py --all-running    # all GUI apps currently running
  python3 export_keymap.py --bundle com.apple.TextEdit  # specific bundle id

Notes:
  - Requires: pip install pyobjc
  - Allow Accessibility access for your terminal/Python.
"""

import argparse
import json
import os
import plistlib
import re
import subprocess
import sys
from datetime import datetime, timezone

# PyObjC
from AppKit import NSWorkspace
from Foundation import NSBundle, NSObject

# Accessibility API via ApplicationServices (PyObjC)
try:
    from ApplicationServices import (
        AXUIElementCreateApplication,
        AXUIElementCopyAttributeValue,
        kAXMenuBarAttribute,
        kAXChildrenAttribute,
        kAXTitleAttribute,
        kAXErrorSuccess,
    )
except Exception as e:
    raise ImportError(
        "Couldn't import Accessibility APIs from ApplicationServices. "
        "Install PyObjC Accessibility bridges: "
        "python3 -m pip install 'pyobjc>=10' 'pyobjc-framework-ApplicationServices>=10'\n"
        f"Original error: {e}"
    )


# Accessibility menu item shortcut attributes (not always present)
# These are not exposed as constants in PyObjC, but strings work.
AX_CMD_CHAR = "AXMenuItemCmdChar"
AX_CMD_MODS = "AXMenuItemCmdModifiers"
AX_ENABLED = "AXEnabled"
AX_CMD_GLYPH = "AXMenuItemCmdGlyph"

# Some apps expose a glyph integer instead of a character for special keys.
# We convert the integer to a Unicode character via chr() and then normalize
# it with AX_SPECIAL_KEY_MAP in normalize_key().


# kAXMenuItemCmdModifiers bit layout:
# bit 0 = Shift (1)
# bit 1 = Option/Alt (2)
# bit 2 = Control (4)
# bit 3 = NO Command (8) — Command is present iff this bit is 0
# We emit canonical macOS ordering: cmd, shift, opt, ctrl
def decode_ax_modifiers(mask):
    try:
        m = int(mask)
    except Exception:
        return []
    mods = []
    if (m & 1) != 0:
        mods.append("shift")
    if (m & 2) != 0:
        mods.append("opt")
    if (m & 4) != 0:
        mods.append("ctrl")
    if (m & 8) == 0:
        mods.append("cmd")
    # Treat bit 4 as Function/Globe if present (observed in newer macOS)
    if (m & 16) != 0:
        mods.append("fn")
    return mods


MOD_TO_SYMBOL = {"cmd": "⌘", "shift": "⇧", "opt": "⌥", "ctrl": "⌃", "fn": "🌐"}

MOD_ORDER = {"ctrl": 0, "fn": 1, "opt": 2, "shift": 3, "cmd": 4}

# Modifier words for search/labeling
MOD_TO_WORD = {"cmd": "Cmd", "shift": "Shift", "opt": "Opt", "ctrl": "Ctrl", "fn": "Fn"}


# --- Centralized Key Registry ---
# Canonical key name: maps to display and aliases for normalization
KEY_REGISTRY = {
    # Simple keys (ASCII, whitespace)
    "Tab": {
        "display": "⇥",
        "aliases": ["\t", "\uf72f"],  # \uf72f is ScrollLock but included for completeness
        # No PUA for Tab, but \t is used
    },
    "Backspace": {
        "display": "⌫",
        "aliases": ["\b"],
    },
    "Esc": {
        "display": "⎋",
        "aliases": ["\x1b"],
    },
    "Enter": {
        "display": "↩",
        "aliases": ["\r", "\n"],
    },
    "Space": {
        "display": "␣",
        "aliases": [" "],
    },
    "CapsLock": {
        "display": "⇪",
        "aliases": [],
    },
    # Arrow keys and navigation (PUA codes)
    "UpArrow": {
        "display": "↑",
        "aliases": ["\uf700"],
    },
    "DownArrow": {
        "display": "↓",
        "aliases": ["\uf701"],
    },
    "LeftArrow": {
        "display": "←",
        "aliases": ["\uf702"],
    },
    "RightArrow": {
        "display": "→",
        "aliases": ["\uf703"],
    },
    "PageUp": {
        "display": "⇞",
        "aliases": ["\uf72c"],
    },
    "PageDown": {
        "display": "⇟",
        "aliases": ["\uf72d"],
    },
    "Home": {
        "display": "↖",
        "aliases": ["\uf729"],
    },
    "End": {
        "display": "↘",
        "aliases": ["\uf72b"],
    },
    "Delete": {
        "display": "⌦",
        "aliases": ["\uf728"],
    },
    "Insert": {
        "display": "⎀",
        "aliases": ["\uf727"],
    },
    # Function keys F1-F24 (PUA codes)
    **{
        f"F{n}": {
            "display": f"F{n}",
            "aliases": [chr(0xf704 + (n-1))] if 1 <= n <= 24 else [],
        }
        for n in range(1, 25)
    },
    # Other known PUA keys (from original AX_SPECIAL_KEY_MAP)
    "Begin": {
        "display": "Begin",
        "aliases": ["\uf72a"],
    },
    "PrintScreen": {
        "display": "PrintScreen",
        "aliases": ["\uf72e"],
    },
    "ScrollLock": {
        "display": "ScrollLock",
        "aliases": ["\uf72f"],
    },
    "Pause": {
        "display": "Pause",
        "aliases": ["\uf730"],
    },
    "SysReq": {
        "display": "SysReq",
        "aliases": ["\uf731"],
    },
    "Break": {
        "display": "Break",
        "aliases": ["\uf732"],
    },
    "Reset": {
        "display": "Reset",
        "aliases": ["\uf733"],
    },
    "Stop": {
        "display": "Stop",
        "aliases": ["\uf734"],
    },
    "Menu": {
        "display": "Menu",
        "aliases": ["\uf735"],
    },
    "User": {
        "display": "User",
        "aliases": ["\uf736"],
    },
    "System": {
        "display": "System",
        "aliases": ["\uf737"],
    },
    "Print": {
        "display": "Print",
        "aliases": ["\uf738"],
    },
    "ClearLine": {
        "display": "ClearLine",
        "aliases": ["\uf739"],
    },
    "ClearDisplay": {
        "display": "ClearDisplay",
        "aliases": ["\uf73a"],
    },
    "InsertLine": {
        "display": "InsertLine",
        "aliases": ["\uf73b"],
    },
    "DeleteLine": {
        "display": "DeleteLine",
        "aliases": ["\uf73c"],
    },
    "InsertChar": {
        "display": "InsertChar",
        "aliases": ["\uf73d"],
    },
    "DeleteChar": {
        "display": "DeleteChar",
        "aliases": ["\uf73e"],
    },
    "Prev": {
        "display": "Prev",
        "aliases": ["\uf73f"],
    },
    "Next": {
        "display": "Next",
        "aliases": ["\uf740"],
    },
    "Select": {
        "display": "Select",
        "aliases": ["\uf741"],
    },
    "Execute": {
        "display": "Execute",
        "aliases": ["\uf742"],
    },
    "Undo": {
        "display": "Undo",
        "aliases": ["\uf743"],
    },
    "Redo": {
        "display": "Redo",
        "aliases": ["\uf744"],
    },
    "Find": {
        "display": "Find",
        "aliases": ["\uf745"],
    },
    "Help": {
        "display": "Help",
        "aliases": ["\uf746"],
    },
    "ModeSwitch": {
        "display": "ModeSwitch",
        "aliases": ["\uf747"],
    },
}

# Build KEY_DISPLAY, KEY_SEARCH, and AX_SPECIAL_KEY_MAP from KEY_REGISTRY
KEY_DISPLAY = {}
KEY_SEARCH = {}
AX_SPECIAL_KEY_MAP = {}
for canonical, entry in KEY_REGISTRY.items():
    # Add canonical key to display/search
    KEY_DISPLAY[canonical] = entry["display"]
    KEY_SEARCH[canonical] = canonical
    # Add aliases (including canonical if alias)
    for alias in entry.get("aliases", []):
        KEY_DISPLAY[alias] = entry["display"]
        KEY_SEARCH[alias] = canonical
        # For AX_SPECIAL_KEY_MAP, only map PUA codes (in Private Use Area)
        if isinstance(alias, str) and len(alias) == 1 and 0xf700 <= ord(alias) <= 0xf7ff:
            AX_SPECIAL_KEY_MAP[alias] = canonical

def format_shortcut_texts(key, modifiers):
    """Return (display, search) strings for a key + modifiers."""
    if not key:
        return ("", "")
    # Order modifiers consistently
    ordered = sorted(modifiers or [], key=lambda m: MOD_ORDER.get(m, 99))
    prefix_disp = "".join(MOD_TO_SYMBOL.get(m, m) for m in ordered)
    disp_key = KEY_DISPLAY.get(key, key)
    prefix_search = " ".join(MOD_TO_WORD.get(m, m) for m in ordered)
    search_key = KEY_SEARCH.get(key, key)
    search = (prefix_search + " " + search_key).strip()
    display = prefix_disp + disp_key
    return (display, search)


# Symbols used by NSUserKeyEquivalents strings
# @ = cmd, $ = shift, ~ = opt, ^ = ctrl
SYMBOL_TO_MOD = {"@": "cmd", "$": "shift", "~": "opt", "^": "ctrl"}


def normalize_key(char):
    if not char:
        return None
    # Try to normalize with AX_SPECIAL_KEY_MAP (PUA Unicode), else canonicalize via aliases
    if char in AX_SPECIAL_KEY_MAP:
        return AX_SPECIAL_KEY_MAP[char]
    # Try all aliases in KEY_REGISTRY
    for canonical, entry in KEY_REGISTRY.items():
        if char == canonical or char in entry.get("aliases", []):
            return canonical
    return char


def _run_defaults_export(domain: str):
    """
    Use `/usr/bin/defaults export <domain> -` to get an XML plist on stdout and parse it.
    Returns dict (possibly empty).
    """
    try:
        proc = subprocess.run(["/usr/bin/defaults", "export", domain, "-"], check=False, capture_output=True)
        if proc.returncode != 0 or not proc.stdout:
            return {}
        return plistlib.loads(proc.stdout)
    except Exception:
        return {}


def read_global_user_overrides():
    """
    Read NSUserKeyEquivalents from the global domain (-g / .GlobalPreferences).
    Returns dict[str,str] like {"Save As…": "@$S"} or {} if none.
    """
    # Safer to parse the whole domain plist (handles non-ASCII keys reliably)
    data = _run_defaults_export("-g")
    if not isinstance(data, dict):
        return {}
    return data.get("NSUserKeyEquivalents", {}) or {}


def read_per_app_user_overrides(bundle_id: str):
    """
    Read NSUserKeyEquivalents from a specific app domain.
    """
    if not bundle_id:
        return {}
    data = _run_defaults_export(bundle_id)
    if not isinstance(data, dict):
        return {}
    return data.get("NSUserKeyEquivalents", {}) or {}


def parse_nsuser_equivalent_string(s: str):
    """
    Convert a string like '@$S' into a normalized structure:
      {"key":"S","modifiers":["cmd","shift"],"raw":"@$S"}
    If the "key" part is empty (e.g., '^\t'), we keep raw and leave key None.
    """
    mods = []
    key_chars = []
    for ch in s:
        if ch in SYMBOL_TO_MOD:
            mods.append(SYMBOL_TO_MOD[ch])
        else:
            key_chars.append(ch)

    key = "".join(key_chars) if key_chars else None
    return {"key": key, "modifiers": mods, "raw": s}


def ax_get(obj, attr):
    """
    Helper to safely read an AX attribute; returns (True, value) or (False, None)
    """
    ok, value = AXUIElementCopyAttributeValue(obj, attr, None)
    return (ok == kAXErrorSuccess, value)


def ax_children(obj):
    ok, value = ax_get(obj, kAXChildrenAttribute)
    return value if ok and value else []


def ax_title(obj):
    ok, value = ax_get(obj, kAXTitleAttribute)
    if ok and value:
        # value may be NSString; convert to str
        return str(value)
    return None


def ax_enabled(obj):
    ok, value = ax_get(obj, AX_ENABLED)
    return bool(value) if ok else True  # assume enabled if not present


def ax_menu_cmd_glyph(item):
    ok, value = ax_get(item, AX_CMD_GLYPH)
    if ok and isinstance(value, (int, float)):
        iv = int(value)
        try:
            return chr(iv)
        except ValueError:
            return None
    return None


def ax_menu_cmd_char(item):
    # Prefer glyph when present (more reliable for arrows/function keys)
    key_from_glyph = ax_menu_cmd_glyph(item)
    if key_from_glyph:
        return normalize_key(key_from_glyph)
    ok, value = ax_get(item, AX_CMD_CHAR)
    if ok and value:
        return normalize_key(str(value))
    return None


def ax_menu_cmd_mods(item):
    ok, value = ax_get(item, AX_CMD_MODS)
    return decode_ax_modifiers(value) if ok else []


def walk_menu_tree(node, path_prefix, out_items):
    """
    DFS walk of AX menu tree, collecting items with titles and shortcuts (if any).
    """
    title = ax_title(node)
    children = ax_children(node)

    # If this node itself is a "menu item" (leaves can still have submenus), capture it.
    # Heuristic: if it has a title, it's a candidate. Ignore separators (title = None or "-")
    if title and title.strip("-").strip():
        shortcut_key = ax_menu_cmd_char(node)
        shortcut_mods = ax_menu_cmd_mods(node)
        path = path_prefix + [title]
        out_items.append(
            {
                "title": title,
                "path": " > ".join(path_prefix + [title]),
                "shortcut": (
                    (
                        lambda _d, _s: {
                            "key": shortcut_key,
                            "modifiers": shortcut_mods,
                            "text_display": _d,
                            "text_search": _s,
                        }
                    )(*format_shortcut_texts(shortcut_key, shortcut_mods))
                    if shortcut_key
                    else None
                ),
                "enabled": ax_enabled(node),
            }
        )

        # If this item has a submenu, its children will be that submenu's items.
        for child in children:
            walk_menu_tree(child, path, out_items)
    else:
        # Non-titled node, descend
        for child in children:
            walk_menu_tree(child, path_prefix, out_items)


def dump_app_menus_for_pid(pid):
    """
    For a given process id, returns list of menu items.
    """
    try:
        app_ax = AXUIElementCreateApplication(pid)
        ok, menu_bar = ax_get(app_ax, kAXMenuBarAttribute)
        if not ok or not menu_bar:
            return []
        items = []
        walk_menu_tree(menu_bar, [], items)
        return items
    except Exception:
        return []


def get_running_gui_apps():
    """
    Returns list of dicts: {name, bundle_id, pid, is_active}
    Only GUI apps (activationPolicy == .regular).
    """
    ws = NSWorkspace.sharedWorkspace()
    apps = []
    for app in ws.runningApplications():
        try:
            if app.activationPolicy() != 0:  # 0 == NSApplicationActivationPolicyRegular
                continue
            apps.append(
                {
                    "name": str(app.localizedName() or ""),
                    "bundle_id": str(app.bundleIdentifier() or ""),
                    "pid": int(app.processIdentifier()),
                    "is_active": bool(app.isActive()),
                }
            )
        except Exception:
            continue
    # Unique by PID; sort active first, then by name
    seen = set()
    uniq = []
    for a in apps:
        if a["pid"] in seen:
            continue
        seen.add(a["pid"])
        uniq.append(a)
    uniq.sort(key=lambda x: (not x["is_active"], x["name"].lower()))
    return uniq


def get_frontmost_app():
    apps = get_running_gui_apps()
    for a in apps:
        if a["is_active"]:
            return a
    return apps[0] if apps else None


def apply_overrides_to_items(items, overrides_global, overrides_app):
    """
    Determine if an override applies to each menu item by exact title match.
    Returns new list with 'override' field if found.
    Priority: per-app > global.
    """
    out = []
    for it in items:
        title = it.get("title")
        ov = None
        scope = None
        if title in overrides_app:
            ov = overrides_app[title]
            scope = "per-app"
        elif title in overrides_global:
            ov = overrides_global[title]
            scope = "global"

        if ov is not None:
            parsed = parse_nsuser_equivalent_string(ov)
            out.append(
                {
                    **it,
                    "source": "user" if parsed.get("key") else "user",  # still user even if no key
                    "override": {"applies": True, "scope": scope, "raw": ov, "parsed": parsed},
                }
            )
        else:
            out.append({**it, "source": "app"})
    return out


def main():
    parser = argparse.ArgumentParser(
        description="Export macOS application keyboard shortcuts + user overrides to JSON."
    )
    g = parser.add_mutually_exclusive_group()
    g.add_argument("--all-running", action="store_true", help="Export for all GUI apps currently running.")
    g.add_argument("--bundle", type=str, help="Export for a specific bundle id (must be running).")
    args = parser.parse_args()

    # Read user overrides once
    overrides_global = read_global_user_overrides()

    # Choose target apps
    targets = []
    running = get_running_gui_apps()

    if args.bundle:
        targets = [a for a in running if a["bundle_id"] == args.bundle]
        if not targets:
            print(
                json.dumps(
                    {"error": f"Bundle id {args.bundle} is not a running GUI app."}, ensure_ascii=False, indent=2
                )
            )
            sys.exit(1)
    elif args.all_running:
        targets = running
    else:
        front = get_frontmost_app()
        if not front:
            print(json.dumps({"error": "No frontmost GUI app detected."}, ensure_ascii=False, indent=2))
            sys.exit(1)
        targets = [front]

    apps_out = []
    for app in targets:
        per_app_overrides = read_per_app_user_overrides(app["bundle_id"])
        items = dump_app_menus_for_pid(app["pid"])
        items = apply_overrides_to_items(items, overrides_global, per_app_overrides)
        apps_out.append(
            {
                "name": app["name"],
                "bundle_id": app["bundle_id"],
                "pid": app["pid"],
                "menus": items,
                "user_overrides_for_app": per_app_overrides,  # raw map for transparency
            }
        )

    result = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "user_overrides": {
            "global": overrides_global,
            "per_app": {a["bundle_id"]: a["user_overrides_for_app"] for a in apps_out},
        },
        "apps": apps_out,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    # Fail early with a clear message if PyObjC frameworks are missing
    try:
        main()
    except PermissionError:
        # Accessibility not granted is commonly surfaced as a PermissionError when AX calls fail
        print(
            json.dumps(
                {
                    "error": "Accessibility permission required. Enable your terminal/Python under Privacy & Security → Accessibility."
                },
                ensure_ascii=False,
                indent=2,
            )
        )
        sys.exit(2)
    except Exception as e:
        print(json.dumps({"error": str(e)}, ensure_ascii=False, indent=2))
        sys.exit(2)

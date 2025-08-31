#!/usr/bin/env bash
set -euo pipefail

# check_icns.sh — Validate contents of a .icns file on macOS.
# Usage:
#   ./check_icns.sh "/System/Applications/Automator.app/Contents/Resources/AppIcon.icns"
# Optional:
#   --require "16,32,128,256,512,1024"   # expected square sizes in px (base sizes; @2x variants are implied)
#   --quiet                               # exit code only, minimal output

REQ_SIZES="16,32,128,256,512,1024"
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --require)
      REQ_SIZES="$2"; shift 2;;
    --quiet)
      QUIET=1; shift;;
    -*)
      echo "Unknown option: $1" >&2; exit 2;;
    *)
      ICNS_PATH="$1"; shift;;
  esac
done

if [[ -z "${ICNS_PATH:-}" ]]; then
  echo "Usage: $0 /path/to/icon.icns [--require \"16,32,128,256,512,1024\"] [--quiet]" >&2
  exit 2
fi

if [[ ! -f "$ICNS_PATH" ]]; then
  echo "No such file: $ICNS_PATH" >&2
  exit 1
fi

# Ensure we're on macOS with iconutil and sips available.
if ! command -v iconutil >/dev/null 2>&1; then
  echo "iconutil not found; this must run on macOS." >&2
  exit 1
fi
if ! command -v sips >/dev/null 2>&1; then
  echo "sips not found (should exist on macOS)." >&2
  exit 1
fi

# 1) Validate magic header ("icns")
if command -v xxd >/dev/null 2>&1; then
  MAGIC=$(xxd -p -l 4 "$ICNS_PATH")
else
  MAGIC=$(hexdump -n 4 -e '4/1 "%02x"' "$ICNS_PATH" 2>/dev/null || echo "")
fi
if [[ "${MAGIC,,}" != "69636e73" ]]; then
  [[ $QUIET -eq 0 ]] && echo "FAIL: Bad magic (expected 'icns'); got 0x$MAGIC from $ICNS_PATH"
  exit 3
fi

# 2) Expand to iconset and enumerate PNGs
WORKDIR="$(mktemp -d /tmp/checkicns.XXXXXX)"
trap 'rm -rf "$WORKDIR"' EXIT

ICONSET="$WORKDIR/icon.iconset"
if ! iconutil -c iconset -o "$ICONSET" "$ICNS_PATH" >/dev/null 2>&1; then
  [[ $QUIET -eq 0 ]] && echo "FAIL: iconutil could not expand $ICNS_PATH"
  exit 4
fi

mapfile -t PNGS < <(ls -1 "$ICONSET"/icon_*x*.png 2>/dev/null || true)
if (( ${#PNGS[@]} == 0 )); then
  [[ $QUIET -eq 0 ]] && echo "FAIL: iconutil produced no PNGs (empty iconset)."
  exit 5
fi

# 3) Build a set of discovered sizes (width==height)
declare -A FOUND=()
MAX_SIZE=0
for p in "${PNGS[@]}"; do
  # sips output lines like: pixelWidth: 256
  W=$(sips -g pixelWidth "$p" 2>/dev/null | awk '/pixelWidth/ {print $2}')
  H=$(sips -g pixelHeight "$p" 2>/dev/null | awk '/pixelHeight/ {print $2}')
  [[ -n "$W" && "$W" == "$H" ]] || continue
  FOUND["$W"]=1
  (( W > MAX_SIZE )) && MAX_SIZE=$W
done

# 4) Determine missing required sizes (including @2x)
#    For each base N in REQ_SIZES, we expect N and 2N to be present.
IFS=',' read -r -a REQ <<< "$REQ_SIZES"
MISSING=()
for base in "${REQ[@]}"; do
  base="${base//[[:space:]]/}"
  [[ -z "$base" ]] && continue
  need1="$base"
  need2=$(( base * 2 ))
  [[ -n "${FOUND[$need1]:-}" ]] || MISSING+=("$need1")
  [[ -n "${FOUND[$need2]:-}" ]] || MISSING+=("$need2")
done

# 5) Report
STATUS=0
if (( ${#MISSING[@]} > 0 )); then
  STATUS=6
fi

if (( MAX_SIZE < 512 )); then
  # Heuristic: modern macOS app icons should include 1024 (512@2x). Warn/fail.
  STATUS=7
fi

if [[ $QUIET -eq 0 ]]; then
  echo "Analyzed: $ICNS_PATH"
  echo "Header:   OK (magic 'icns')"
  echo -n "Found:    "
  # Print sorted sizes
  printf "%s\n" "${!FOUND[@]}" | sort -n | tr '\n' ' '; echo
  echo "Largest:  ${MAX_SIZE}px"
  if (( ${#MISSING[@]} > 0 )); then
    echo -n "Missing:  "
    printf "%s " "${MISSING[@]}"; echo
  else
    echo "Missing:  none (meets required set: $REQ_SIZES + @2x)"
  fi
  if (( STATUS == 0 )); then
    echo "Result:   PASS"
  else
    echo "Result:   FAIL (status $STATUS)"
  fi
fi

exit $STATUS

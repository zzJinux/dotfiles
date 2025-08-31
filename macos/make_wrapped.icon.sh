#!/usr/bin/env bash
set -euo pipefail

# Usage: ./make_wrapped_icon.sh "/Applications/Original.app" "/Applications/Wrapper.app"
# Optional third arg: custom badge .icns path
# Default badge is Automator's icon inside /System/Applications/Automator.app

ORIG_APP="${1:-}"
WRAP_APP="${2:-}"
# NOTE: AutomatorApplet.icns does not exist on modern macOS; AppIcon.icns is correct
BADGE_ICNS="${3:-/System/Applications/Automator.app/Contents/Resources/AppIcon.icns}"

if [[ -z "${ORIG_APP}" || -z "${WRAP_APP}" ]]; then
  echo "Usage: $0 \"/Applications/Original.app\" \"/Applications/Wrapper.app\" [badge.icns]"
  exit 1
fi

if [[ ! -d "$ORIG_APP" ]]; then
  echo "Original app not found: $ORIG_APP" >&2
  exit 1
fi
if [[ ! -d "$WRAP_APP" ]]; then
  echo "Wrapper app not found: $WRAP_APP" >&2
  exit 1
fi
if [[ ! -f "$BADGE_ICNS" ]]; then
  echo "Badge .icns not found: $BADGE_ICNS" >&2
  echo "Hint: try /System/Applications/Automator.app/Contents/Resources/AppIcon.icns" >&2
  exit 1
fi

# Check for iconutil
if ! command -v iconutil >/dev/null 2>&1; then
  echo "iconutil not found; this script must run on macOS." >&2
  exit 1
fi

# Check for ImageMagick (magick or convert)
if command -v magick >/dev/null 2>&1; then
  IM="magick"
elif command -v convert >/dev/null 2>&1; then
  IM="convert"
else
  echo "ImageMagick not found. Install with: brew install imagemagick" >&2
  exit 1
fi

PLISTBUDDY="/usr/libexec/PlistBuddy"

# Resolve original app's primary .icns
RES_DIR="$ORIG_APP/Contents/Resources"
PLIST="$ORIG_APP/Contents/Info.plist"

if [[ ! -f "$PLIST" ]]; then
  echo "Missing Info.plist in original app." >&2
  exit 1
fi

CFICON=""
set +e
CFICON="$("$PLISTBUDDY" -c 'Print :CFBundleIconFile' "$PLIST" 2>/dev/null || true)"
set -e

# CFBundleIconFile may be without .icns extension
if [[ -n "$CFICON" ]]; then
  # Try with and without extension
  if [[ -f "$RES_DIR/$CFICON" ]]; then
    ORIG_ICNS="$RES_DIR/$CFICON"
  elif [[ -f "$RES_DIR/$CFICON.icns" ]]; then
    ORIG_ICNS="$RES_DIR/$CFICON.icns"
  else
    ORIG_ICNS=""
  fi
else
  ORIG_ICNS=""
fi

# Fallback: pick the largest .icns in Resources
if [[ -z "$ORIG_ICNS" ]]; then
  mapfile -t ICNS_LIST < <(ls -1 "$RES_DIR"/*.icns 2>/dev/null || true)
  if (( ${#ICNS_LIST[@]} == 0 )); then
    echo "No .icns found in $RES_DIR. If the app uses asset catalogs only, this script can't extract the icon." >&2
    exit 1
  fi
  # Heuristic: choose the .icns with the biggest file size
  ORIG_ICNS="$(ls -Sl "$RES_DIR"/*.icns | awk 'NR==1{print $9}')"
fi

echo "Original icon: $ORIG_ICNS"
echo "Badge icon:    $BADGE_ICNS"

# Workspace
WORKDIR="$(mktemp -d /tmp/wrapicon.XXXXXX)"
trap 'rm -rf "$WORKDIR"' EXIT

ORIG_ICONSET="$WORKDIR/orig.iconset"
BADGE_ICONSET="$WORKDIR/badge.iconset"
OUT_ICONSET="$WORKDIR/wrapper.iconset"
mkdir -p "$ORIG_ICONSET" "$BADGE_ICONSET" "$OUT_ICONSET"

# Expand icns to iconsets
iconutil -c iconset -o "$ORIG_ICONSET" "$ORIG_ICNS"
iconutil -c iconset -o "$BADGE_ICONSET" "$BADGE_ICNS"

# Choose an original source PNG (largest available). If iconutil produced no PNGs,
# extract a single PNG directly from the .icns via sips/ImageMagick.
ORIG_SRC="$(ls -Sl "$ORIG_ICONSET"/icon_*x*.png 2>/dev/null | awk 'NR==1{print $9}')"
if [[ -z "$ORIG_SRC" ]]; then
  ORIG_SRC="$WORKDIR/orig_fallback.png"
  if command -v sips >/dev/null 2>&1; then
    sips -s format png "$ORIG_ICNS" --out "$ORIG_SRC" >/dev/null || true
  else
    "$IM" "$ORIG_ICNS" "$ORIG_SRC" || true
  fi
fi
if [[ ! -f "$ORIG_SRC" ]]; then
  echo "Failed to extract base icon image from $ORIG_ICNS" >&2
  exit 1
fi

# Determine the largest available original frame size (for info / heuristics)
orig_max_px() {
  local setdir="$1" src="$2" max=0 sz
  if compgen -G "$setdir/icon_*x*.png" >/dev/null; then
    while IFS= read -r p; do
      sz=$(sips -g pixelWidth "$p" 2>/dev/null | awk '/pixelWidth/ {print $2}')
      [[ -n "$sz" ]] || continue
      (( sz > max )) && max=$sz
    done < <(ls -1 "$setdir"/icon_*x*.png 2>/dev/null || true)
  fi
  if (( max == 0 )) && [[ -f "$src" ]]; then
    max=$(sips -g pixelWidth "$src" 2>/dev/null | awk '/pixelWidth/ {print $2}')
  fi
  echo "${max:-0}"
}

ORIG_MAX="$(orig_max_px "$ORIG_ICONSET" "$ORIG_SRC")"
echo "Original largest frame: ${ORIG_MAX}px"

# Choose a badge source PNG (largest available). If iconutil produced no PNGs,
# extract a single PNG directly from the .icns via sips/ImageMagick.
BADGE_SRC="$(ls -Sl "$BADGE_ICONSET"/icon_*x*.png 2>/dev/null | awk 'NR==1{print $9}')"
if [[ -z "$BADGE_SRC" ]]; then
  BADGE_SRC="$WORKDIR/badge_fallback.png"
  if command -v sips >/dev/null 2>&1; then
    sips -s format png "$BADGE_ICNS" --out "$BADGE_SRC" >/dev/null
  else
    "$IM" "$BADGE_ICNS" "$BADGE_SRC"
  fi
fi
if [[ ! -f "$BADGE_SRC" ]]; then
  echo "Failed to extract badge image from $BADGE_ICNS" >&2
  exit 1
fi

# AFTER expanding badge iconset and choosing BADGE_SRC, add this:

# Determine the largest available badge frame size
badge_max_px() {
  local setdir="$1"
  local max=0 sz
  # Prefer iconutil frames; else inspect the fallback PNG
  if compgen -G "$setdir/icon_*x*.png" >/dev/null; then
    while IFS= read -r p; do
      sz=$(sips -g pixelWidth "$p" 2>/dev/null | awk '/pixelWidth/ {print $2}')
      [[ -n "$sz" ]] || continue
      (( sz > max )) && max=$sz
    done < <(ls -1 "$setdir"/icon_*x*.png 2>/dev/null || true)
  elif [[ -f "$BADGE_SRC" ]]; then
    max=$(sips -g pixelWidth "$BADGE_SRC" 2>/dev/null | awk '/pixelWidth/ {print $2}')
  fi
  echo "${max:-0}"
}

BADGE_MAX="$(badge_max_px "$BADGE_ICONSET")"
if [[ -z "$BADGE_MAX" || "$BADGE_MAX" -le 0 ]]; then
  echo "Could not determine badge size; using 128px as a conservative default." >&2
  BADGE_MAX=128
fi
echo "Badge largest frame: ${BADGE_MAX}px"

# Helper: upscale with a decent filter when needed
scale_badge() { # $1: src, $2: target px, $3: out
  local src="$1" target="$2" out="$3"
  # Use Lanczos; add mild sharpening after major upscales
  if [[ "$IM" == "magick" || "$IM" == "convert" ]]; then
    "$IM" "$src" -filter Lanczos -resize "${target}x${target}" \
      \( +clone -blur 0x0.5 \) -compose overlay -composite \
      "$out"
  else
    # Fallback to sips (no filter control)
    sips -s format png -z "$target" "$target" "$src" --out "$out" >/dev/null
  fi
}

# Target sizes we want to fill (standard Apple iconset)
# For each base we also fill the @2x variant automatically
BASE_SIZES=(16 32 128 256 512)
# Compute geometry params from size:
# - badge scale ~38% of base
# - padding ~6% of base
badge_scale() { # $1: base size -> echo integer pixel size for badge
  local base="$1"
  # round to nearest
  awk "BEGIN{printf \"%d\", ($base*0.38)+0.5}"
}
pad_px() { # $1: base size -> echo padding pixels
  local base="$1"
  awk "BEGIN{printf \"%d\", ($base*0.06)+0.5}"
}

# Helper to find a suitable source PNG in an iconset; if missing, upscale from largest available
find_or_scale_icon() { # $1: iconset dir, $2: desired size -> stdout: path to generated file
  local setdir="$1"
  local size="$2"
  local name="icon_${size}x${size}.png"
  local src="$setdir/$name"

  if [[ -f "$src" ]]; then
    echo "$src"
    return 0
  fi

  local largest
  largest="$(ls -Sl "$setdir"/icon_*x*.png 2>/dev/null | awk 'NR==1{print $9}')"

  # If iconutil didn't produce any PNGs, fall back to the extracted ORIG_SRC
  if [[ -z "$largest" ]]; then
    if [[ -f "$ORIG_SRC" ]]; then
      largest="$ORIG_SRC"
    else
      echo "Missing PNGs in iconset and no fallback source available: $setdir" >&2
      exit 1
    fi
  fi

  # Scale down (or up) to desired size from the best available source
  local out="$WORKDIR/scaled_${size}.png"
  "$IM" "$largest" -resize "${size}x${size}" "$out"
  echo "$out"
}

echo "Compositing sizes…"
for base in "${BASE_SIZES[@]}"; do
  for scale in 1 2; do
    target=$(( base * scale ))
    name="icon_${base}x${base}"
    [[ $scale -eq 2 ]] && name="${name}@2x"
    out="$OUT_ICONSET/${name}.png"

    # Base layer from original iconset (fallback to scaling)
    base_png="$(find_or_scale_icon "$ORIG_ICONSET" "$target")"

    # Compute badge and padding sizes
    bpx="$(badge_scale "$target")"
    ppx="$(pad_px "$target")"

    # Clamp badge size to available max; upscale if needed (warn on big jumps)
    use_bpx="$bpx"
    if (( use_bpx > BADGE_MAX )); then
      # We’ll upscale from BADGE_MAX to use_bpx for better quality than letting IM scale on-the-fly
      echo "Note: upscaling badge from ${BADGE_MAX}px to ${use_bpx}px for ${name}" >&2
      upscaled="$WORKDIR/badge_${use_bpx}.png"
      scale_badge "$BADGE_SRC" "$use_bpx" "$upscaled"
      badge_for_this="$upscaled"
    else
      # Either exact or downscale from BADGE_SRC
      badge_for_this="$WORKDIR/badge_${use_bpx}.png"
      "$IM" "$BADGE_SRC" -resize "${use_bpx}x${use_bpx}" "$badge_for_this"
    fi

    # Composite
    "$IM" "$base_png" \
      \( "$badge_for_this" \) \
      -gravity southeast -geometry "+${ppx}+${ppx}" \
      -composite "$out"
  done
done

# Build icns
WRAP_ICNS="$WORKDIR/WrapperIcon.icns"
iconutil -c icns -o "$WRAP_ICNS" "$OUT_ICONSET"
echo "Built: $WRAP_ICNS"

# Install into wrapper
WRAP_RES="$WRAP_APP/Contents/Resources"
WRAP_PLIST="$WRAP_APP/Contents/Info.plist"
mkdir -p "$WRAP_RES"
cp "$WRAP_ICNS" "$WRAP_RES/WrapperIcon.icns"

# Update CFBundleIconFile (value should be basename without extension)
if [[ -f "$WRAP_PLIST" ]]; then
  set +e
  "$PLISTBUDDY" -c "Set :CFBundleIconFile WrapperIcon" "$WRAP_PLIST" 2>/dev/null
  if [[ $? -ne 0 ]]; then
    "$PLISTBUDDY" -c "Add :CFBundleIconFile string WrapperIcon" "$WRAP_PLIST"
  fi
  set -e
else
  echo "Warning: Wrapper Info.plist not found; cannot set CFBundleIconFile. Continuing…" >&2
fi

# Refresh Finder/Dock icon caches
# Touching the .app and restarting Finder/Dock usually refreshes, but full cache reset may still be needed on some macOS versions
# (e.g., `sudo find /private/var/folders -name com.apple.dock.iconcache -delete; killall Dock`)

touch "$WRAP_APP"
killall Finder || true
killall Dock || true

echo "✅ Installed wrapper icon with Automator badge into:"
echo "   $WRAP_APP"

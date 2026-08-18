#!/usr/bin/env bash
# Build a GitHub-ready CarrotType .dmg (unsigned / self-signed — no notarization).
#
# Usage (from repo root or macos/):
#   ./macos/scripts/build-release-dmg.sh
#
# Optional env:
#   VERSION=0.1.0          # defaults to CFBundleShortVersionString from project.yml
#   CONFIGURATION=Release
#   SIGN_IDENTITY="CarrotType Development"  # or "-" for ad-hoc
#   SKIP_CODESIGN=1
#   CLEAN=1                # wipe macos/.derivedData-release before build (full rebuild)
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MACOS="$ROOT/macos"
DIST="$ROOT/dist"
PACKAGING_DMG="$MACOS/packaging/dmg"
LAYOUT="$PACKAGING_DMG/layout.sh"
# shellcheck source=../packaging/dmg/layout.sh
source "$LAYOUT"
CONFIGURATION="${CONFIGURATION:-Release}"
VERSION="${VERSION:-}"
SIGN_IDENTITY="${SIGN_IDENTITY:-CarrotType Development}"

if [[ -z "$VERSION" ]]; then
  VERSION="$(
    python3 - <<'PY' "$MACOS/project.yml"
import re, sys
text = open(sys.argv[1]).read()
m = re.search(r'CFBundleShortVersionString:\s*"([^"]+)"', text)
print(m.group(1) if m else "0.1.0")
PY
  )"
fi

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
if [[ ! -d "$DEVELOPER_DIR" ]]; then
  echo "ERROR: Xcode not found at $DEVELOPER_DIR" >&2
  exit 1
fi

cd "$MACOS"
if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
fi

DERIVED="$MACOS/.derivedData-release"
if [[ "${CLEAN:-0}" == "1" ]]; then
  echo "==> CLEAN=1 — wiping $DERIVED"
  rm -rf "$DERIVED"
else
  echo "==> Reusing DerivedData at $DERIVED (set CLEAN=1 for a full rebuild)"
fi
mkdir -p "$DERIVED" "$DIST"

echo "==> Building CarrotType $VERSION ($CONFIGURATION, arm64)"
xcodebuild \
  -project CarrotType.xcodeproj \
  -scheme CarrotType \
  -configuration "$CONFIGURATION" \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED" \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  COMPILER_INDEX_STORE_ENABLE=NO \
  ONLY_ACTIVE_ARCH=YES \
  build

APP="$(find "$DERIVED/Build/Products/$CONFIGURATION" -maxdepth 1 -name 'CarrotType.app' -print -quit)"
if [[ -z "$APP" || ! -d "$APP" ]]; then
  echo "ERROR: CarrotType.app not found under $DERIVED/Build/Products/$CONFIGURATION" >&2
  exit 1
fi

STAGE="$DIST/dmg-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/CarrotType.app"
ln -s /Applications "$STAGE/Applications"

ENTITLEMENTS="$MACOS/CarrotType/CarrotType.entitlements"

resign_app_bundle() {
  local app_path="$1"
  local identity="$2"
  local frameworks="$app_path/Contents/Frameworks"
  local macos_dir="$app_path/Contents/MacOS"

  # Inside-out: dylibs → frameworks → helper tool → app (same identity for all).
  if [[ -d "$frameworks" ]]; then
    find "$frameworks" -name '*.dylib' -type f | while read -r dylib; do
      codesign --force --sign "$identity" --timestamp=none "$dylib"
    done
    find "$frameworks" -maxdepth 1 -name '*.framework' -type d | while read -r fw; do
      codesign --force --sign "$identity" --timestamp=none "$fw"
    done
  fi

  # ADR-009: Smart cleanup helper (signed before the outer .app) + MLX shader bundle in Resources.
  if [[ -x "$macos_dir/CarrotTypeCleanupHelper" ]]; then
    codesign --force --sign "$identity" --timestamp=none "$macos_dir/CarrotTypeCleanupHelper"
  else
    echo "ERROR: CarrotTypeCleanupHelper missing under $macos_dir" >&2
    exit 1
  fi
  if [[ ! -d "$app_path/Contents/Resources/mlx-swift_Cmlx.bundle" ]]; then
    echo "ERROR: mlx-swift_Cmlx.bundle missing under Contents/Resources (MLX shaders)" >&2
    exit 1
  fi

  # Self-signed / ad-hoc: do NOT use --options runtime.
  # Hardened Runtime enforces Team ID matching on embedded frameworks and
  # crashes at launch with "different Team IDs" even when both Team IDs are empty.
  # Entitlements still include disable-library-validation for safety.
  local extra=()
  if [[ -f "$ENTITLEMENTS" ]]; then
    extra+=(--entitlements "$ENTITLEMENTS")
  fi
  codesign --force "${extra[@]}" --sign "$identity" --timestamp=none "$app_path"
  codesign --verify --deep --strict "$app_path"
  echo "==> Embedded entitlements:"
  codesign -d --entitlements :- "$app_path" 2>/dev/null | plutil -p - 2>/dev/null || true
}
if [[ "${SKIP_CODESIGN:-0}" != "1" ]]; then
  if [[ "$SIGN_IDENTITY" == "-" ]] || ! security find-identity -v -p codesigning 2>/dev/null | grep -F "$SIGN_IDENTITY" >/dev/null; then
    echo "==> Codesign identity '$SIGN_IDENTITY' not found — using ad-hoc (-)"
    SIGN_IDENTITY="-"
  else
    echo "==> Codesign with: $SIGN_IDENTITY"
  fi
  resign_app_bundle "$STAGE/CarrotType.app" "$SIGN_IDENTITY"
fi

DMG_NAME="CarrotType-${VERSION}.dmg"
DMG_PATH="$DIST/$DMG_NAME"
RW_DMG="$DIST/CarrotType-rw.dmg"
BG_SRC="$PACKAGING_DMG/background@2x.png"
rm -f "$DMG_PATH" "$RW_DMG"

if [[ ! -f "$BG_SRC" ]]; then
  echo "ERROR: missing $BG_SRC (run: swift macos/scripts/render-dmg-background.swift)" >&2
  exit 1
fi

VOLUME="/Volumes/${DMG_VOLNAME}"
if [[ -d "$VOLUME" ]]; then
  echo "==> Detaching leftover $VOLUME"
  hdiutil detach "$VOLUME" -quiet || hdiutil detach "$VOLUME" -force || true
  sleep 1
fi

echo "==> Creating read-write $RW_DMG"
hdiutil create \
  -volname "$DMG_VOLNAME" \
  -srcfolder "$STAGE" \
  -ov \
  -fs HFS+ \
  -format UDRW \
  "$RW_DMG"

echo "==> Attaching $RW_DMG"
MOUNT_OUTPUT="$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG")"
echo "$MOUNT_OUTPUT"
DEVICE="$(echo "$MOUNT_OUTPUT" | awk 'NR==1 { print $1 }')"
if [[ -z "$DEVICE" || ! -d "$VOLUME" ]]; then
  echo "ERROR: failed to mount $RW_DMG at $VOLUME" >&2
  exit 1
fi

detach_rw() {
  hdiutil detach "$DEVICE" -quiet 2>/dev/null \
    || hdiutil detach "$VOLUME" -force 2>/dev/null \
    || true
}
trap detach_rw EXIT

echo "==> Installing Finder background"
mkdir -p "$VOLUME/.background"
sips -s format tiff -s dpiWidth 144 -s dpiHeight 144 \
  "$BG_SRC" --out "$VOLUME/.background/background.tiff" >/dev/null
chflags hidden "$VOLUME/.background"

WINDOW_RIGHT=$((DMG_WINDOW_LEFT + DMG_WINDOW_WIDTH))
WINDOW_BOTTOM=$((DMG_WINDOW_TOP + DMG_WINDOW_HEIGHT))

echo "==> Applying Finder window layout"
osascript <<EOF
tell application "Finder"
  tell disk "$DMG_VOLNAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set sidebar width of container window to 0
    set the bounds of container window to {${DMG_WINDOW_LEFT}, ${DMG_WINDOW_TOP}, ${WINDOW_RIGHT}, ${WINDOW_BOTTOM}}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to ${DMG_ICON_SIZE}
    set background picture of theViewOptions to file ".background:background.tiff"
    set position of item "CarrotType.app" of container window to {${DMG_APP_X}, ${DMG_APP_Y}}
    set position of item "Applications" of container window to {${DMG_APPS_X}, ${DMG_APPS_Y}}
    close
    open
    update without registering applications
    delay 3
    close
  end tell
end tell
EOF

sync
echo "==> Detaching $DEVICE"
trap - EXIT
detach_rw
sleep 1

echo "==> Converting $DMG_PATH"
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"
rm -f "$RW_DMG"
rm -rf "$STAGE"

echo
echo "OK: $DMG_PATH"
echo "SHA256: $(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
echo
echo "GitHub Release: attach this .dmg. Gatekeeper will block until users Right-click → Open"
echo "(no Apple Developer ID notarization in this build)."

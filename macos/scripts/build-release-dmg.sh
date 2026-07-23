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
rm -f "$DMG_PATH"

echo "==> Creating $DMG_PATH"
hdiutil create \
  -volname "CarrotType" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGE"

echo
echo "OK: $DMG_PATH"
echo "SHA256: $(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
echo
echo "GitHub Release: attach this .dmg. Gatekeeper will block until users Right-click → Open"
echo "(no Apple Developer ID notarization in this build)."

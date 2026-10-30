#!/usr/bin/env bash
# Submit a Release DMG to Apple notarytool, wait, and staple.
# Requires a Developer ID signed DMG and a Keychain notary profile (no secrets in-repo).
#
# Usage:
#   ./macos/scripts/notarize-dmg.sh dist/CarrotType-0.3.6.dmg
#   NOTARY_PROFILE=carrottype-notary ./macos/scripts/notarize-dmg.sh path/to.dmg
#
# Create the profile once (ops/deploy.md / ops/notarization.env.example):
#   xcrun notarytool store-credentials "carrottype-notary" \
#     --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-password"

set -euo pipefail

DMG_PATH="${1:-}"
PROFILE="${NOTARY_PROFILE:-carrottype-notary}"

if [[ -z "${DMG_PATH}" ]]; then
  echo "Usage: $0 <path-to.dmg>" >&2
  exit 2
fi

if [[ ! -f "${DMG_PATH}" ]]; then
  echo "ERROR: DMG not found: ${DMG_PATH}" >&2
  exit 1
fi

if ! xcrun notarytool history --keychain-profile "${PROFILE}" >/dev/null 2>&1; then
  echo "ERROR: notarytool Keychain profile '${PROFILE}' is missing or unusable." >&2
  echo "Create it with: xcrun notarytool store-credentials \"${PROFILE}\" \\" >&2
  echo "  --apple-id \"…\" --team-id \"…\" --password \"app-specific-password\"" >&2
  echo "See ops/deploy.md and ops/notarization.env.example." >&2
  exit 1
fi

echo "Submitting ${DMG_PATH} with profile ${PROFILE}…"
xcrun notarytool submit "${DMG_PATH}" \
  --keychain-profile "${PROFILE}" \
  --wait

echo "Stapling…"
xcrun stapler staple "${DMG_PATH}"

echo "Assessing…"
spctl --assess --type open --verbose "${DMG_PATH}" || true
echo "Done. Verify on a clean Mac that double-click opens without Open Anyway."

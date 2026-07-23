#!/bin/bash
# Re-sign the built .app with a stable identity when available so TCC grants
# (Accessibility) survive rebuilds. Safe no-op if the cert is missing.
set -euo pipefail

CERT_NAME="CarrotType Development"
APP_PATH="${TARGET_BUILD_DIR:?}/${FULL_PRODUCT_NAME:?}"
ENTITLEMENTS="${CODE_SIGN_ENTITLEMENTS:-}"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "note: skip stable resign — app not found at ${APP_PATH}"
  exit 0
fi

if ! security find-identity -v -p codesigning 2>/dev/null | grep -F "${CERT_NAME}" >/dev/null; then
  echo "note: «${CERT_NAME}» not found — keeping Xcode signature (ad-hoc)."
  echo "      Run macos/scripts/ensure-dev-codesign.sh once to keep Accessibility across Rebuild."
  exit 0
fi

ENTITLEMENTS_ARGS=()
# Prefer the expanded entitlements from the build if present.
DERIVED_ENTITLEMENTS="${TARGET_TEMP_DIR:-}/CarrotType.app.xcent"
if [[ -f "${DERIVED_ENTITLEMENTS}" ]]; then
  ENTITLEMENTS_ARGS=(--entitlements "${DERIVED_ENTITLEMENTS}")
elif [[ -n "${ENTITLEMENTS}" && -f "${SRCROOT}/${ENTITLEMENTS}" ]]; then
  ENTITLEMENTS_ARGS=(--entitlements "${SRCROOT}/${ENTITLEMENTS}")
elif [[ -n "${ENTITLEMENTS}" && -f "${ENTITLEMENTS}" ]]; then
  ENTITLEMENTS_ARGS=(--entitlements "${ENTITLEMENTS}")
fi

echo "Re-signing with stable identity: ${CERT_NAME}"
# --deep covers CarrotType.debug.dylib and embedded frameworks from SPM.
codesign --force --deep --sign "${CERT_NAME}" --timestamp=none \
  --options runtime \
  "${ENTITLEMENTS_ARGS[@]}" \
  "${APP_PATH}"

codesign -dv --verbose=2 "${APP_PATH}" 2>&1 | grep -E 'Authority|Identifier|Format|flags' || true
codesign --verify --deep --strict "${APP_PATH}"

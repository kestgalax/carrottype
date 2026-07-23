#!/bin/bash
# Creates a stable self-signed codesign identity so Accessibility / Microphone
# TCC grants survive Xcode rebuilds (ad-hoc signing resets them every build).
#
# Run once per machine:
#   ./macos/scripts/ensure-dev-codesign.sh
#
set -euo pipefail

CERT_NAME="CarrotType Development"
KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"
P12_PASS="carrottype-dev"
TMPDIR_CERT="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR_CERT"; }
trap cleanup EXIT

if security find-identity -v -p codesigning 2>/dev/null | grep -F "${CERT_NAME}" >/dev/null; then
  echo "OK: codesigning identity already present: ${CERT_NAME}"
  security find-identity -v -p codesigning | grep -F "${CERT_NAME}" || true
  exit 0
fi

OPENSSL_BIN="${OPENSSL_BIN:-}"
if [[ -z "${OPENSSL_BIN}" ]]; then
  if [[ -x /opt/homebrew/opt/openssl@3/bin/openssl ]]; then
    OPENSSL_BIN=/opt/homebrew/opt/openssl@3/bin/openssl
  elif [[ -x /usr/local/opt/openssl@3/bin/openssl ]]; then
    OPENSSL_BIN=/usr/local/opt/openssl@3/bin/openssl
  else
    OPENSSL_BIN="$(command -v openssl)"
  fi
fi

if "${OPENSSL_BIN}" version 2>/dev/null | grep -q LibreSSL; then
  echo "ERROR: нужен OpenSSL (не LibreSSL). Установите: brew install openssl@3" >&2
  echo "Потом: OPENSSL_BIN=\$(brew --prefix openssl@3)/bin/openssl $0" >&2
  exit 1
fi

echo "Creating self-signed codesign cert: ${CERT_NAME}"
echo "Using OpenSSL: $("${OPENSSL_BIN}" version)"

"${OPENSSL_BIN}" req -x509 -newkey rsa:2048 \
  -keyout "${TMPDIR_CERT}/dev.key" \
  -out "${TMPDIR_CERT}/dev.crt" \
  -days 7300 -nodes \
  -subj "/CN=${CERT_NAME}/O=CarrotType" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=codeSigning"

# Empty P12 passwords often fail Keychain MAC checks on recent macOS.
LEGACY_FLAG=()
if "${OPENSSL_BIN}" pkcs12 -help 2>&1 | grep -q -- '-legacy'; then
  LEGACY_FLAG=(-legacy)
fi

"${OPENSSL_BIN}" pkcs12 -export \
  "${LEGACY_FLAG[@]}" \
  -out "${TMPDIR_CERT}/dev.p12" \
  -inkey "${TMPDIR_CERT}/dev.key" \
  -in "${TMPDIR_CERT}/dev.crt" \
  -passout "pass:${P12_PASS}" \
  -name "${CERT_NAME}"

IMPORT_OK=0
if security import "${TMPDIR_CERT}/dev.p12" \
  -k "${KEYCHAIN}" \
  -P "${P12_PASS}" \
  -T /usr/bin/codesign \
  -T /usr/bin/security; then
  IMPORT_OK=1
fi

# Retry without -legacy packaging if first path failed earlier in export; already exported with legacy.
if [[ "${IMPORT_OK}" -ne 1 ]]; then
  echo "Retrying PKCS#12 import with A → login keychain…"
  security import "${TMPDIR_CERT}/dev.p12" \
    -k "${KEYCHAIN}" \
    -P "${P12_PASS}" \
    -A \
    -T /usr/bin/codesign \
    -T /usr/bin/security
  IMPORT_OK=1
fi

# User-domain trust (no sudo). Enough for local codesign.
if ! security add-trusted-cert -r trustRoot -k "${KEYCHAIN}" "${TMPDIR_CERT}/dev.crt"; then
  echo "WARN: add-trusted-cert failed — откройте Keychain Access → сертификат «${CERT_NAME}» → Trust → Code Signing = Always Trust." >&2
fi

security set-key-partition-list \
  -S "apple-tool:,apple:,codesign:" \
  -s -l "${CERT_NAME}" \
  "${KEYCHAIN}" >/dev/null 2>&1 || true

if security find-identity -v -p codesigning | grep -F "${CERT_NAME}" >/dev/null; then
  echo "OK: ${CERT_NAME} ready."
  echo "Дальше: cd macos && xcodegen generate, Rebuild в Xcode, один раз снова включите Универсальный доступ."
else
  echo "ERROR: сертификат не виден как codesigning identity." >&2
  echo "Откройте Keychain Access → login → My Certificates и проверьте «${CERT_NAME}»." >&2
  exit 1
fi

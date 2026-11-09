#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_TMP="$(mktemp -d "${TMPDIR:-/tmp}/carrottype-ultra.XXXXXX")"
trap 'rm -rf "$TASK_TMP"' EXIT
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
swiftc -parse-as-library \
  "$TASK_ROOT/macos/CarrotType/Services/LegacySTTStorage.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/DictationModelPolicy.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/ModelTypes.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/BundledModelCatalog.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/AppLanguage.swift" \
  "$TASK_ROOT/scripts/tests/UltraModelChecks.swift" -o "$TASK_TMP/checks"
"$TASK_TMP/checks" "$TASK_ROOT/macos/CarrotType/Resources/ModelCatalog.json"

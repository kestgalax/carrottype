#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_TMP="$(mktemp -d "${TMPDIR:-/tmp}/carrottype-island.XXXXXX")"
trap 'rm -rf "$TASK_TMP"' EXIT
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
swiftc -parse-as-library \
  "$TASK_ROOT/macos/CarrotType/Models/LanguageResolution.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/AppLanguage.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/DynamicIslandMode.swift" \
  "$TASK_ROOT/scripts/tests/DynamicIslandChecks.swift" -o "$TASK_TMP/checks"
"$TASK_TMP/checks"

#!/bin/bash
# Exercises production code with isolated pasteboards and disposable helper processes.
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_TMP="$(mktemp -d "${TMPDIR:-/tmp}/carrottype-reliability.XXXXXX")"
trap 'rm -rf "$TASK_TMP"' EXIT
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
swiftc -parse-as-library \
  "$TASK_ROOT/macos/Shared/DictationRules.swift" \
  "$TASK_ROOT/macos/CarrotType/Services/ClipboardSnapshot.swift" \
  "$TASK_ROOT/macos/CarrotType/Services/SelectionTextService.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/LanguageResolution.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/AppLanguage.swift" \
  "$TASK_ROOT/macos/CarrotType/Services/CleanupHelperTransport.swift" \
  "$TASK_ROOT/macos/Shared/CleanupHelperProtocol.swift" \
  "$TASK_ROOT/scripts/tests/DictationReliabilityChecks.swift" \
  -o "$TASK_TMP/checks"
"$TASK_TMP/checks" --check

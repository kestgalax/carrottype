#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_TMP="$(mktemp -d "${TMPDIR:-/tmp}/carrottype-release-notes.XXXXXX")"
trap 'rm -rf "$TASK_TMP"' EXIT
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
swiftc -parse-as-library "$TASK_ROOT/macos/CarrotType/Models/LanguageResolution.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/AppLanguage.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/ReleaseNotes.swift" \
  "$TASK_ROOT/scripts/tests/ReleaseNotesChecks.swift" -o "$TASK_TMP/checks"
"$TASK_TMP/checks" "$TASK_ROOT" "$TASK_TMP"
python3 "$TASK_ROOT/scripts/tests/test_release_notes.py"

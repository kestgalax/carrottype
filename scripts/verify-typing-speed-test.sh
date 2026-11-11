#!/bin/bash
# Production typing-speed model fixtures. No UI, device, model or network.
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_TMP="$(mktemp -d "${TMPDIR:-/tmp}/carrottype-typing-speed.XXXXXX")"
trap 'rm -rf "$TASK_TMP"' EXIT
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
xcrun --sdk macosx swiftc -parse-as-library \
  "$TASK_ROOT/macos/CarrotType/Models/AppLanguage.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/UsageStatsEstimate.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/TypingTestCorpus.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/TypingSpeedTest.swift" \
  "$TASK_ROOT/scripts/tests/TypingSpeedTestChecks.swift" -o "$TASK_TMP/checks"
"$TASK_TMP/checks"

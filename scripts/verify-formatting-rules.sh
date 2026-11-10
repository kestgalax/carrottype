#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_TMP="$(mktemp -d "${TMPDIR:-/tmp}/carrottype-rules.XXXXXX")"
trap 'rm -rf "$TASK_TMP"' EXIT
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
swiftc -parse-as-library \
  "$TASK_ROOT/macos/Shared/DictationRules.swift" \
  "$TASK_ROOT/macos/Shared/CleanupHelperProtocol.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/AppLanguage.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/AppTheme.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/ModelTypes.swift" \
  "$TASK_ROOT/macos/CarrotType/Models/BundledModelCatalog.swift" \
  "$TASK_ROOT/macos/CarrotType/Services/TextCleanup.swift" \
  "$TASK_ROOT/macos/CarrotType/Services/Engines/DictationFormatting.swift" \
  "$TASK_ROOT/macos/CarrotType/Services/Engines/LightCleanupEngine.swift" \
  "$TASK_ROOT/scripts/tests/FormattingRulesChecks.swift" -o "$TASK_TMP/checks"
"$TASK_TMP/checks"

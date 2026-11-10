#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_TMP="$(mktemp -d "${TMPDIR:-/tmp}/carrottype-session.XXXXXX")"
trap 'rm -rf "$TASK_TMP"' EXIT
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
swiftc -parse-as-library "$TASK_ROOT/macos/CarrotType/Services/UpdateInstallationGate.swift" \
  "$TASK_ROOT/macos/CarrotType/Services/DictationSessionCoordinator.swift" \
  "$TASK_ROOT/scripts/tests/DictationSessionChecks.swift" -o "$TASK_TMP/checks"
"$TASK_TMP/checks"

cp "$TASK_ROOT/scripts/verify-live-draft-sanitize.swift" "$TASK_TMP/main.swift"
swiftc "$TASK_ROOT/macos/CarrotType/Services/Engines/LiveDraftText.swift" "$TASK_TMP/main.swift" -o "$TASK_TMP/draft"
"$TASK_TMP/draft"
cp "$TASK_ROOT/scripts/verify-wave-link-port-order.swift" "$TASK_TMP/main.swift"
swiftc "$TASK_ROOT/macos/CarrotType/Services/WaveLinkPortOrder.swift" "$TASK_TMP/main.swift" -o "$TASK_TMP/ports"
"$TASK_TMP/ports"
swiftc -emit-library -emit-module -module-name FluidAudio \
  "$TASK_ROOT/scripts/tests/fixtures/FluidAudio.swift" -o "$TASK_TMP/libFluidAudio.dylib" \
  -emit-module-path "$TASK_TMP/FluidAudio.swiftmodule"
swiftc -parse-as-library -I "$TASK_TMP" -L "$TASK_TMP" -lFluidAudio -Xlinker -rpath -Xlinker "$TASK_TMP" \
  "$TASK_ROOT/macos/CarrotType/Models/AppLanguage.swift" \
  "$TASK_ROOT/macos/CarrotType/Services/Engines/STTEngineError.swift" \
  "$TASK_ROOT/macos/CarrotType/Services/ConvertedBufferFanout.swift" \
  "$TASK_ROOT/macos/CarrotType/Services/Engines/StreamingSTTEngine.swift" \
  "$TASK_ROOT/macos/CarrotType/Services/Engines/LiveDraftText.swift" \
  "$TASK_ROOT/macos/CarrotType/Services/Engines/ParakeetStreamingEngine.swift" \
  "$TASK_ROOT/scripts/tests/StreamingEpochChecks.swift" -o "$TASK_TMP/streaming"
"$TASK_TMP/streaming"

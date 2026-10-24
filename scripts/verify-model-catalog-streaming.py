#!/usr/bin/env python3
"""Linux-runnable check: ModelCatalog.json supportsStreaming flags (ADR-014)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "macos/CarrotType/Resources/ModelCatalog.json"

EXPECT_TRUE = {
    "stt.parakeet-tdt-0.6b-v3",
    "stt.parakeet-ultra",
}
EXPECT_FALSE = {
    "stt.whisper-base-ggml",
    "stt.whisper-small-ggml",
    "stt.whisper-large-v3-turbo-q5",
    "stt.apple-speechanalyzer",
}


def main() -> int:
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    if data.get("version", 0) < 9:
        print(f"FAIL: catalog version must be >= 9, got {data.get('version')}", file=sys.stderr)
        return 1

    packages = {p["id"]: p for p in data["packages"]}
    errors: list[str] = []

    for pid in EXPECT_TRUE | EXPECT_FALSE:
        if pid not in packages:
            errors.append(f"missing package {pid}")
            continue
        flag = packages[pid].get("supportsStreaming")
        want = pid in EXPECT_TRUE
        if flag is not want:
            errors.append(f"{pid}: supportsStreaming={flag!r}, expected {want}")

    for pid, pkg in packages.items():
        if pkg.get("role") != "stt":
            continue
        if "supportsStreaming" not in pkg:
            errors.append(f"{pid}: missing supportsStreaming key")

    if errors:
        print("FAIL:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    print("OK: ModelCatalog.json streaming flags (version", data["version"], ")")
    for pid in sorted(EXPECT_TRUE | EXPECT_FALSE):
        print(f"  {pid}: {packages[pid]['supportsStreaming']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

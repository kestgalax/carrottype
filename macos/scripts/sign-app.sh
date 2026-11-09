#!/bin/bash
# Sign a built copy inside-out, including Sparkle's installer/app/XPC components.
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TASK_APP="${1:?Usage: sign-app.sh /path/to/CarrotType.app [identity]}"
TASK_IDENTITY="${2:-CarrotType Development}"
python3 - "$TASK_APP" "$TASK_IDENTITY" "$TASK_ROOT/macos/CarrotType/CarrotType.entitlements" <<'PY'
import pathlib, subprocess, sys
app = pathlib.Path(sys.argv[1]).resolve()
identity, entitlements = sys.argv[2:]
if not app.is_dir() or app.suffix != '.app':
    raise SystemExit('Expected a built app bundle')
helper = app / 'Contents/MacOS/CarrotTypeCleanupHelper'
if not helper.is_file() or not (app / 'Contents/Resources/mlx-swift_Cmlx.bundle').is_dir():
    raise SystemExit('Missing cleanup helper or MLX shader bundle')
frameworks = app / 'Contents/Frameworks'
targets = set()
for path in frameworks.rglob('*'):
    if path.is_symlink():
        continue
    if path.suffix in ('.app', '.xpc', '.framework', '.dylib') or path.name == 'Autoupdate':
        targets.add(path)
for path in sorted(targets, key=lambda p: len(p.parts), reverse=True) + [helper, app]:
    args = ['codesign', '--force', '--sign', identity, '--timestamp=none', '--options', '0']
    if path != app:
        args += ['--preserve-metadata=entitlements']
    if path == app:
        args += ['--entitlements', entitlements]
    subprocess.run(args + [str(path)], check=True)
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
PY

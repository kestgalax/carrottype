#!/usr/bin/env python3
"""Check actual AppState/coordinator presentation policy after a local Debug build.

Usage: python3 scripts/verify-dynamic-island-app.py --build-log /tmp/debug.log
All mutations are inside a temporary staging app and unique defaults domain. No
microphone, model, clipboard, WAV or status-panel output reaches the real user UI.
Native offscreen snapshots are written under dist/.builds.noindex by default.
"""
import argparse
import os
from pathlib import Path
import plistlib
import shlex
import subprocess
import tempfile
import uuid

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--build-log', type=Path, required=True)
parser.add_argument('--products', type=Path, default=Path('macos/.derivedData/Build/Products/Debug'))
parser.add_argument('--output', type=Path, default=Path('dist/.builds.noindex/Dynamic-Island-Native-Review'))
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
products = args.products.resolve()
lines = args.build_log.read_text().splitlines()
if not any('BUILD SUCCEEDED' in line for line in lines):
    raise SystemExit('Expected successful Debug build log')
line = next((line for line in lines if 'builtin-SwiftDriver -- ' in line and '-module-name CarrotType ' in line), None)
if line is None:
    raise SystemExit('Build log has no CarrotType compile command; supply the successful non-cached Debug build log')
driver_args = shlex.split(line.split('builtin-SwiftDriver -- ', 1)[1])
flags = []
i = 0
while i < len(driver_args):
    if driver_args[i] in ['-I', '-F', '-Xcc', '-sdk', '-target']:
        flags.extend(driver_args[i:i+2])
        i += 2
    else:
        i += 1
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='carrottype-island-app-') as directory:
    temporary = Path(directory)
    app = temporary / 'CarrotType.app'
    subprocess.run(['ditto', str(products / 'CarrotType.app'), str(app)], check=True)
    info = app / 'Contents/Info.plist'
    metadata = plistlib.loads(info.read_bytes())
    metadata.update(CFBundleIdentifier='app.carrottype.macos.update-test.dynamic-island.' + uuid.uuid4().hex,
                    SUEnableAutomaticChecks=False, SUAutomaticallyUpdate=False)
    info.write_bytes(plistlib.dumps(metadata))
    developer = Path(os.environ.get('DEVELOPER_DIR', '/Applications/Xcode.app/Contents/Developer'))
    subprocess.run([str(developer / 'Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc'),
                    '-parse-as-library', '-module-name', 'DynamicIslandAppChecks',
                    str(root / 'scripts/tests/DynamicIslandAppChecks.swift'), *flags,
                    str(app / 'Contents/MacOS/CarrotType.debug.dylib'),
                    '-Xlinker', '-rpath', '-Xlinker', str(app / 'Contents/MacOS'),
                    '-Xlinker', '-rpath', '-Xlinker', str(app / 'Contents/Frameworks'),
                    '-o', str(app / 'Contents/MacOS/CarrotType')], check=True, cwd=root / 'macos')
    subprocess.run([str(root / 'macos/scripts/sign-app.sh'), str(app), '-'], check=True)
    subprocess.run([str(app / 'Contents/MacOS/CarrotType'), str(output)],
                   check=True, timeout=120)

#!/usr/bin/env python3
"""Exercise Sparkle's real native installer on isolated A/B app bundles, never /Applications."""
import argparse
import sys
sys.dont_write_bytecode = True
import functools
import http.server
import importlib.util
import json
import pathlib
import plistlib
import shutil
import subprocess
import threading
import uuid
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'macos/scripts'))
spec = importlib.util.spec_from_file_location('update_assets', ROOT / 'macos/scripts/prepare-update.py')
assets = importlib.util.module_from_spec(spec)
spec.loader.exec_module(assets)


def run(args, **kwargs):
    return subprocess.run([str(x) for x in args], check=True, **kwargs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', required=True, type=pathlib.Path)
    parser.add_argument('--output-dir', required=True, type=pathlib.Path)
    parser.add_argument('--derived-data', type=pathlib.Path, default=ROOT / 'macos/.derivedData')
    parser.add_argument('--port', type=int, default=39187)
    parser.add_argument('--previous-version', help='Optional synthetic A marketing version for native UI review')
    args = parser.parse_args()
    if not (args.app / 'Contents/MacOS/CarrotType.debug.dylib').is_file():
        raise SystemExit('Use the Debug candidate with staging profile isolation, never a Release app')
    out = args.output_dir.resolve()
    if out.exists():
        raise SystemExit('Use a fresh staging directory; existing test artifacts are preserved')
    out.mkdir(parents=True)
    artifact = args.derived_data.resolve() / 'SourcePackages/artifacts/sparkle/Sparkle'
    framework_parent = artifact / 'Sparkle.xcframework/macos-arm64_x86_64'
    source = args.derived_data.resolve() / 'SourcePackages/checkouts/Sparkle/sparkle-cli'
    cli = out / 'sparkle-cli'
    run(['xcrun', 'clang', '-DSPU_OBJC_DIRECT_MEMBERS=', '-DSPU_OBJC_DIRECT=', '-fobjc-arc', '-fmodules',
         '-F', framework_parent, '-framework', 'Foundation', '-framework', 'AppKit', '-framework', 'Sparkle',
         '-Wl,-rpath,' + str(framework_parent), source / 'main.m', source / 'SPUCommandLineDriver.m',
         source / 'SPUCommandLineUserDriver.m', '-o', cli])
    sign = [artifact / 'bin/sign_update', '--account', assets.ACCOUNT]
    base = f'http://127.0.0.1:{args.port}'
    source_info = plistlib.loads((args.app / 'Contents/Info.plist').read_bytes())
    target_build = source_info['CFBundleVersion']
    previous_version = args.previous_version or source_info['CFBundleShortVersionString']
    previous_build = str(int(target_build) - 1)
    staging_id = 'app.carrottype.macos.update-test.' + uuid.uuid4().hex
    for label, build in [('A', previous_build), ('B', target_build)]:
        app = out / label / 'CarrotType.app'
        app.parent.mkdir()
        run(['ditto', args.app.resolve(), app])
        info_path = app / 'Contents/Info.plist'
        info = plistlib.loads(info_path.read_bytes())
        info.update(CFBundleIdentifier=staging_id, CFBundleVersion=build,
                    CFBundleShortVersionString=previous_version if label == 'A' else source_info['CFBundleShortVersionString'],
                    CFBundleDisplayName='CarrotType Update Test', SUFeedURL=base + '/good/appcast.xml',
                    SUEnableAutomaticChecks=False, SUAutomaticallyUpdate=False)
        info_path.write_bytes(plistlib.dumps(info))
        fixture_notes = app / 'Contents/Resources/ReleaseNotes.json'
        notes_data = json.loads(fixture_notes.read_text())
        notes_data['build'] = build
        notes_data['version'] = info['CFBundleShortVersionString']
        fixture_notes.write_text(json.dumps(notes_data, ensure_ascii=False, indent=2) + '\n')
        run([ROOT / 'macos/scripts/sign-app.sh', app])
    web = out / 'web'
    run(['python3', ROOT / 'macos/scripts/prepare-update.py', '--app', out / 'B/CarrotType.app',
         '--output-dir', web / 'good', '--sparkle-bin', artifact / 'bin', '--previous-build', previous_build,
         '--staging-base-url', base + '/good'])
    good = web / 'good'
    # Signed feed pointing to a corrupted archive: validation must reject before extraction.
    bad_archive = web / 'bad-archive'
    shutil.copytree(good, bad_archive)
    archive = next(bad_archive.glob('*.zip'))
    data = bytearray(archive.read_bytes())
    data[len(data) // 2] ^= 1
    archive.write_bytes(data)
    feed = bad_archive / 'appcast.xml'
    tree = ET.parse(feed)
    tree.find('channel/item/enclosure').set('url', base + '/bad-archive/' + archive.name)
    tree.write(feed, encoding='utf-8', xml_declaration=True)
    run(sign + [feed])
    # Unsigned/tampered feed must not be offered, even though the archive is valid.
    bad_feed = web / 'bad-feed'
    bad_feed.mkdir()
    (bad_feed / 'appcast.xml').write_bytes((good / 'appcast.xml').read_bytes().replace(b'CarrotType', b'Tampered', 1))
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(web))
    server = http.server.ThreadingHTTPServer(('127.0.0.1', args.port), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    app = out / 'A/CarrotType.app'
    # Byte-for-byte fixture data remains outside the replaceable app bundle.
    fixture = out / 'profile/models/preserved-model-fixture'
    fixture.parent.mkdir(parents=True)
    fixture.write_bytes(b'local model fixture; never part of the update archive')
    stats = out / 'profile/daily.json'
    stats.write_text('{"fixture": "preserve local statistics"}')
    before = {p: p.read_bytes() for p in (fixture, stats)}
    try:
        results = []
        for label, extra, succeeds in [
            ('offline', ['--feed-url', 'http://127.0.0.1:1/appcast.xml', '--probe'], False),
            ('tampered-feed', ['--feed-url', base + '/bad-feed/appcast.xml', '--probe'], False),
            ('corrupt-archive', ['--feed-url', base + '/bad-archive/appcast.xml'], False),
            ('available', ['--feed-url', base + '/good/appcast.xml', '--probe'], True),
            ('install-A-to-B', ['--feed-url', base + '/good/appcast.xml'], True),
            ('no-new-version', ['--feed-url', base + '/good/appcast.xml', '--probe'], False),
        ]:
            checked_app = app
            if label in ('offline', 'tampered-feed', 'corrupt-archive'):
                # Never let a rejected archive's native installer/resume state pollute
                # another scenario (or a prior run's manual staging profile).
                checked_app = out / ('negative-' + label) / 'CarrotType.app'
                checked_app.parent.mkdir()
                run(['ditto', app, checked_app])
                checked_info = checked_app / 'Contents/Info.plist'
                metadata = plistlib.loads(checked_info.read_bytes())
                metadata['CFBundleIdentifier'] = staging_id + '-' + label
                checked_info.write_bytes(plistlib.dumps(metadata))
                run([ROOT / 'macos/scripts/sign-app.sh', checked_app])
            checked_original = (checked_app / 'Contents/MacOS/CarrotType').read_bytes()
            log = out / (label + '.log')
            with log.open('w') as stream:
                result = subprocess.run([str(cli), str(checked_app), '--verbose',
                                         '--user-agent-name', 'CarrotType isolated verification'] + ([] if '--probe' in extra else ['--check-immediately']) + extra,
                                        stdout=stream, stderr=subprocess.STDOUT, timeout=90)
            text = log.read_text()
            assert '--probe does not work together' not in text
            expected_errors = {'offline': 'error 2001', 'tampered-feed': 'error 1000', 'corrupt-archive': 'error 4005'}
            if label in expected_errors:
                assert expected_errors[label] in text, f'{label}: wrong failure reason'
            if label == 'install-A-to-B':
                bundled_notes = assets.release_notes.load(out / 'B/CarrotType.app/Contents/Resources/ReleaseNotes.json')
                assert 'Release notes:' in text and any(
                    content['summary'] in text for content in bundled_notes['localizations'].values()
                ), 'Native Sparkle did not render the structured notes'
            current = plistlib.loads((checked_app / 'Contents/Info.plist').read_bytes())['CFBundleVersion']
            if (result.returncode == 0) != succeeds:
                raise RuntimeError(f'{label}: unexpected status {result.returncode}; see {log}')
            if label in ('offline', 'tampered-feed', 'corrupt-archive', 'available'):
                assert current == previous_build and (checked_app / 'Contents/MacOS/CarrotType').read_bytes() == checked_original
            else:
                assert current == target_build
            for path, value in before.items():
                assert path.read_bytes() == value
            results.append(f'PASS {label}: exit={result.returncode}, installed build={current}')
            print(results[-1], flush=True)
        run(['codesign', '--verify', '--deep', '--strict', app])
        assert (app / 'Contents/MacOS/CarrotTypeCleanupHelper').is_file()
        assert (app / 'Contents/Resources/mlx-swift_Cmlx.bundle/Contents/Resources/default.metallib').is_file()
        (out / 'results.txt').write_text('\n'.join(results) + '\nNative GUI/TCC: manual check still required.\n')
    finally:
        server.shutdown()
        server.server_close()
    # Restore a signed A copy for the maintainer's separate standard-UI test.
    run(['ditto', args.app.resolve(), out / 'manual-A/CarrotType.app'])
    manual = out / 'manual-A/CarrotType.app'
    info_path = manual / 'Contents/Info.plist'
    info = plistlib.loads(info_path.read_bytes())
    info.update(CFBundleIdentifier=staging_id, CFBundleVersion=previous_build,
                CFBundleShortVersionString=previous_version,
                CFBundleDisplayName='CarrotType Update Test', SUFeedURL=base + '/good/appcast.xml')
    info_path.write_bytes(plistlib.dumps(info))
    fixture_notes = manual / 'Contents/Resources/ReleaseNotes.json'
    notes_data = json.loads(fixture_notes.read_text())
    notes_data['build'] = previous_build
    notes_data['version'] = previous_version
    fixture_notes.write_text(json.dumps(notes_data, ensure_ascii=False, indent=2) + '\n')
    run([ROOT / 'macos/scripts/sign-app.sh', manual])
    (out / 'staging-identity.txt').write_text(staging_id + '\n')
    (out / 'start-server.command').write_text('#!/bin/bash\nexec python3 -m http.server ' + str(args.port)
        + ' --bind 127.0.0.1 --directory ' + "'" + str(web).replace("'", "'\\''") + "'\n")
    (out / 'start-server.command').chmod(0o755)
    print('Native installer checks passed. Manual UI/TCC checks remain; no public release was created.')


if __name__ == '__main__':
    main()

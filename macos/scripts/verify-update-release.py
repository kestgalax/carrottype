#!/usr/bin/env python3
"""Read-only release gate: download GitHub assets and verify signed stable update metadata."""
import argparse
import hashlib
import importlib.util
import json
import pathlib
import plistlib
import re
import subprocess
import sys
import tempfile
import urllib.request
import xml.etree.ElementTree as ET
import zipfile

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('update_assets', pathlib.Path(__file__).with_name('prepare-update.py'))
assets = importlib.util.module_from_spec(spec)
spec.loader.exec_module(assets)
REPO = 'kestgalax/carrottype'


def gh_json(endpoint):
    return json.loads(subprocess.check_output(['gh', 'api', endpoint]))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--tag', required=True)
    parser.add_argument('--previous-build', required=True, type=int)
    parser.add_argument('--sparkle-bin', required=True, type=pathlib.Path)
    parser.add_argument('--published', action='store_true', help='Also verify public latest endpoint and public archive')
    args = parser.parse_args()
    if not re.fullmatch(r'v\d+\.\d+\.\d+', args.tag):
        raise ValueError('Stable tag required')
    # Listing works for authenticated drafts, unlike /releases/tags on some GitHub installations.
    releases = gh_json(f'repos/{REPO}/releases?per_page=100')
    release = next(r for r in releases if r['tag_name'] == args.tag)
    if release['prerelease'] or release['draft'] == args.published:
        raise ValueError('Expected stable draft before publishing, or stable published release with --published')
    names = {a['name']: a for a in release['assets']}
    sign = [str(args.sparkle_bin.resolve() / 'sign_update'), '--account', assets.ACCOUNT, '--verify']
    with tempfile.TemporaryDirectory(prefix='carrottype-release-verify-') as folder:
        root = pathlib.Path(folder)

        def download(name):
            path = root / name
            asset = names[name]
            with path.open('wb') as stream:
                subprocess.run(['gh', 'api', '-H', 'Accept: application/octet-stream',
                                f'repos/{REPO}/releases/assets/{asset["id"]}'], stdout=stream, check=True)
            if path.stat().st_size != asset['size']:
                raise ValueError('Asset length mismatch: ' + name)
            if asset.get('digest') and asset['digest'] != 'sha256:' + hashlib.sha256(path.read_bytes()).hexdigest():
                raise ValueError('GitHub asset digest mismatch: ' + name)
            return path

        feed = download('appcast.xml')
        subprocess.run(sign + [str(feed)], check=True)
        tree = ET.parse(feed)
        items = tree.findall('channel/item')
        if len(items) != 1:
            raise ValueError('Expected one stable full update')
        item = items[0]
        build = item.findtext('{' + assets.SPARKLE + '}version')
        version = item.findtext('{' + assets.SPARKLE + '}shortVersionString')
        if args.tag != 'v' + version:
            raise ValueError('Appcast version/tag mismatch')
        name = f'CarrotType-{version}-{build}.zip'
        enclosure = item.find('enclosure')
        expected_url = assets.RELEASES + '/download/' + args.tag + '/' + name
        if enclosure.attrib['url'] != expected_url:
            raise ValueError('Archive URL must point to this versioned GitHub asset')
        archive = download(name)
        if str(archive.stat().st_size) != enclosure.attrib['length']:
            raise ValueError('Appcast archive length mismatch')
        subprocess.run(sign + [str(archive), enclosure.attrib['{' + assets.SPARKLE + '}edSignature']], check=True)
        with zipfile.ZipFile(archive) as zip_file:
            info = plistlib.loads(zip_file.read('CarrotType.app/Contents/Info.plist'))
        actual_version, actual_build = assets.validate_metadata(info, args.previous_build)
        if (version, build) != (actual_version, actual_build):
            raise ValueError('Archive app does not match appcast')
        public_key = subprocess.check_output([str(args.sparkle_bin.resolve() / 'generate_keys'),
                                             '--account', assets.ACCOUNT, '-p'], text=True).strip()
        if info['SUPublicEDKey'] != public_key:
            raise ValueError('Archive uses a different updater key')
        download(f'CarrotType-{version}.dmg')
        if args.published:
            latest = gh_json(f'repos/{REPO}/releases/latest')
            if latest['id'] != release['id']:
                raise ValueError('Published release is not latest stable')
            # Check unauthenticated client-facing endpoints as well as authenticated draft assets.
            for url, local in [(assets.FEED, feed), (expected_url, archive)]:
                with urllib.request.urlopen(url, timeout=60) as response:
                    if not response.url.startswith('https://'):
                        raise ValueError('HTTPS redirect required')
                    if hashlib.sha256(response.read()).digest() != hashlib.sha256(local.read_bytes()).digest():
                        raise ValueError('Public endpoint does not serve the verified asset')
    print('Verified stable release assets, signatures, identity, version, lengths and URLs. No release was modified.')


if __name__ == '__main__':
    main()

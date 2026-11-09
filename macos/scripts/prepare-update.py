#!/usr/bin/env python3
"""Prepare signed update assets locally. Never publishes or exports a private key."""
import argparse
import datetime
import email.utils
import pathlib
import plistlib
import re
import subprocess
import xml.etree.ElementTree as ET
from urllib.parse import urlsplit

ACCOUNT = 'app.carrottype.macos.updates'
RELEASES = 'https://github.com/kestgalax/carrottype/releases'
FEED = RELEASES + '/latest/download/appcast.xml'
SPARKLE = 'http://www.andymatuschak.org/xml-namespaces/sparkle'
ET.register_namespace('sparkle', SPARKLE)


def validate_metadata(info, previous_build, staging=False):
    version, build = info['CFBundleShortVersionString'], info['CFBundleVersion']
    if not re.fullmatch(r'\d+\.\d+\.\d+', version):
        raise ValueError('Stable version must be MAJOR.MINOR.PATCH, no prerelease')
    if not re.fullmatch(r'[1-9]\d*', build) or int(build) <= previous_build:
        raise ValueError('CFBundleVersion must increase beyond the last stable release')
    expected_id = 'app.carrottype.macos.update-test' if staging else 'app.carrottype.macos'
    if info.get('CFBundleIdentifier') != expected_id:
        raise ValueError('Unexpected bundle identity (production and staging must be isolated)')
    if not staging and info.get('SUFeedURL') != FEED:
        raise ValueError('Production feed must use the stable GitHub release endpoint')
    for key in ['SURequireSignedFeed', 'SUVerifyUpdateBeforeExtraction']:
        if info.get(key) is not True:
            raise ValueError('Required signature verification is disabled: ' + key)
    if info.get('SUSignedFeedFailureExpirationInterval') != 0:
        raise ValueError('Signed feed verification must not expire')
    if info.get('SUEnableSystemProfiling') is not False:
        raise ValueError('System profiling must be disabled')
    if not info.get('SUPublicEDKey'):
        raise ValueError('Missing embedded public key')
    return version, build


def make_feed(version, build, archive_url, signature, length, notes, feed_url):
    root = ET.Element('rss', {'version': '2.0'})
    channel = ET.SubElement(root, 'channel')
    ET.SubElement(channel, 'title').text = 'CarrotType Updates'
    ET.SubElement(channel, 'link').text = feed_url
    ET.SubElement(channel, 'description').text = 'Stable signed application updates'
    item = ET.SubElement(channel, 'item')
    ET.SubElement(item, 'title').text = 'CarrotType ' + version
    ET.SubElement(item, 'pubDate').text = email.utils.format_datetime(datetime.datetime.now(datetime.timezone.utc))
    ET.SubElement(item, 'link').text = RELEASES + '/tag/v' + version
    for key, value in [('version', build), ('shortVersionString', version),
                       ('minimumSystemVersion', '14.0.0'), ('hardwareRequirements', 'arm64')]:
        ET.SubElement(item, '{' + SPARKLE + '}' + key).text = value
    ET.SubElement(item, 'description', {'{' + SPARKLE + '}format': 'plain-text'}).text = notes
    ET.SubElement(item, 'enclosure', {
        'url': archive_url, '{' + SPARKLE + '}edSignature': signature,
        'length': str(length), 'type': 'application/octet-stream',
    })
    ET.indent(root)
    return ET.tostring(root, encoding='utf-8', xml_declaration=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', required=True, type=pathlib.Path)
    parser.add_argument('--output-dir', required=True, type=pathlib.Path)
    parser.add_argument('--sparkle-bin', required=True, type=pathlib.Path)
    parser.add_argument('--previous-build', required=True, type=int)
    parser.add_argument('--notes', required=True, type=pathlib.Path, help='Short plain text, embedded in signed feed')
    parser.add_argument('--staging-base-url', help='Only isolated test identity; loopback HTTP allowed')
    args = parser.parse_args()
    app = args.app.resolve()
    staging = args.staging_base_url is not None
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    version, build = validate_metadata(info, args.previous_build, staging)
    if staging:
        url = urlsplit(args.staging_base_url)
        if url.scheme != 'http' or url.hostname != '127.0.0.1' or url.query or url.fragment:
            raise ValueError('Staging accepts only http://127.0.0.1:<port>[/path]')
    tools = args.sparkle_bin.resolve()
    public_key = subprocess.check_output([str(tools / 'generate_keys'), '--account', ACCOUNT, '-p'], text=True).strip()
    if public_key != info['SUPublicEDKey']:
        raise ValueError('Keychain public key does not match app; refusing to sign')
    subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
    if not (app / 'Contents/Frameworks/Sparkle.framework').is_dir():
        raise ValueError('Sparkle is missing from the archive')
    out = args.output_dir.resolve()
    out.mkdir(parents=True, exist_ok=True)
    name = f'CarrotType-{version}-{build}.zip'
    archive, feed = out / name, out / 'appcast.xml'
    if archive.exists() or feed.exists():
        raise ValueError('Refusing to overwrite prepared assets; use a new output directory')
    subprocess.run(['ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', str(app), str(archive)], check=True)
    sign = [str(tools / 'sign_update'), '--account', ACCOUNT]
    signature = subprocess.check_output(sign + ['-p', str(archive)], text=True).strip()
    subprocess.run(sign + ['--verify', str(archive), signature], check=True)
    base = args.staging_base_url.rstrip('/') if staging else RELEASES + '/download/v' + version
    feed_url = base + '/appcast.xml' if staging else FEED
    feed.write_bytes(make_feed(version, build, base + '/' + name, signature, archive.stat().st_size,
                               args.notes.read_text(), feed_url))
    subprocess.run(sign + [str(feed)], check=True)
    subprocess.run(sign + ['--verify', str(feed)], check=True)
    print(f'Prepared and verified: {archive}\nSigned feed: {feed}\nNo release was published.')


if __name__ == '__main__':
    main()

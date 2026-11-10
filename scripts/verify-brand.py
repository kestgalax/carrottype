#!/usr/bin/env python3
"""Read-only checks of editable brand masters and the actual Xcode asset references."""
import json
import re
from pathlib import Path
import struct
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'macos/CarrotType/Assets.xcassets'
BRAND = ROOT / 'macos/Brand'
SVG = '{http://www.w3.org/2000/svg}'


def paths(path):
    tree = ET.parse(path)
    # SVG masters must remain self-contained, with vector geometry only.
    assert all(n.tag in {SVG + 'svg', SVG + 'g', SVG + 'path'} for n in tree.iter()), path
    allowed = {SVG + 'svg': {'viewBox', 'width', 'height'}, SVG + 'g': {'transform'}, SVG + 'path': {'d', 'fill'}}
    assert all(set(n.attrib) <= allowed[n.tag] for n in tree.iter()), path
    assert all(re.fullmatch(r'#[0-9a-fA-F]{6}', n.attrib['fill']) for n in tree.iter(SVG + 'path')), path
    return [(n.attrib['d'], n.attrib['fill']) for n in tree.iter(SVG + 'path')]


iconset = ASSETS / 'AppIcon.appiconset'
info = json.loads((iconset / 'Contents.json').read_text())
assert {(i['size'], i['scale']) for i in info['images']} == {
    (f'{size}x{size}', scale) for size in (16, 32, 128, 256, 512) for scale in ('1x', '2x')}
for item in info['images']:
    data = (iconset / item['filename']).read_bytes()
    pixels = int(item['size'].split('x')[0]) * int(item['scale'][0])
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    assert struct.unpack('>II', data[16:24]) == (pixels, pixels), item
assert {p.name for p in iconset.iterdir()} == {'Contents.json'} | {i['filename'] for i in info['images']}
mark = paths(BRAND / 'CarrotType-Mark.svg')
app = paths(BRAND / 'CarrotType-AppIcon.svg')
mono = paths(BRAND / 'CarrotType-Template.svg')
assert app[1:] == mark, 'App icon and mark drifted'
assert [d for d, _ in mono] == [d for d, _ in mark], 'Menu silhouette drifted'
assert all(fill == '#000000' for _, fill in mono)
image = ASSETS / 'CarrotMark.imageset'
assert (image / 'CarrotMark.svg').read_bytes() == (BRAND / 'CarrotType-Template.svg').read_bytes()
meta = json.loads((image / 'Contents.json').read_text())
assert meta['properties']['template-rendering-intent'] == 'template'
assert meta['properties']['preserves-vector-representation']
template = ET.parse(image / 'CarrotMark.svg').getroot()
assert (template.attrib['width'], template.attrib['height']) == ('18', '18')
print('PASS actual Xcode PNG slots/sizes, self-contained vector masters, app/menu silhouette and template metadata')

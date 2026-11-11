#!/usr/bin/env python3
"""Validate bundled release data and render safe, self-contained update notes."""
import argparse
import datetime
import html
import json
from pathlib import Path
import re

LABELS = {
    'en': {'new': 'New', 'improved': 'Improved', 'fixed': 'Fixed', 'changelog': 'Full changelog'},
    'ru': {'new': 'Новое', 'improved': 'Улучшено', 'fixed': 'Исправлено', 'changelog': 'Полный журнал изменений'},
}
KINDS = {'new', 'improved', 'fixed'}


def load(path, version=None, build=None):
    return validate(json.loads(Path(path).read_text()), version, build)


def validate(notes, version=None, build=None):
    if notes.get('schemaVersion') != 1:
        raise ValueError('Unsupported release notes schema')
    if not re.fullmatch(r'\d+\.\d+\.\d+', notes.get('version', '')):
        raise ValueError('Invalid notes version')
    if not re.fullmatch(r'[1-9]\d*', notes.get('build', '')):
        raise ValueError('Invalid notes build')
    if version is not None and (notes['version'], notes['build']) != (version, build):
        raise ValueError('Release notes version/build does not match app')
    if datetime.date.fromisoformat(notes['date']).isoformat() != notes['date']:
        raise ValueError('Invalid release date')
    translations = notes.get('localizations', {})
    if 'en' not in translations:
        raise ValueError('English fallback is required')
    for language, content in translations.items():
        if language not in LABELS:
            raise ValueError('Unsupported release notes language')
        require_text(content['summary'])
        seen = set()
        count = 0
        for section in content['sections']:
            kind = section['kind']
            if kind not in KINDS or kind in seen:
                raise ValueError('Invalid/duplicate release section')
            seen.add(kind)
            for item in section['items']:
                require_text(item['title'])
                if item.get('detail') is not None:
                    require_text(item['detail'])
                count += 1
        if not count:
            raise ValueError('At least one note required')
    return notes


def load_history(path, current):
    history = json.loads(Path(path).read_text())
    if not isinstance(history, list):
        raise ValueError('History must be an array')
    expected = int(current['build']) - 1
    for entry in history:
        validate(entry)
        if int(entry['build']) != expected:
            raise ValueError('History must contain contiguous descending builds before current')
        expected -= 1
    return history


def require_text(value):
    if not isinstance(value, str) or not value.strip():
        raise ValueError('Non-empty note text required')


def content_for(notes, language):
    language = language if language in notes['localizations'] else 'en'
    return language, notes['localizations'][language]


def release_url(notes):
    return 'https://github.com/kestgalax/carrottype/releases'


def render_html(notes, language, history=None):
    language, content = content_for(notes, language)
    labels = LABELS[language]
    escape = html.escape
    releases = []
    for entry in [notes] + (history or []):
        _, content = content_for(entry, language)
        sections = []
        for section in content['sections']:
            if not section['items']:
                continue
            items = []
            for item in section['items']:
                detail = '<p class="detail">' + escape(item['detail']) + '</p>' if item.get('detail') else ''
                items.append('<li><p>' + escape(item['title']) + '</p>' + detail + '</li>')
            sections.append('<section><h2>' + labels[section['kind']] + ' <span class="count">' +
                            str(len(items)) + '</span></h2><ul>' + ''.join(items) + '</ul></section>')
        heading = ('<h3>v' + escape(entry['version']) + ' · ' + escape(entry['date']) + '</h3>') if history else ''
        releases.append('<article class="release" data-sparkle-version="' + escape(entry['build']) + '">' +
                        heading + '<p class="summary">' + escape(content['summary']) + '</p>' + ''.join(sections) + '</article>')
    scope = ''
    if history:
        start = escape(history[-1]['version'])
        text = ('Доступна история с версии ' if language == 'ru' else 'Available history starts at version ') + start + '.'
        scope = '<p class="history-scope detail">' + text + '</p>'
    # Only template-owned markup. No scripts, remote resources, forms or dynamic styling.
    return '''<!doctype html><html lang="''' + language + '''"><head><meta charset="utf-8">
<meta name="color-scheme" content="light dark"><style>
:root{color-scheme:light dark;--ink:#242426;--muted:#656568;--line:#dddde0;--accent:#a3420a;--paper:#fff}
@media(prefers-color-scheme:dark){:root{--ink:#f1f1f2;--muted:#b4b4ba;--line:#414145;--accent:#ffad73;--paper:#202022}}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:15px/1.55 -apple-system,BlinkMacSystemFont,sans-serif}
.release.sparkle-installed-version,.release.sparkle-installed-version ~ .release,.release.sparkle-installed-version ~ .history-scope{display:none}
article+article{border-top:1px solid var(--line);padding-top:22px}h3{font-size:18px;margin:0 0 14px}.history-scope{margin-bottom:18px}
main{max-width:740px;padding:24px 28px 28px;margin:auto}header{border-left:3px solid var(--accent);padding-left:14px;margin-bottom:20px}
h1{font-size:22px;line-height:1.25;margin:0 0 6px;font-weight:650}p{margin:0}.meta,.summary,.detail{color:var(--muted)}
.meta{font-size:13px}.summary{margin-bottom:26px}section{margin:0 0 26px}h2{font-size:14px;color:var(--accent);margin:0 0 14px;font-weight:650}
.count{font-weight:400;color:var(--muted);padding-left:8px}ul{padding:0 0 0 18px;margin:0}li{padding-left:4px;margin:0 0 16px}li::marker{color:var(--accent)}
.detail{font-size:14px;margin-top:4px}footer{border-top:1px solid var(--line);padding-top:16px;font-size:13px}a{color:var(--accent)}
@media(max-width:420px){main{padding:18px}}
</style></head><body><main><header><h1>CarrotType ''' + escape(notes['version']) + '''</h1><p class="meta">''' + escape(notes['date']) + '''</p></header>''' + ''.join(releases) + scope + '<footer><a href="' + release_url(notes) + '">' + labels['changelog'] + '</a></footer></main></body></html>'


def render_markdown(notes, language):
    language, content = content_for(notes, language)
    # Text is authored as prose; escape Markdown syntax so HTML/links remain literal.
    def escape(text):
        return re.sub(r'([\\`*_{}\[\]()<>#+.!|~-])', r'\\\1', text).replace('\n', ' ')
    lines = [f"# CarrotType {notes['version']}", '', notes['date'], '', escape(content['summary']), '']
    for section in content['sections']:
        if section['items']:
            lines += ['## ' + LABELS[language][section['kind']], '']
            for item in section['items']:
                lines += ['- ' + escape(item['title']) + (' ' + escape(item['detail']) if item.get('detail') else '')]
            lines += ['']
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('--output-dir', required=True, type=Path)
    args = parser.parse_args()
    notes = load(args.source)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    history_path = args.source.with_name('ReleaseNotesHistory.json')
    history = load_history(history_path, notes) if history_path.exists() else []
    for lang in notes['localizations']:
        (args.output_dir / f'release-notes.{lang}.html').write_text(render_html(notes, lang, history))
        (args.output_dir / f'release-notes.{lang}.md').write_text(render_markdown(notes, lang))
    print('Validated and rendered localized release notes. Nothing was published.')


if __name__ == '__main__':
    main()

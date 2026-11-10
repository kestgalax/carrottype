from html.parser import HTMLParser
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).parents[2] / 'macos/scripts'))
import release_notes
import importlib.util
spec = importlib.util.spec_from_file_location('update', Path(__file__).parents[2] / 'macos/scripts/prepare-update.py')
update = importlib.util.module_from_spec(spec)
spec.loader.exec_module(update)


class ReleaseNotesChecks(unittest.TestCase):
    def setUp(self):
        self.notes = release_notes.load(Path(__file__).parents[2] / 'macos/CarrotType/Resources/ReleaseNotes.json', '0.6.1', '27')

    def test_safe_localized_feed_and_output(self):
        for lang in ('en', 'ru'):
            notes = copy.deepcopy(self.notes)
            notes['localizations'][lang]['sections'][0]['items'][0]['title'] = '<script src="https://evil"> & [link](url)'
            rendered = release_notes.render_html(notes, lang)
            self.assertNotIn('<script', rendered)
            class ResourceCheck(HTMLParser):
                def handle_starttag(inner, tag, attrs):
                    self.assertNotIn(tag, {'script', 'iframe', 'img', 'link', 'form'})
                    self.assertFalse(any(key in {'src', 'srcset'} or key.startswith('on') for key, value in attrs))
            ResourceCheck().feed(rendered)
            self.assertIn('&lt;script', rendered)
            self.assertNotIn('<h2>' + release_notes.LABELS[lang]['fixed'], rendered)
            self.assertIn('class="count">2</span>', rendered)
            md = release_notes.render_markdown(notes, lang)
            self.assertNotIn('[link](url)', md)
        feed = ET.fromstring(update.make_feed('0.6.1', '27', 'https://example.com/app.zip', 'sig', 42,
                                             '', update.FEED, self.notes))
        descriptions = feed.findall('channel/item/description')
        self.assertEqual({d.attrib['{http://www.w3.org/XML/1998/namespace}lang'] for d in descriptions}, {'en', 'ru'})
        self.assertTrue(all(d.attrib['{' + update.SPARKLE + '}format'] == 'html' for d in descriptions))
        self.assertEqual(feed.find('channel/item/enclosure').attrib['length'], '42')
        self.assertIn('What', descriptions[0].text)
        self.assertIn('Что', descriptions[1].text)
        self.assertEqual(release_notes.content_for(self.notes, 'de')[0], 'en')

    def test_invalid_or_mismatched_sources_fail(self):
        candidates = []
        for key, value in [('version', '1.0.0'), ('build', '28'), ('date', '2026-02-31'), ('schemaVersion', 2)]:
            candidate = copy.deepcopy(self.notes)
            candidate[key] = value
            candidates.append(candidate)
        candidate = copy.deepcopy(self.notes)
        candidate['localizations'].pop('en')
        candidates.append(candidate)
        candidate = copy.deepcopy(self.notes)
        candidate['localizations']['en']['sections'].append(candidate['localizations']['en']['sections'][0])
        candidates.append(candidate)
        candidate = copy.deepcopy(self.notes)
        candidate['localizations']['en']['summary'] = ' '
        candidates.append(candidate)
        for candidate in candidates:
            with self.subTest(candidate=candidate), tempfile.TemporaryDirectory() as tmp:
                source = Path(tmp) / 'notes.json'
                source.write_text(json.dumps(candidate))
                with self.assertRaises((ValueError, KeyError)):
                    release_notes.load(source, '0.6.1', '27')


if __name__ == '__main__':
    unittest.main()

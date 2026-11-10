import sys
sys.dont_write_bytecode = True
import importlib.util
import pathlib
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, str(pathlib.Path(__file__).parents[2] / 'macos/scripts'))

spec = importlib.util.spec_from_file_location('update', pathlib.Path(__file__).parents[2] / 'macos/scripts/prepare-update.py')
update = importlib.util.module_from_spec(spec)
spec.loader.exec_module(update)


class UpdateAssetChecks(unittest.TestCase):
    def setUp(self):
        self.info = dict(CFBundleShortVersionString='0.5.0', CFBundleVersion='25',
                         CFBundleIdentifier='app.carrottype.macos', SUFeedURL=update.FEED,
                         SURequireSignedFeed=True, SUVerifyUpdateBeforeExtraction=True,
                         SUSignedFeedFailureExpirationInterval=0, SUEnableSystemProfiling=False, SUEnableJavaScript=False,
                         SUPublicEDKey='public-key')

    def test_monotonic_build_and_stable_only(self):
        self.assertEqual(update.validate_metadata(self.info, 24), ('0.5.0', '25'))
        for build, version in [('24', '0.5.0'), ('23', '0.5.0'), ('25', '0.5.0-beta'), ('025', '0.5.0')]:
            with self.subTest(build=build, version=version), self.assertRaises(ValueError):
                update.validate_metadata(dict(self.info, CFBundleVersion=build, CFBundleShortVersionString=version), 24)

    def test_trust_and_staging_isolation(self):
        for key, value in [('SURequireSignedFeed', False), ('SUVerifyUpdateBeforeExtraction', False),
                           ('SUEnableSystemProfiling', True), ('SUEnableJavaScript', True), ('SUSignedFeedFailureExpirationInterval', 1),
                           ('SUFeedURL', 'http://example.com/feed.xml'), ('SUPublicEDKey', ''),
                           ('CFBundleIdentifier', 'app.carrottype.macos.update-test')]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                update.validate_metadata(dict(self.info, **{key: value}), 24)
        with self.assertRaises(ValueError):
            update.validate_metadata(self.info, 24, staging=True)
        update.validate_metadata(dict(self.info, CFBundleIdentifier='app.carrottype.macos.update-test'), 24, staging=True)
        update.validate_metadata(dict(self.info, CFBundleIdentifier='app.carrottype.macos.update-test.run-123'), 24, staging=True)
        with self.assertRaises(ValueError):
            update.validate_metadata(dict(self.info, CFBundleIdentifier='app.carrottype.macos.update-test../invalid'), 24, staging=True)

    def test_feed_escapes_notes_and_keeps_signature_metadata(self):
        root = ET.fromstring(update.make_feed('0.5.0', '25', 'https://example.com/archive.zip', 'signature', 123,
                                             'Fix <clipboard> & "updates"', update.FEED))
        item = root.find('channel/item')
        self.assertEqual(item.find('description').text, 'Fix <clipboard> & "updates"')
        self.assertEqual(item.find('enclosure').attrib['{' + update.SPARKLE + '}edSignature'], 'signature')
        self.assertEqual(item.find('{' + update.SPARKLE + '}version').text, '25')
        self.assertEqual(item.find('enclosure').attrib['length'], '123')


if __name__ == '__main__':
    unittest.main()

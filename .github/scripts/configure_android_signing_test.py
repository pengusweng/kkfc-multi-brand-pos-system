import base64
import importlib.util
import os
import sys
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location(
    'signing', Path(__file__).with_name('configure-android-signing.py'))
signing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(signing)


class SigningTests(unittest.TestCase):
    def test_properties_escape_passwords(self):
        self.assertEqual(signing.property_value(' a=b:c\\d\né'), r'\ a\=b\:c\\d\n\u00e9')

    def test_missing_secrets_fail_without_creating_a_key(self):
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaisesRegex(SystemExit, 'ANDROID_KEYSTORE_BASE64'):
                signing.configure()

    def test_keystore_is_preserved_and_properties_match(self):
        env = {'ANDROID_KEYSTORE_BASE64': base64.b64encode(b'fixture-key').decode(),
               'ANDROID_STORE_PASSWORD': 'secret', 'ANDROID_KEY_ALIAS': 'release',
               'ANDROID_KEY_PASSWORD': 'key=secret'}
        original = Path.cwd()
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, env):
            try:
                os.chdir(directory)
                Path('android').mkdir()
                signing.configure()
                self.assertEqual(Path('android/app-release.jks').read_bytes(), b'fixture-key')
                self.assertIn(r'keyPassword=key\=secret', Path('android/key.properties').read_text())
            finally:
                os.chdir(original)


if __name__ == '__main__':
    unittest.main()

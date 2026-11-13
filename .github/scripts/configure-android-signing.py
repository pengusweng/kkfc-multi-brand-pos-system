"""Write signing files in mobile/android without printing secret material."""
import base64
import os
from pathlib import Path


def property_value(value):
    escaped = (value.replace('\\', '\\\\').replace('\n', '\\n')
            .replace('\r', '\\r').replace('\t', '\\t')
            .replace(' ', '\\ ').replace(':', '\\:').replace('=', '\\='))
    # Properties.load(InputStream) uses Latin-1; unicode escapes preserve all keys.
    encoded = escaped.encode('utf-16-be')
    units = [int.from_bytes(encoded[i:i + 2], 'big') for i in range(0, len(encoded), 2)]
    return ''.join(chr(unit) if unit < 128 else f'\\u{unit:04x}' for unit in units)


def configure():
    names = ['ANDROID_KEYSTORE_BASE64', 'ANDROID_STORE_PASSWORD',
             'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD']
    missing = [name for name in names if not os.environ.get(name)]
    if missing:
        raise SystemExit('Configure these repository Actions secrets before building: '
                         + ', '.join(missing) + '. See mobile/UPDATES.md.')
    android = Path('android')
    keystore = base64.b64decode(''.join(os.environ[names[0]].split()), validate=True)
    if not keystore:
        raise SystemExit('ANDROID_KEYSTORE_BASE64 must contain a keystore.')
    (android / 'app-release.jks').write_bytes(keystore)
    values = {'storeFile': 'app-release.jks',
              'storePassword': os.environ[names[1]],
              'keyAlias': os.environ[names[2]],
              'keyPassword': os.environ[names[3]]}
    (android / 'key.properties').write_text(
        ''.join(f'{key}={property_value(value)}\n' for key, value in values.items()),
        encoding='utf-8')


if __name__ == '__main__':
    configure()

const { test } = require('node:test');
const assert = require('node:assert/strict');
const publish = require('./publish-android-release.cjs');

function fixture() {
  const calls = [];
  const missing = () => Promise.reject(Object.assign(new Error('Not found'), { status: 404 }));
  const repos = {
    getLatestRelease: missing, getReleaseByTag: missing,
    createRelease: async (data) => { calls.push(['create', data]); return { data: { id: 1, draft: true } }; },
    listReleaseAssets: async () => ({ data: [] }),
    uploadReleaseAsset: async (data) => { calls.push(['upload', data.name]); },
    deleteReleaseAsset: async () => {},
    updateRelease: async (data) => { calls.push(['publish', data]); },
  };
  return { repos, calls, args: {
    github: { rest: { repos } }, context: { repo: { owner: 'org', repo: 'pos' }, sha: 'abc', ref: 'refs/heads/development' },
    core: { info() {} }, buildNumber: 100101, readFile: () => Buffer.from('fixture'),
  } };
}

test('Android release is published only after the APK and checksum upload', async () => {
  const f = fixture();
  await publish(f.args);
  assert.deepEqual(f.calls.map((call) => call[0]), ['create', 'upload', 'upload', 'publish']);
  assert.equal(f.calls[0][1].draft, true);
  assert.equal(f.calls[1][1], 'kkfc-pos.apk');
  assert.equal(f.calls[2][1], 'kkfc-pos.apk.sha256');
  assert.equal(f.calls[3][1].make_latest, 'true');
});

test('An older rerun cannot replace a newer Android release', async () => {
  const f = fixture();
  f.repos.getLatestRelease = async () => ({ data: { tag_name: 'android-build-100201' } });
  await publish(f.args);
  assert.deepEqual(f.calls, []);
});

test('Failed uploads leave the release as a draft', async () => {
  const f = fixture();
  f.repos.uploadReleaseAsset = async () => { throw new Error('upload failed'); };
  await assert.rejects(publish(f.args), /upload failed/);
  assert.equal(f.calls.some((call) => call[0] === 'publish'), false);
});

test('API failures do not publish a release blindly', async () => {
  const f = fixture();
  f.repos.getLatestRelease = async () => { throw Object.assign(new Error('rate limited'), { status: 403 }); };
  await assert.rejects(publish(f.args), /rate limited/);
  assert.deepEqual(f.calls, []);
});

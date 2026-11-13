const fs = require('node:fs');

module.exports = async function publish({ github, context, core, buildNumber, readFile = fs.readFileSync }) {
  if (!Number.isSafeInteger(buildNumber) || buildNumber < 1) {
    throw new Error('Invalid Android build number');
  }
  const repo = context.repo;
  try {
    const { data: latest } = await github.rest.repos.getLatestRelease(repo);
    const match = /^android-build-(\d+)$/.exec(latest.tag_name);
    if (match && Number(match[1]) >= buildNumber) {
      core.info('A newer Android build is already published; leaving it unchanged.');
      return;
    }
  } catch (error) {
    if (error.status !== 404) throw error;
  }
  const tag = `android-build-${buildNumber}`;
  let release;
  try {
    release = (await github.rest.repos.getReleaseByTag({ ...repo, tag })).data;
    if (!release.draft) {
      core.info('This build is already published.');
      return;
    }
  } catch (error) {
    if (error.status !== 404) throw error;
    release = (await github.rest.repos.createRelease({
      ...repo, tag_name: tag, target_commitish: context.sha,
      name: `KKFC POS · ${context.ref.replace('refs/heads/', '')} · Android build ${buildNumber}`, draft: true,
      body: `Optional Android update from ${context.ref} at ${context.sha}.\n\nDownload kkfc-pos.apk on your device and open it to install. You can keep using the previous version.`,
    })).data;
  }
  for (const name of ['kkfc-pos.apk', 'kkfc-pos.apk.sha256']) {
    const { data: existing } = await github.rest.repos.listReleaseAssets({ ...repo, release_id: release.id });
    for (const asset of existing.filter((asset) => asset.name === name)) {
      await github.rest.repos.deleteReleaseAsset({ ...repo, asset_id: asset.id });
    }
    await github.rest.repos.uploadReleaseAsset({
      ...repo, release_id: release.id, name,
      data: readFile(`dist/${name}`),
      headers: { 'content-type': name.endsWith('.apk') ? 'application/vnd.android.package-archive' : 'text/plain' },
    });
  }
  // Publish only after both assets exist; devices never see a half-uploaded build.
  await github.rest.repos.updateRelease({ ...repo, release_id: release.id, draft: false, make_latest: 'true' });
};

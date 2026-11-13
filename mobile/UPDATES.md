# Android builds and optional updates

The **Android APK** workflow runs on pushes to `development` and `main` that
change `mobile/**` (excluding Markdown documentation), the Android APK workflow,
or its signing/publishing scripts. Backend-only, web-only and documentation-only
pushes do not generate new APKs or update notices.

It can also be started from GitHub Actions with **Run workflow**, regardless of
which files changed. Use this after changing build variables or signing secrets
when a rebuild is needed. It tests the mobile app, builds a signed universal APK,
and saves it as an Actions artifact.
No local backend is needed. Builds use the hosted API at
`https://kkfc-demo-api.onrender.com/api` by default.

For now, **development publishes in-app updates**. Set the repository Actions
variable `ANDROID_UPDATE_BRANCH` to `main` when production is ready. The next
successful qualifying build on that branch publishes the update. Other branches only
produce manually downloadable APKs, with automatic update checking disabled.

## One-time GitHub setup

In the repository, open **Settings → Secrets and variables → Actions**.
Add these **repository secrets**:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64 of the persistent Android signing keystore |
| `ANDROID_STORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Signing key alias |
| `ANDROID_KEY_PASSWORD` | Signing key password |

Use the **same signing key as the APK already installed on your devices**.
The project's previous release builds used the local Android debug key unless
you configured signing separately. For those APKs, reuse the original builder's
`%USERPROFILE%\.android\debug.keystore` (usual alias `androiddebugkey`, usual
store and key password `android`). A different key cannot replace that installed
app; uninstalling would remove its local data.

To copy the keystore as Base64 in PowerShell, set the path to the correct existing
keystore and run:

```powershell
$posSigningKey = Join-Path $env:USERPROFILE '.android\debug.keystore'
[Convert]::ToBase64String([IO.File]::ReadAllBytes($posSigningKey)) | Set-Clipboard
```

Paste into the `ANDROID_KEYSTORE_BASE64` secret. Never put the key or passwords
in source control. Back up the original keystore securely; all updates need it.
For a brand-new app installation, a dedicated release key can be used instead.
The workflow fails clearly if signing secrets are missing, rather than publishing
an APK signed with a different temporary key on each runner.

Optional **repository variables**:

| Variable | Default | Purpose |
| --- | --- | --- |
| `ANDROID_UPDATE_BRANCH` | `development` | Branch whose APK becomes the optional update; change to `main` for production |
| `ANDROID_API_URL` | `https://kkfc-demo-api.onrender.com/api` | Hosted HTTPS API URL, including `/api` |

## Download and install

1. Push to `development`, or manually run **Actions → Android APK** on that branch.
2. Wait for **Test and build signed APK** and **Publish optional app update**.
3. Open the repository's **Releases** page and download **kkfc-pos.apk** on Android.
4. Open the downloaded file and approve Android's install/update prompt. Android
   may ask you to allow installations from the browser first.

The first installation of a build containing this feature is manual. The app
already installed on a device cannot discover updates until it has this code.
The hosted API must also have the backend fixes deployed; building an APK only
updates the mobile app.

## Behavior inside the app

- The ordering menu checks GitHub Releases once per app session, asynchronously.
- Newer builds appear as a small inline **Download update** notice with a close button.
- No dialog, startup gate, automatic APK download, forced logout, or mandatory update.
- Dismissal hides that build across navigation and app restarts. A newer build
  can be offered later. The release remains available from GitHub manually.
- Tapping **Download update** opens the APK in the system browser. Installation
  remains an explicit Android action; ordering continues if the offer is ignored.
- Offline devices, missing releases, rate limits and errors remain silent.
- POS session tokens are never sent to GitHub. No GitHub token is embedded.

Releases use tags `android-build-<versionCode>` and contain the APK plus its SHA-256
checksum. The workflow derives increasing version codes from its run number and
attempt, starting above 100000. Keep this workflow's version numbering continuous;
if recreating the workflow resets its run counter, raise the base before publishing.
Older reruns never replace a newer published build. Releases are drafted while
assets upload and are made visible only when both assets are present.

## Run the current code without a local backend

You can also run uncommitted changes from Android Studio using these additional
Flutter run arguments:

```text
--dart-define=ENV=prod --dart-define=API_URL=https://kkfc-demo-api.onrender.com/api
```

Update checking is disabled for local builds unless you explicitly add
`--dart-define=APP_UPDATES_ENABLED=true`.

References: [Flutter Android signing](https://docs.flutter.dev/deployment/android),
[Android app updates](https://developer.android.com/google/play/app-updates),
[GitHub Releases API](https://docs.github.com/en/rest/releases/releases).

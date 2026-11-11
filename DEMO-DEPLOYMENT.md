# Render Free demo deployment

Demo: **12 November 2026 (Asia/Singapore)**. This guide uses the existing NestJS API in `server/`, Render Free PostgreSQL, and the Android and web clients already in this repository.

**Read the status labels carefully: DONE means prepared in this repository. TODO means you still need to perform or verify the step. No Render deployment or remote database changes have been performed by the code preparation.**

## 1. Code preparation

### Existing Docker deployment: correction for the login 500

The supplied deployment log for commit `59380a9` shows Render building the normal `server/Dockerfile`. That image starts `node dist/main` directly, without migrations or seeding. It also omits the CLI and source files needed by `start:demo`. The log ends before the login failure, so the exact request error is not yet confirmed. A healthy `SELECT 1` alone does not prove the user/session tables exist.

- [x] **DONE** - Added `server/Dockerfile.render`, a demo image containing the migration and seed tools, configured to run `npm run start:demo`.
- [ ] **TODO** - Commit and push this new Dockerfile to the branch Render deploys. Earlier commits do not contain it.
- [ ] **TODO** - In the existing API service, open **Settings -> Build & Deploy** and set these values:

| Existing Docker service setting | Value |
| --- | --- |
| Root Directory | `server` |
| Dockerfile Path (relative to Root Directory) | `Dockerfile.render` |
| Docker Build Context Directory | `.` |
| Docker Command | Leave empty to use the image's CMD; remove any `node dist/main` override |
| Health Check Path | `/api/health` |

- [ ] **TODO** - Keep `DATABASE_URL`, `DEMO_SEED_PASSWORD`, and `DEMO_SEED_PIN` in Render Environment. Use a password of **20-32 characters**: the login DTO rejects more than 32. The Docker image uses Node 22 from `FROM`, so `NODE_VERSION` does not control this Docker deployment.
- [ ] **TODO** - Redeploy the latest commit. Confirm logs show `start:demo`, migration completion, fixture seeding, and finally Nest startup. If migrations fail, share the sanitized error; do not reset the database or bypass migrations.
- [ ] **TODO** - Retry login using `test_order_staff` and the hosted seed password. Existing seeded passwords are preserved; changing an environment value does not rotate them.
- [ ] **TODO** - If login still returns 500, export **runtime logs covering the login attempt**, not only the build/startup log. Remove credentials and tokens.

This lets you keep the existing service and database. Section 3 below describes the alternative of creating a new native Node service; you do not need both approaches.

Docker verification: `git diff --check` passed. A local image build could not be run because the Docker daemon is unavailable in this session. Hosted image build, migration replay, and login remain TODO.

- [x] **DONE** — API listens on `0.0.0.0` and Render's `PORT` (`server/src/main.ts`).
- [x] **DONE** — Public `GET /api/health` checks PostgreSQL with `SELECT 1`. Returns 200 for success and 503 for failure without exposing connection details (`server/src/health.controller.ts`).
- [x] **DONE** — Health controller registered in `server/src/app.module.ts`.
- [x] **DONE** — Production seeding requires `DEMO_SEED_PASSWORD` and `DEMO_SEED_PIN`. New seeded accounts use those settings; PINs and passwords are hashed. Local test defaults remain available outside production (`server/prisma/seed-test.ts`).
- [x] **DONE** — `npm run start:demo` applies committed migrations, seeds missing fixtures, then starts the built API (`server/package.json`).
- [x] **DONE** — Empty demo-secret placeholders documented in `server/.env.example`.
- [x] **DONE** — Seed checks include missing production credentials, invalid PINs, and hashing of hosting overrides (`server/prisma/seed.check.ts`).
- [x] **TODO** — Commit and push the prepared changes to the branch you will deploy. Review the diff; do not commit `.env` files, real passwords, database connection strings, private keys, or tokens.

Local verification results are recorded in section 8. Hosted migrations, endpoint checks, and device tests remain TODO until you run them.

## 2. Create the database in Render

- [x] **TODO** — Sign in at <https://dashboard.render.com> and choose **New → Postgres**.

| Setting | Value |
| --- | --- |
| Name | `kkfc-demo-db` |
| Database | `kkfc_demo` |
| Region | Singapore if offered; use the same region for the API |
| PostgreSQL version | 17, matching local Docker Compose |
| Instance type | **Free** |

- [x] **TODO** — Wait until the database is available.
- [x] **TODO** — Locate the **Internal Database URL** in its connection details. Paste it only into Render's API environment settings below. It contains a password; do not copy it into this file, GitHub, the APK, screenshots, or chat.
- [x] **TODO** — If external database access is unnecessary, remove public access rules in the database's Networking settings. The API will use the internal connection.

The free database expires after 30 days and has no managed backups. That covers this demo, but reconstructing synthetic fixtures does not recover orders created during the presentation.

## 3. Create the API service

- [x] **TODO** — Choose **New → Web Service**, connect this GitHub repository, and select your prepared branch.

**Choose the Node runtime explicitly, even though Render may detect the Dockerfile.** The existing Docker runtime does not contain the migration and TypeScript seed tooling needed by this walkthrough. You do not need to upload `.env` or use Docker Compose on Render.

| Setting | Value |
| --- | --- |
| Name | `kkfc-demo-api` or an available alternative |
| Runtime / Language | **Node** |
| Root directory | `server` |
| Region | Same as the database |
| Instance type | **Free** |
| Build command | `npm ci --include=dev && npm run build` |
| Start command | `npm run start:demo` |
| Health check path | `/api/health` |

Before deploying, add the following under **Environment**:

| Variable | Value to enter privately in Render |
| --- | --- |
| `NODE_ENV` | `production` |
| `NODE_VERSION` | `22` |
| `DATABASE_URL` | The database's **Internal Database URL** |
| `DEMO_SEED_PASSWORD` | A newly generated strong password, 20-32 characters (login accepts at most 32) |
| `DEMO_SEED_PIN` | A new four-digit PIN, preserving any leading zero |

Do not add a custom `PORT`; the API reads Render's assigned value. Do not use the password or PIN from the local test fixtures.

For this one-day demo, all newly seeded users share the configured demo password. Only eligible roles receive the configured action PIN. Keep those credentials within the demo team. This is a demo configuration, not a full production security hardening exercise.

**Important:** seeding preserves existing users and PINs. Changing a Render seed setting later does not change existing account credentials. Start with a fresh database; do not seed public development credentials first.

- [x] **TODO** — Deploy the service and inspect the logs for successful build, migration, seeding, and Nest startup.

The startup command reruns on restarts and cold starts. Migrations apply only when pending; seeding fills missing records and preserves existing rows. This adds startup time but avoids needing shell access, which Free web services do not provide.

The synthetic menu fixture intentionally uses missing-image placeholders. Login and reading those fixtures do not require AWS credentials. Actual uploads, stored object keys, and storage-dependent demo flows need separately configured S3/CloudFront access; do not assume those work from API deployment alone.

## 4. Verify the hosted API

Replace `YOUR-SERVICE` below with the actual service hostname shown by Render. Never enter that placeholder literally.

- [ ] **TODO** — Open `https://YOUR-SERVICE.onrender.com/api/health`.

Expected HTTP 200:

```json
{"status":"ok","database":"ok"}
```

This verifies a real database query, not just that the Node process is running. A 404 at the bare `/` URL is normal because there is no root route.

- [ ] **TODO** — Confirm the logs say migrations completed. Do not replace migrations with `prisma db push`, `migrate reset`, or `migrate dev` to bypass a deployment error.
- [ ] **TODO** — Open `https://YOUR-SERVICE.onrender.com/api/docs`.
- [ ] **TODO** — Use `POST /api/auth/login` with username `test_order_staff` and the password from your hosting settings. Do not save the response token in this guide.
- [ ] **TODO** — Use Swagger's **Authorize** control with the returned bearer token.
- [ ] **TODO** — Call `GET /api/auth/me` and verify the expected user.
- [ ] **TODO** — Call `GET /api/brands`; copy a returned `brand_id`.
- [ ] **TODO** — Call `GET /api/menu-catalog/brand/{brandId}?page=1&limit=100`. Check items, prices, channels, modifiers, and pagination. This is the preferred Android menu endpoint.
- [ ] **TODO** — Call `GET /api/menu-items/brand/{brandId}` to check the Android fallback endpoint. If that fallback is exercised, also verify `GET /api/menu-channels/menu-item/{menuItemId}`.
- [ ] **TODO** — Verify an incorrect password returns 401 and an authenticated menu endpoint rejects a request without a token.

Do not run the full integration suite against this demo database: the repository's integration tests expect a separate test database and may change fixture data.

## 5. Connect the physical Android device

**DONE — existing code support:** `mobile/lib/core/config/app_config.dart` already accepts the `API_URL` and `ENV` build settings. The Android main manifest already includes Internet permission. No credentials need to be added to the app.

From PowerShell, starting at the repository root:

```powershell
Set-Location mobile
flutter devices
```

Run on a connected device (replace both placeholders):

```powershell
flutter run -d YOUR_DEVICE_ID --dart-define=ENV=prod --dart-define=API_URL=https://YOUR-SERVICE.onrender.com/api
```

Or build an APK to install on the device:

```powershell
flutter build apk --release --dart-define=ENV=prod --dart-define=API_URL=https://YOUR-SERVICE.onrender.com/api
```

APK: `mobile/build/app/outputs/flutter-apk/app-release.apk`.

- [ ] **TODO** — Install/run the new build; an old APK still contains its old API URL.
- [ ] **TODO** — Turn off device Wi-Fi and use cellular data, or use another independent network.
- [ ] **TODO** — Log in and open the menu. Compare returned items and prices with the API results and inspect Render logs for the requests.

The mobile app has fallback data/endpoint behavior. A populated screen by itself does not prove the hosted API worked. Only the public API URL belongs in the APK; enter the password through the login screen. Never put database credentials, PINs, AWS keys, or signing keys into `--dart-define` arguments.

## 6. Connect the web app

**DONE — existing code support:** Next.js login already uses server-side `API_URL` and proxies login to the NestJS API. That login path does not need browser-to-API CORS configuration.

For a web app running on your laptop, create/update the ignored `web/.env.local`:

```dotenv
API_URL=https://YOUR-SERVICE.onrender.com
```

From a new terminal at the repository root:

```powershell
Set-Location web
npm.cmd ci
npm.cmd run dev
```

- [ ] **TODO** — Restart Next.js after changing the setting, then open <http://localhost:3001> and verify login.
- [ ] **TODO** — Exercise every web screen used in the demo. A login pass alone does not prove menu screens use live data.

If the web app is already hosted, set `API_URL` in that host's environment settings and redeploy it instead. This guide publishes the API; it does not automatically publish the Next.js web app. Direct browser requests to the API, if introduced, need a specific CORS origin configuration.

## 7. Complete the deployment record and recovery notes

Fill these fields without credentials:

| Evidence | Result |
| --- | --- |
| Public API base URL | TODO |
| API Render service name | TODO |
| Database name / region | TODO |
| Full deployed commit SHA from Render | TODO |
| Migration completion / timestamp | TODO |
| Health 200 with database ok / timestamp | TODO |
| Synthetic records verified | TODO |
| Android login and menu over separate network / timestamp | TODO |
| Web login and actual demo screens / timestamp | TODO |
| Invalid password / missing-token checks | TODO |
| Log location | Render dashboard → API service → Logs |
| Secrets location | Render environment settings; values intentionally omitted |

Your local commit is available with `git rev-parse HEAD`; confirm it matches Render's deployed commit. The working tree is not a deployed commit until you commit, push, and deploy it.

Recovery:

1. **Sleeping API:** open `/api/health` and wait until it returns 200. Render Free sleeps after 15 idle minutes and may take about a minute to wake. The web login has a 10-second timeout, so wake the API before logging in.
2. **Build failure:** inspect the first error in deployment logs. Fix it and redeploy; do not bypass migrations or publish credentials as a workaround.
3. **Startup/database failure:** check database availability, matching regions, and the API's `DATABASE_URL` setting. Confirm that production seed settings are present and that the PIN has exactly four digits. Do not paste connection strings into issue reports.
4. **Application regression:** redeploy the recorded working commit or use an available Render rollback. Reverting application code does not undo database schema changes; confirm schema compatibility first.
5. **Lost demo database:** create a fresh Free database if permitted, update the API connection setting, and redeploy. `start:demo` reconstructs the committed schema and synthetic fixtures. Orders or edits from the old database will be lost unless separately exported beforehand.
6. **Before the presentation:** wake health, test both logins and menus, and keep the verified APK and commit details available. After the demo, remove the public demo service/database when no longer needed.

## 8. Local verification by Codex

- [x] **DONE / PASS** — `npm.cmd run build`: generated the Prisma client and compiled the NestJS application.
- [x] **DONE / PASS** — `npm.cmd run db:seed:check`: production credential requirements, PIN validation, hosting-secret hashes, fixture preservation, and missing-record restoration. Uses an in-memory database substitute; no real database changes.
- [x] **DONE / PASS** — Local HTTP smoke check against the compiled health controller: module registration, `/api/health` prefix, real HTTP 200 for a successful mocked query, HTTP 503 for a failed mocked query, and no underlying connection-error details in the response. This did not connect to PostgreSQL.
- [x] **DONE / PASS** — Prettier on changed TypeScript files, ESLint on changed API source files, and `git diff --check`.
- [ ] **TODO / NOT RUN** — Render deployment, empty PostgreSQL migration replay, hosted login/menu checks, APK build/install, external-network test, and web rehearsal. Record your actual results above after deployment.

## References

- Render Node service setup: <https://render.com/docs/deploy-node-express-app>
- Render Node version configuration: <https://render.com/docs/node-version>
- Database setup and internal connections: <https://render.com/docs/postgresql-creating-connecting>
- Free-tier sleep, expiry, shell and backup limits: <https://render.com/docs/free>

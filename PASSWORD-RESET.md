# Reset every account to one shared password

This is a one-time password reset for the existing Render database. It updates **every account**, including superadmins and inactive accounts, and deletes existing sessions. Inactive accounts stay inactive. Existing PINs, roles, usernames, orders, and menu records are preserved. It does not reseed the database or require a new APK.

## Code status

- [x] **DONE** - Added `npm run db:reset-passwords` and a temporary startup command that applies pending migrations, resets passwords, and starts the API.
- [x] **DONE** - Each account receives a separate Argon2 hash of the shared password. Password updates, session deletion, and the completion record commit together or roll back together.
- [x] **DONE** - Added a database completion marker keyed by `ACCOUNT_RESET_ID` and an advisory lock to serialize reset jobs. Restarts using the same ID skip the reset rather than logging everyone out again.
- [x] **DONE** - Reset output and audit details contain counts and a non-secret operation ID, without passwords, password hashes, connection strings, or tokens.
- [ ] **TODO** - Apply the reset on Render. Codex has not changed any local or hosted account passwords.

## 1. Commit and push

Commit and push these code/doc changes to the branch Render deploys. The deployed image must contain the new scripts before the reset command can work.

Use the existing Render API service with **Root Directory = `server`**, **Dockerfile Path = `Dockerfile.render`**, and **Docker Build Context = `.`**. Keep its existing database and HTTPS URL.

## 2. Add the new password in Render

Open **Render -> kkfc-demo-api -> Environment** and add:

| Key | Value |
| --- | --- |
| `ACCOUNT_RESET_PASSWORD` | Your new shared password, generated privately, **20-32 characters** |
| `ACCOUNT_RESET_ID` | A new non-secret label, for example `rotation-2026-11-13-1` |

Keep `DATABASE_URL` pointing to the existing Render database. Do not put the new password in GitHub, the APK, this document, chat, a shell command, or a screenshot. Enter the raw password in the Render value field without surrounding quotes. All users will share this password; keep it within your authorized team.

Changing `DEMO_SEED_PASSWORD` is unrelated to this operation. The reset script reads only process environment; it does not automatically load a local `.env` or fall back to `DB_*` variables.

## 3. Select the temporary reset command

In **Settings -> Build & Deploy -> Docker Command**, enter:

```text
npm run start:reset-passwords
```

Save and deploy the pushed commit. Existing sessions will be invalidated when the reset commits; tell the team to sign in again afterward. The API starts only after migrations and the reset succeed. Free compute can take a minute or more to hash all account passwords.

## 4. Verify the reset

In **Logs**, wait for:

```text
Password reset completed: N accounts updated; M sessions revoked.
```

Then wait for the service to be live and check `/api/health`. On a restart using the same ID, this is expected instead:

```text
Password reset already completed for this ACCOUNT_RESET_ID; skipped.
```

- [ ] **TODO** - Log in through Swagger or the app with an existing username and the new password.
- [ ] **TODO** - Confirm the old password is rejected (if the new password differs).
- [ ] **TODO** - Confirm a previously issued token is rejected by `GET /api/auth/me`.

If deployment fails, inspect its first error. The CLI intentionally does not print raw database errors that could contain secrets. Check that the password is 20-32 characters, the ID contains only letters/digits/underscores/hyphens (maximum 64), and `DATABASE_URL` is correct. Do not delete/reset the database to bypass an error. A failed reset transaction does not leave partially updated accounts. A successful completion message means the transaction already committed, even if the API later fails to start.

## 5. Return to normal startup

After verifying login:

1. Change **Docker Command** to:

   ```text
   npm run start:deploy
   ```

2. Remove `ACCOUNT_RESET_PASSWORD` and `ACCOUNT_RESET_ID` from Environment.
3. Save the settings and redeploy. Do not remove the variables while leaving the temporary reset command selected, because its required-setting checks would stop startup.

The normal `start:deploy` command applies migrations and starts the API without seeding or resetting accounts. Keep this Docker Command override; clearing it restores the demo image's default seed startup. `DEMO_SEED_PASSWORD` and `DEMO_SEED_PIN` are not needed by `start:deploy` and can also be removed if nothing else uses them. Existing user PINs remain in the database.

To deliberately reset again later, use a **new** `ACCOUNT_RESET_ID` and repeat the temporary command steps. Reusing a completed ID skips the operation even if you change the password value. Keep the audit completion record intact while that ID is configured.

## Verification record

- [x] **DONE / PASS** - `npm run db:reset-passwords:check`: missing/invalid settings, active/inactive accounts, separate Argon2 salts, session deletion, audit privacy, rollback model, repeated-ID skip, and empty-database refusal. Uses an in-memory transaction substitute; no real database changes.
- [x] **DONE / PASS** - TypeScript (`tsc --noEmit -p prisma/tsconfig.seed.json`), Prettier on the reset scripts/configuration, and `git diff --check`.
- [ ] **TODO** - Hosted PostgreSQL locking, reset execution, and login/session verification. No real account passwords have been changed by Codex.

| Hosted evidence (no credentials) | Result |
| --- | --- |
| Deployed commit | TODO |
| Reset ID | TODO |
| Completion timestamp and counts | TODO |
| Health check | TODO |
| New-password login / old-password rejection | TODO |
| Old token rejected | TODO |
| Normal startup restored and reset secret removed | TODO |

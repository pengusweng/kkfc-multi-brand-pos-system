# Automatic CI failure issues

The reporter must be installed on `main`, this repository's default branch.
Once installed there, it reports failures for PRs into **both** `development`
and `main`; PR authors do not need to merge their feature into `main` first.
Installing it only on `development` does not activate the `workflow_run` event.

`Report CI failures` runs after the main `CI` workflow finishes unsuccessfully.
It creates a separate issue for each failing area: Backend, Flutter, or CI setup.
It reports failed tests, formatting, lint, builds, and infrastructure failures;
a failed check is recorded as requiring investigation, not as a confirmed bug.
Cancelled runs and passing runs do not create issues.

## Enable and configure

1. Merge the workflow and `.github/scripts/` files into the repository's
   **default branch**. GitHub only triggers `workflow_run` workflows that exist
   there. This change does not publish the workflow by itself.
2. Ensure GitHub Issues is enabled for the repository and repository or
   organization policy permits the workflow's `issues: write` permission.
3. In **Settings → Secrets and variables → Actions → Variables**, optionally
   create these repository variables. Values are GitHub usernames, separated
   by commas or spaces; a leading `@` is accepted. No personal access token
   is required.

| Variable               | Purpose                         | Example value       |
| ---------------------- | ------------------------------- | ------------------- |
| `CI_BACKEND_ASSIGNEES` | Backend tests and builds        | `backend-developer` |
| `CI_FLUTTER_ASSIGNEES` | Flutter checks and builds       | `mobile-developer`  |
| `CI_DEFAULT_ASSIGNEES` | CI setup and fallback ownership | `qa-lead`           |

The examples are placeholders; use actual eligible repository users. The script
checks assignment eligibility before creating the issue. It tries area owners,
then default owners, then the PR author, workflow actor, and repository owner
in that order. Organization accounts cannot themselves be issue assignees;
set `CI_DEFAULT_ASSIGNEES` for reliable ownership in an organization repository.
If no account is eligible, it still creates the report, explicitly marks it
unassigned, and emits an Actions warning. At most ten users are assigned.
Assignment notifications follow each user's GitHub notification settings.

## Issue format and lifecycle

To report a failure that completed before activation, open **Actions → Report
CI failures → Run workflow**, select the default branch, and enter the failed
CI run's numeric ID. For the originally inspected PR #178 run, the ID is
`42491122658`. The workflow fetches the run from this repository and validates
that it is a completed, failed `CI` run. Normal stale-PR and duplicate checks
still apply. This does not rerun the application's tests.

Example title: **[CI] Backend failure — PR #42**

The issue includes:

- Execution: PR or branch, commit, workflow run, attempt, and owner.
- Failed checks: a table linking failed jobs and naming their failed steps.
- Test reports: links to available test, golden image, and coverage artifacts.
- Investigation checklist: reproduce, check requirements, classify the cause,
  link the fix, and verify the checks before closing.

If tests never started, the issue explains that no reports are available and
links the run logs. Artifacts remain subject to GitHub's retention settings.

There is one **open** issue per PR (or push branch) and failing area. Repeated
failures update it and retain the previous report in a comment. A duplicate
delivery for the same run attempt makes no changes. Manual reassignment is
preserved. After an issue is closed, a later failure creates a new issue.
Passing runs do not close issues automatically: the assigned person reviews
the cause and fix before closing them. A PR failure and a post-merge branch
failure have different tracking scopes and can produce separate issues.

Superseded PR commits, closed PRs, and outdated rerun completion events are
ignored. The final aggregate `CI` failure does not create a second issue when
a specific failed job already explains it. Notifications are serialized by
source repository and branch to avoid concurrent duplicate creation. GitHub
concurrency may replace a pending notification when several runs finish in
quick succession; the newest failure still reports the current branch state.

## Verification and security

Run from the repository root:

```powershell
node --test .github/scripts/*.test.cjs
```

These tests use a simulated GitHub API; they create no real issues. The main CI
workflow runs them as a required part of its aggregate check. They cover owner
routing and fallback, repeated failures, duplicate delivery, evidence links,
manual reassignment, missing reports, fork PR lookup, outdated runs, and API
permission failures.

The reporting workflow executes only the script from the trusted default
branch. It does not check out a PR head, execute test artifacts, or read secrets
from test output. API data is passed as data, not shell commands. It uses the
built-in `GITHUB_TOKEN`, with read access to Actions and PR metadata and write
access to Issues.

For an end-to-end verification after merge, use a temporary PR targeting
`development` with a deliberate failing assertion. Check the issue's owner,
failed-step links, and reports; rerun to check deduplication, then fix the
assertion and close the test issue. A live GitHub notification has not been
verified by the local API simulation.

## Current test scope

Backend Robot Framework E2E is enabled in `workflows/ci.yml` after integration
tests, using a separate PostgreSQL service and excluding external-storage tests.
Active backend CI runs reporting tools, traceability, unit tests, build, and
database-backed integration tests. Flutter CI runs formatting, analysis,
unit/widget/golden tests, and an Android debug build. Flutter-to-API emulator
integration suites remain separate local runs.

Local audit on 2026-11-08:

The subsequent local Robot E2E run passed all 24 tests with none skipped.

| Check                                  | Result                                                                |
| -------------------------------------- | --------------------------------------------------------------------- |
| Backend reporting tests                | 14 passed                                                             |
| CI issue reporting tests               | 11 passed using simulated GitHub responses                            |
| Backend Gherkin traceability           | 643 declarations mapped                                               |
| Backend unit tests                     | 733 passed, 21 suites                                                 |
| Backend integration tests              | 1,188 passed, 21 suites; 23 migrations applied to isolated PostgreSQL |
| Backend lint, formatting, build        | Passed                                                                |
| Flutter unit/widget/golden tests       | 231 passed, none skipped; Windows baselines                           |
| Flutter analysis and source formatting | Passed                                                                |
| Android debug APK build                | Passed                                                                |

The local Windows run does not verify Linux golden rendering. CI remains the
verification environment for those platform-specific baselines. Passing these
checks establishes the tested scenarios, not an absence of all possible bugs.

References: [workflow_run](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_run),
[creating issues](https://docs.github.com/en/rest/issues/issues#create-an-issue),
[assignment eligibility](https://docs.github.com/en/rest/issues/assignees#check-if-a-user-can-be-assigned).

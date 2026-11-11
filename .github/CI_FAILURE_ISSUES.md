# Automatic CI failure issues

Issue creation and assignment run **inside the existing CI workflow** in
`workflows/required-ci.yml`. Failed PRs targeting `development` or `main`, and
failed pushes to those branches, can create issues. No listener or merge into
the default branch is required.

## Activate on development

Merge this change into `development`. New CI runs that include the updated
workflow use its `Report CI failures` job. Existing completed runs do not gain
new jobs retroactively; update an existing PR with the latest `development`
and trigger a new run to use the reporter. Rerunning an old workflow revision
does not install the new reporting job.

The earlier main-targeted activation PR #179 is superseded by this approach.
The separate `workflow_run` listener is removed to avoid duplicate reporters.

## Assignment

In **Settings > Secrets and variables > Actions > Variables**, set eligible
GitHub usernames, separated by commas or spaces. A leading `@` is accepted.

| Variable               | Receives                                 |
| ---------------------- | ---------------------------------------- |
| `CI_BACKEND_ASSIGNEES` | Backend test and build failures          |
| `CI_FLUTTER_ASSIGNEES` | Flutter test and build failures          |
| `CI_WEB_ASSIGNEES`     | Web test and build failures              |
| `CI_DEFAULT_ASSIGNEES` | CI setup failures and fallback ownership |

The reporter checks assignment eligibility. For PR failures it assigns the PR
author first, together with the configured owners of every failed CI area
(including Web). Duplicate usernames are removed. Branch failures use the
configured owners. If no one is eligible, it tries default owners, then the
workflow actor or repository owner.
Organization accounts cannot themselves receive assignments; configure a real
user as the default owner. Up to ten users can be assigned. If none is eligible,
the issue is still created with an explicit unassigned notice and an Actions
warning. GitHub notification preferences determine delivery to each assignee.

## Execution and permissions

The reporting job waits for automation tests, change detection, backend, and
Flutter, and Web. It runs when a dependency fails, even if subsequent stages are skipped.
It reads the current attempt's job results while the workflow is still running.
The final required `CI` job waits for reporting and still fails if any required
pipeline failed. Reporting problems are visible as failed jobs too.

Only the reporting job receives `issues: write`, with read access to repository,
Actions, and PR metadata. Test jobs retain their existing permissions. The
reporter uses the built-in `GITHUB_TOKEN`; no personal access token is needed.

Same-repository PRs and branch pushes support automatic issue writing. Fork
and Dependabot PRs are excluded from the write-enabled reporting job because
their tokens can be read-only. Their normal CI checks still run. The reporter
does not use `pull_request_target` or a separate default-branch listener.
Repository and organization policy must allow the requested token permissions,
and GitHub Issues must be enabled.

## Reports and duplicates

Each issue has a consistent title, such as **[CI] Failure - PR #178**,
and contains the source PR or branch, head commit, run attempt, assigned owners,
failed jobs and steps, available test-report links, and an investigation
checklist. A failed check is recorded for investigation, not as proof of an
application bug. If reports are unavailable, the issue links the run logs.
Artifacts remain subject to GitHub retention settings.

One open issue combines all failed CI areas per PR or branch. Later failures update
it and retain the earlier report in a comment. Repeated execution for the same
attempt creates no duplicate. Existing eligible assignees are retained, and the
PR author and owners of newly failing areas are added, up to ten users. A previous
area-specific report is reused when available; historical duplicate issues are
not automatically closed. Superseded PR
commits, closed PRs, obsolete reruns, success, and cancellation are ignored.
Reporting jobs are serialized per PR or branch to avoid concurrent duplicates.
GitHub may replace a pending reporting job when several runs finish quickly.

Passing runs do not close issues automatically. The assigned person verifies
the cause and fix before closing. A later failure after closure creates a new
issue. PR and post-merge branch failures have distinct tracking scopes.

## Verification

From the repository root:

```powershell
node --test .github/scripts/*.test.cjs
```

Tests simulate the GitHub API and create no real issues. They cover current
in-progress runs, merge-ref versus PR head commits, area owners and fallback,
job API lag, duplicate prevention, reruns, manual reassignment, missing reports,
fork/Dependabot restrictions, superseded runs, and permission failures.

For a live check, use a same-repository PR into `development` whose CI includes
this workflow. A failing check should start `Report CI failures`, which should
link the newly created or updated assigned issue in its Actions job summary.

Live verification on 2026-11-09: a temporary deliberately failing check on
PR #180 automatically created [issue #181](https://github.com/pengusweng/kkfc-multi-brand-pos-system/issues/181)
and assigned `sys-te-mika` and `gbrlgrg` using the repository variables. The
reporting job passed while its workflow was still in progress. The temporary
verification workflow was then removed and its test issue closed.

References: [job permissions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idpermissions),
[creating issues](https://docs.github.com/en/rest/issues/issues#create-an-issue).

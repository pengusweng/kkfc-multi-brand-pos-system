"use strict";

const { test } = require("node:test");
const assert = require("node:assert/strict");
const report = require("./report-ci-failure.cjs");

function runningFixture() {
  const f = fixture();
  f.state.current = {
    ...f.context.payload.workflow_run,
    status: "in_progress",
    conclusion: null,
    head_sha: "synthetic-merge-commit",
  };
  Object.assign(f.context, {
    eventName: "pull_request",
    runId: 10,
    runAttempt: 1,
    actor: "author",
    payload: {
      pull_request: {
        ...f.state.pr,
        head: { ...f.state.pr.head, repo: { full_name: "org/pos" } },
      },
    },
  });
  f.core.notice = (message) => f.calls.warnings.push(message);
  f.dependencyResults = {
    backend: { result: "failure" },
    frontend: { result: "success" },
  };
  return f;
}

test("reports failures inside an unfinished PR CI run using the PR head SHA", async () => {
  const f = runningFixture();
  f.env.GITHUB_RUN_ATTEMPT = "1";
  delete f.context.runAttempt;
  await report(f);
  assert.equal(f.calls.created.length, 1);
  assert.deepEqual(f.calls.created[0].assignees, ["backend-owner"]);
  assert.match(f.calls.created[0].body, /commit\/abc123/);
  assert.doesNotMatch(f.calls.created[0].body, /synthetic-merge-commit/);
});

test("uses dependency results when failed jobs have not appeared in the API yet", async () => {
  const f = runningFixture();
  f.state.jobs = [];
  f.dependencyResults = {
    backend: { result: "failure" },
    frontend: { result: "failure" },
  };
  await report(f);
  assert.deepEqual(
    f.calls.created.map((issue) => issue.title),
    ["[CI] Backend failure — PR #42", "[CI] Flutter failure — PR #42"],
  );
});

test("does not report a dependency run with only passing, skipped, or cancelled jobs", async () => {
  for (const result of ["success", "skipped", "cancelled"]) {
    const f = runningFixture();
    f.dependencyResults = { backend: { result } };
    await report(f);
    assert.equal(f.calls.created.length, 0);
  }
});

test("groups web failures with web owners, including when the jobs API lags", async () => {
  for (const jobs of [[], [{ name: "Web / Lint, tests, build and browser smoke", conclusion: "failure" }]]) {
    const f = runningFixture();
    f.state.jobs = jobs;
    f.dependencyResults = { web: { result: "failure" } };
    f.env.CI_WEB_ASSIGNEES = "qa-owner";
    await report(f);
    assert.equal(f.calls.created.length, 1);
    assert.match(f.calls.created[0].title, /Web failure/);
    assert.deepEqual(f.calls.created[0].assignees, ["qa-owner"]);
  }
});

test("does not write issues for fork or Dependabot PRs", async () => {
  for (const fork of [true, false]) {
    const f = runningFixture();
    if (fork)
      f.context.payload.pull_request.head.repo.full_name = "outside/pos";
    else f.context.actor = "dependabot[bot]";
    await report(f);
    assert.equal(f.calls.created.length, 0);
    assert.equal(f.calls.warnings.length, 1);
  }
});

test("ignores obsolete, queued, successful, and cancelled current runs", async () => {
  const changes = [
    (f) => {
      f.state.current.run_attempt = 2;
    },
    (f) => {
      f.state.current.status = "queued";
    },
    (f) => {
      Object.assign(f.state.current, {
        status: "completed",
        conclusion: "success",
      });
    },
    (f) => {
      Object.assign(f.state.current, {
        status: "completed",
        conclusion: "cancelled",
      });
    },
    (f) => {
      f.state.pr.head.sha = "newer-head";
    },
  ];
  for (const change of changes) {
    const f = runningFixture();
    change(f);
    await report(f);
    assert.equal(f.calls.created.length, 0);
  }
});

test("reports a current development push using default ownership for CI failures", async () => {
  const f = runningFixture();
  f.context.eventName = "push";
  f.context.payload = {};
  Object.assign(f.state.current, {
    head_branch: "development",
    head_sha: "abc123",
  });
  f.state.jobs = [{ name: "CI automation tests", conclusion: "failure" }];
  f.dependencyResults = { "automation-tests": { result: "failure" } };
  await report(f);
  assert.equal(f.calls.created[0].title, "[CI] CI failure — development");
  assert.deepEqual(f.calls.created[0].assignees, ["qa-owner"]);
});

test("updates a current-run issue and ignores a repeated call for the same attempt", async () => {
  const f = runningFixture();
  await report(f);
  await report(f);
  f.context.runAttempt = 2;
  f.state.current.run_attempt = 2;
  await report(f);
  assert.equal(f.calls.created.length, 1);
  assert.equal(f.calls.updated.length, 1);
  assert.equal(f.calls.comments.length, 1);
});

function fixture() {
  const calls = {
    created: [],
    updated: [],
    comments: [],
    warnings: [],
    checked: [],
  };
  const state = {
    issues: [],
    artifacts: [{ id: 7, name: "unit-test-results", expired: false }],
    jobs: [
      {
        name: "Backend / Stage 1 - Unit Tests (UT) & Build",
        conclusion: "failure",
        html_url: "https://github.com/org/pos/actions/runs/10/job/1",
        steps: [{ name: "Run Jest Unit Tests", conclusion: "failure" }],
      },
      { name: "CI", conclusion: "failure", steps: [] },
    ],
    pr: {
      number: 42,
      state: "open",
      base: { ref: "development" },
      head: { sha: "abc123" },
      user: { login: "author" },
      html_url: "https://github.com/org/pos/pull/42",
    },
    eligible: new Set([
      "backend-owner",
      "mobile-owner",
      "qa-owner",
      "author",
      "org",
    ]),
    current: { status: "completed", run_attempt: 1, conclusion: "failure" },
  };
  const api = (fn) => fn;
  const github = {
    rest: {
      actions: {
        getWorkflowRun: async () => ({ data: state.current }),
        listJobsForWorkflowRunAttempt: api(async () => state.jobs),
        listWorkflowRunArtifacts: api(async () => state.artifacts),
      },
      repos: {
        listPullRequestsAssociatedWithCommit: api(async () => [state.pr]),
      },
      pulls: { get: async () => ({ data: state.pr }) },
      issues: {
        listForRepo: api(async () => state.issues),
        checkUserCanBeAssigned: async ({ assignee }) => {
          calls.checked.push(assignee);
          if (!state.eligible.has(assignee))
            throw Object.assign(new Error("Not assignable"), { status: 404 });
        },
        create: async (input) => {
          calls.created.push(input);
          const issue = {
            ...input,
            number: 9,
            user: { login: "github-actions[bot]" },
            assignees: input.assignees.map((login) => ({ login })),
            html_url: "https://github.com/org/pos/issues/9",
          };
          state.issues.push(issue);
          return { data: issue };
        },
        createComment: async (input) => {
          calls.comments.push(input);
        },
        update: async (input) => {
          calls.updated.push(input);
          Object.assign(state.issues[0], input);
        },
      },
    },
    paginate: async (method, args) => method(args),
  };
  const context = {
    repo: { owner: "org", repo: "pos" },
    serverUrl: "https://github.com",
    payload: {
      workflow_run: {
        id: 10,
        run_attempt: 1,
        run_number: 20,
        name: "CI",
        conclusion: "failure",
        event: "pull_request",
        head_sha: "abc123",
        head_branch: "feature/order",
        html_url: "https://github.com/org/pos/actions/runs/10",
        actor: { login: "author" },
        pull_requests: [{ number: 42 }],
      },
    },
  };
  const summary = {
    addHeading() {
      return this;
    },
    addList() {
      return this;
    },
    async write() {},
  };
  const core = { warning: (message) => calls.warnings.push(message), summary };
  const env = {
    CI_BACKEND_ASSIGNEES: "backend-owner",
    CI_FLUTTER_ASSIGNEES: "mobile-owner",
    CI_DEFAULT_ASSIGNEES: "qa-owner",
  };
  return { github, context, core, env, state, calls };
}

test("creates one backend issue with owner, evidence, and failed steps; ignores aggregate failure", async () => {
  const f = fixture();
  await report(f);
  assert.equal(f.calls.created.length, 1);
  const issue = f.calls.created[0];
  assert.deepEqual(issue.assignees, ["backend-owner"]);
  assert.equal(issue.title, "[CI] Backend failure — PR #42");
  assert.match(issue.body, /Run Jest Unit Tests/);
  assert.match(issue.body, /actions\/runs\/10\/artifacts\/7/);
  assert.match(issue.body, /not yet a confirmed application bug/);
});

test("routes simultaneous backend, Flutter, and setup failures to their owners", async () => {
  const f = fixture();
  f.state.jobs.push(
    { name: "Flutter / Flutter CI Pipeline", conclusion: "failure" },
    { name: "Detect Changes", conclusion: "failure" },
  );
  await report(f);
  assert.deepEqual(
    f.calls.created.map((issue) => issue.assignees),
    [["backend-owner"], ["mobile-owner"], ["qa-owner"]],
  );
});

test("falls back from invalid area owners to default owners, then PR author", async () => {
  const f = fixture();
  f.env.CI_BACKEND_ASSIGNEES = "unknown";
  f.env.CI_DEFAULT_ASSIGNEES = "also-unknown";
  await report(f);
  assert.deepEqual(f.calls.created[0].assignees, ["author"]);
  assert.equal(f.calls.warnings.length, 2);
});

test("updates repeated failures, preserves previous evidence and human assignment, and is idempotent", async () => {
  const f = fixture();
  await report(f);
  f.state.issues[0].assignees = [{ login: "human-owner" }];
  f.context.payload.workflow_run.run_attempt = 2;
  f.state.current.run_attempt = 2;
  await report(f);
  await report(f);
  assert.equal(f.calls.created.length, 1);
  assert.equal(f.calls.updated.length, 1);
  assert.equal(f.calls.comments.length, 1);
  assert.match(f.calls.comments[0].body, /ci-run:10:1/);
  assert.equal(f.calls.updated[0].assignees, undefined);
  assert.match(f.calls.updated[0].body, /Responsibility:\*\* @human-owner/);
});

test("does not trust issue markers created by other users", async () => {
  const f = fixture();
  f.state.issues.push({
    user: { login: "author" },
    body: "<!-- ci-failure:pr-42:Backend -->",
  });
  await report(f);
  assert.equal(f.calls.created.length, 1);
});

test("does not create issues for success, cancellation, superseded commits, closed PRs, or older attempts", async () => {
  const changes = [
    (f) => {
      f.context.payload.workflow_run.conclusion = "success";
    },
    (f) => {
      f.context.payload.workflow_run.conclusion = "cancelled";
    },
    (f) => {
      f.state.pr.head.sha = "newer";
    },
    (f) => {
      f.state.pr.state = "closed";
    },
    (f) => {
      f.state.current.run_attempt = 2;
    },
    (f) => {
      f.state.current.status = "in_progress";
    },
    (f) => {
      f.state.pr.base.ref = "other";
    },
  ];
  for (const change of changes) {
    const f = fixture();
    change(f);
    await report(f);
    assert.equal(f.calls.created.length, 0);
  }
});

test("finds fork PRs when the workflow event omits pull_requests", async () => {
  const f = fixture();
  f.context.payload.workflow_run.pull_requests = [];
  await report(f);
  assert.equal(f.calls.created.length, 1);
});

test("reports branch push failures and startup errors even without tests or artifacts", async () => {
  const f = fixture();
  Object.assign(f.context.payload.workflow_run, {
    event: "push",
    head_branch: "main",
  });
  f.state.jobs = [];
  f.state.artifacts = [];
  await report(f);
  assert.equal(f.calls.created[0].title, "[CI] CI failure — main");
  assert.match(f.calls.created[0].body, /No test report artifacts/);
  assert.match(f.calls.created[0].body, /startup or infrastructure/);
});

test("creates evidence with a warning even when no account is assignable", async () => {
  const f = fixture();
  f.state.eligible.clear();
  await report(f);
  assert.deepEqual(f.calls.created[0].assignees, []);
  assert.match(f.calls.created[0].body, /Unassigned/);
  assert.ok(
    f.calls.warnings.some((message) =>
      message.includes("No eligible assignee"),
    ),
  );
});

test("does not turn unexpected permission errors into silent assignment failures", async () => {
  const f = fixture();
  f.github.rest.issues.checkUserCanBeAssigned = async () => {
    throw Object.assign(new Error("Forbidden"), { status: 403 });
  };
  await assert.rejects(report(f), /Forbidden/);
});

test("escapes untrusted job text and suppresses accidental mentions", async () => {
  const f = fixture();
  f.state.jobs[0].steps[0].name = "<script> | @someone\nnext";
  await report(f);
  assert.match(
    f.calls.created[0].body,
    /&lt;script&gt; \\\| @\u200bsomeone next/,
  );
});

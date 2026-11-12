"use strict";

const failures = new Set([
  "failure",
  "timed_out",
  "startup_failure",
  "action_required",
]);
const bot = "github-actions[bot]";
const areaFor = (name) =>
  name.startsWith("Backend /")
    ? "Backend"
    : name.startsWith("Flutter /")
      ? "Flutter"
      : name.startsWith("Web /")
        ? "Web"
        : "CI";
const trackingFor = (issue) => {
  try {
    const data = JSON.parse(
      issue?.body?.match(/<!-- ci-tracking:(.*?) -->/)?.[1] ?? "null",
    );
    if (data && Array.isArray(data.areas) && Array.isArray(data.jobs))
      return data;
  } catch {
    /* Older reports have no machine-readable tracking. */
  }
  const areas =
    issue?.body?.match(/^## (.+) CI failure$/m)?.[1].split(", ") ?? [];
  const jobs = [
    ...(issue?.body ?? "").matchAll(/^\| \[(.*?)\]\([^\n]*?\) \|/gm),
  ].map((match) => match[1]);
  return { areas, jobs, runNumber: 0 };
};
const safe = (value) =>
  String(value ?? "")
    .replace(/[\r\n]+/g, " ")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/[\\`*_[\]()!|]/g, "\\$&")
    .replace(/@/g, "@\u200b");
const usernames = (value) => [
  ...new Set(
    String(value ?? "")
      .split(/[\s,]+/)
      .map((name) => name.replace(/^@/, ""))
      .filter(Boolean),
  ),
];

module.exports = async function report({
  github,
  context,
  core,
  env = process.env,
  dependencyResults,
  recover = false,
}) {
  const repo = context.repo;
  if (
    recover &&
    (dependencyResults?.ci?.result !== "success" ||
      dependencyResults?.["automation-tests"]?.result !== "success" ||
      dependencyResults?.["detect-changes"]?.result !== "success" ||
      !["backend", "frontend", "web"].every((name) =>
        ["success", "skipped"].includes(dependencyResults?.[name]?.result),
      ))
  )
    return;
  let run;
  if (dependencyResults !== undefined) {
    // Reporting runs inside CI, after its dependencies but before CI completes.
    if (
      !recover &&
      !Object.values(dependencyResults).some((job) => job.result === "failure")
    )
      return;
    if (!["pull_request", "push"].includes(context.eventName)) return;
    if (
      context.actor === "dependabot[bot]" ||
      (context.eventName === "pull_request" &&
        context.payload.pull_request.head.repo.full_name !==
          `${repo.owner}/${repo.repo}`)
    ) {
      core.notice(
        "Automatic issue reporting is unavailable for fork and Dependabot PRs with read-only tokens.",
      );
      return;
    }
    const { data: current } = await github.rest.actions.getWorkflowRun({
      ...repo,
      run_id: context.runId,
    });
    const runAttempt = Number(env.GITHUB_RUN_ATTEMPT ?? context.runAttempt);
    if (
      current.run_attempt !== runAttempt ||
      !["in_progress", "completed"].includes(current.status) ||
      (current.status === "completed" &&
        !(recover
          ? current.conclusion === "success"
          : failures.has(current.conclusion)))
    )
      return;
    run = {
      ...current,
      event: context.eventName,
      conclusion: recover ? "success" : "failure",
      // PR CI executes a merge ref; issue tracking must use the actual head SHA.
      head_sha: context.payload.pull_request?.head.sha ?? current.head_sha,
      pull_requests: context.payload.pull_request
        ? [{ number: context.payload.pull_request.number }]
        : current.pull_requests,
    };
  } else {
    // Also accept a completed run when replaying an older failure with this script.
    run = context.payload.workflow_run;
    if (!["failure", "timed_out"].includes(run.conclusion)) return;
    if (!["pull_request", "push"].includes(run.event)) return;

    const { data: current } = await github.rest.actions.getWorkflowRun({
      ...repo,
      run_id: run.id,
    });
    if (
      current.status !== "completed" ||
      current.run_attempt !== run.run_attempt ||
      current.conclusion !== run.conclusion
    )
      return;
  }

  let pr;
  if (run.event === "pull_request") {
    let candidates = run.pull_requests ?? [];
    // Fork PR workflow_run payloads can omit pull_requests.
    if (!candidates.length) {
      candidates = await github.paginate(
        github.rest.repos.listPullRequestsAssociatedWithCommit,
        {
          ...repo,
          commit_sha: run.head_sha,
          per_page: 100,
        },
      );
    }
    for (const candidate of candidates) {
      const { data } = await github.rest.pulls.get({
        ...repo,
        pull_number: candidate.number,
      });
      if (
        data.state === "open" &&
        ["main", "development"].includes(data.base.ref) &&
        data.head.sha === run.head_sha
      ) {
        pr = data;
        break;
      }
    }
    // Do not file failures for closed PRs or superseded commits.
    if (!pr) return;
  } else if (!["main", "development"].includes(run.head_branch)) {
    return;
  } else {
    const { data: branch } = await github.rest.repos.getBranch({
      ...repo,
      branch: run.head_branch,
    });
    if (branch.commit.sha !== run.head_sha) return;
  }

  // A delayed run for the same head must not overwrite a newer result.
  const runs = await github.paginate(github.rest.actions.listWorkflowRuns, {
    ...repo,
    workflow_id: run.workflow_id,
    branch: run.head_branch,
    event: run.event,
    per_page: 100,
  });
  if (runs.some((other) => other.run_number > run.run_number)) return;

  const jobs = await github.paginate(
    github.rest.actions.listJobsForWorkflowRunAttempt,
    {
      ...repo,
      run_id: run.id,
      attempt_number: run.run_attempt,
      per_page: 100,
    },
  );
  const groups = new Map();
  for (const job of jobs.filter((job) => failures.has(job.conclusion))) {
    // The final CI job merely repeats a downstream failure; avoid another issue.
    if (
      job.name === "CI" &&
      jobs.some(
        (other) => other.name !== "CI" && failures.has(other.conclusion),
      )
    )
      continue;
    const category = areaFor(job.name);
    if (!groups.has(category)) groups.set(category, []);
    groups.get(category).push(job);
  }
  // The jobs API can lag the scheduler; dependency results are authoritative.
  for (const [name, job] of Object.entries(dependencyResults ?? {})) {
    if (job.result !== "failure") continue;
    const category =
      name === "backend"
        ? "Backend"
        : name === "frontend"
          ? "Flutter"
          : name === "web"
            ? "Web"
            : "CI";
    if (!groups.has(category)) groups.set(category, []);
  }
  if (!groups.size) groups.set("CI", []);

  const artifacts = await github.paginate(
    github.rest.actions.listWorkflowRunArtifacts,
    {
      ...repo,
      run_id: run.id,
      per_page: 100,
    },
  );
  const issues = await github.paginate(github.rest.issues.listForRepo, {
    ...repo,
    state: "all",
    creator: bot,
    per_page: 100,
  });
  const scope = pr ? `pr-${pr.number}` : `branch-${run.head_branch}`;
  const links = [];
  const category = [...groups.keys()].join(", ");
  const failedJobs = [...groups.values()].flat();
  const marker = `<!-- ci-failure:${scope}:all -->`;
  const isReport = (issue) => !issue.pull_request && issue.user?.login === bot;
  // Reuse a previous area report when upgrading to consolidated reporting.
  const existing =
    issues.find((issue) => isReport(issue) && issue.body?.includes(marker)) ??
    issues.find(
      (issue) =>
        isReport(issue) &&
        ["Backend", "Flutter", "Web", "CI"].some((area) =>
          issue.body?.includes(`<!-- ci-failure:${scope}:${area} -->`),
        ),
    );
  const attemptMarker = `<!-- ci-run:${run.id}:${run.run_attempt} -->`;
  if (recover) {
    if (!existing || existing.state === "closed") return;
    const tracking = trackingFor(existing);
    const areaJobs = {
      Backend: "backend",
      Flutter: "frontend",
      Web: "web",
      CI: "ci",
    };
    if (
      !tracking.areas.length ||
      tracking.runNumber > run.run_number ||
      !tracking.areas.every(
        (area) => dependencyResults[areaJobs[area]]?.result === "success",
      ) ||
      !tracking.jobs.every((name) =>
        jobs.some(
          (job) => safe(job.name) === name && job.conclusion === "success",
        ),
      ) ||
      jobs.some((job) => failures.has(job.conclusion))
    )
      return;
    // Require actual successful checks in each previously failing area, even for legacy reports.
    if (
      !tracking.areas.every((area) =>
        jobs.some(
          (job) => areaFor(job.name) === area && job.conclusion === "success",
        ),
      )
    )
      return;
    await github.rest.issues.createComment({
      ...repo,
      issue_number: existing.number,
      body: `All required CI checks and the previously failing checks passed on the latest commit ${run.head_sha}. Automatically closing as completed.\n\n[Successful run, attempt ${run.run_attempt}](${run.html_url})`,
    });
    await github.rest.issues.update({
      ...repo,
      issue_number: existing.number,
      state: "closed",
      state_reason: "completed",
    });
    await core.summary
      .addHeading("Resolved CI failure issue")
      .addList([existing.html_url])
      .write();
    return;
  }
  if (existing?.state !== "closed" && existing?.body?.includes(attemptMarker)) {
    links.push(existing.html_url);
    await core.summary.addHeading("CI failure issues").addList(links).write();
    return;
  }

  const configured = [...groups.keys()].flatMap((area) =>
    usernames(
      area === "Backend"
        ? env.CI_BACKEND_ASSIGNEES
        : area === "Flutter"
          ? env.CI_FLUTTER_ASSIGNEES
          : area === "Web"
            ? env.CI_WEB_ASSIGNEES
            : env.CI_DEFAULT_ASSIGNEES,
    ),
  );
  const defaults = usernames(env.CI_DEFAULT_ASSIGNEES);
  const fallback = [pr?.user?.login, run.actor?.login, repo.owner].filter(
    Boolean,
  );
  let assignees = [];
  // Assign the PR author and all failed-area owners together, author first.
  // Existing assignees are retained when later failures add another CI area.
  for (const tier of [
    [
      pr?.user?.login,
      ...(existing?.assignees ?? []).map((user) => user.login),
      ...configured,
    ].filter(Boolean),
    defaults,
    ...fallback.map((name) => [name]),
  ]) {
    for (const assignee of new Set(tier)) {
      try {
        await github.rest.issues.checkUserCanBeAssigned({
          ...repo,
          assignee,
        });
        assignees.push(assignee);
      } catch (error) {
        if (![404, 422].includes(error.status)) throw error;
        core.warning(
          `Cannot assign ${category} failure to ${assignee}; trying fallback.`,
        );
      }
    }
    if (assignees.length) break;
  }
  assignees = [...new Set(assignees)].slice(0, 10);
  if (!assignees.length)
    core.warning(
      `No eligible assignee for ${category}. Configure CI_DEFAULT_ASSIGNEES.`,
    );

  const rows = failedJobs.map((job) => {
    const steps = (job.steps ?? []).filter((step) =>
      failures.has(step.conclusion),
    );
    return `| [${safe(job.name)}](${job.html_url}) | ${safe(job.conclusion)} | ${steps.map((step) => safe(step.name)).join(", ") || "See job log"} |`;
  });
  const reportArtifacts = artifacts.filter(
    (artifact) =>
      !artifact.expired && /test|coverage|golden|robot/i.test(artifact.name),
  );
  const subject = pr ? `PR #${pr.number}` : `branch ${safe(run.head_branch)}`;
  const body = [
    marker,
    attemptMarker,
    `<!-- ci-tracking:${JSON.stringify({
      areas: [
        ...new Set([
          ...(existing?.state === "closed" ? [] : trackingFor(existing).areas),
          ...groups.keys(),
        ]),
      ],
      jobs: [
        ...new Set([
          ...(existing?.state === "closed" ? [] : trackingFor(existing).jobs),
          ...failedJobs.map((job) => safe(job.name)),
        ]),
      ],
      runNumber: run.run_number,
    })} -->`,
    `## ${category} CI failure`,
    "",
    "A CI check failed and needs investigation. This is not yet a confirmed application bug.",
    "",
    "### Execution",
    "",
    `- **Source:** ${pr ? `[${subject}](${pr.html_url})` : subject}`,
    `- **Commit:** [${run.head_sha.slice(0, 12)}](${context.serverUrl}/${repo.owner}/${repo.repo}/commit/${run.head_sha})`,
    `- **Run:** [${safe(run.name)} #${run.run_number}, attempt ${run.run_attempt}](${run.html_url})`,
    `- **Responsibility:** ${assignees.length ? assignees.map((name) => `@${name}`).join(", ") : "Unassigned — configure CI_DEFAULT_ASSIGNEES in repository Actions variables."}`,
    "",
    "### Failed checks",
    "",
    ...(rows.length
      ? ["| Job | Result | Failed step |", "| --- | --- | --- |", ...rows]
      : [
          "No failed job details were available. Inspect the workflow run for startup or infrastructure errors.",
        ]),
    "",
    "### Test reports",
    "",
    ...(reportArtifacts.length
      ? reportArtifacts.map(
          (artifact) =>
            `- [${safe(artifact.name)}](${run.html_url}/artifacts/${artifact.id})`,
        )
      : [
          `No test report artifacts are available. Check the [run logs](${run.html_url}); the failure may have occurred before tests started.`,
        ]),
    "",
    "### Investigation checklist",
    "",
    "- [ ] Reproduce the failure at the linked commit.",
    "- [ ] Compare the observed behavior with the requirement and test expectations.",
    "- [ ] Identify whether the cause is application code, a test, or the environment.",
    "- [ ] Link the fix and verify the relevant checks pass before closing this issue.",
    "",
    "This issue combines CI failures for the same PR or branch. Earlier run links are retained in comments.",
  ].join("\n");
  const title = `[CI] Failure — ${pr ? `PR #${pr.number}` : run.head_branch}`;
  if (existing) {
    // Save the previous evidence before replacing the current report.
    await github.rest.issues.createComment({
      ...repo,
      issue_number: existing.number,
      body: `Previous failure report:\n\n${existing.body}`,
    });
    await github.rest.issues.update({
      ...repo,
      issue_number: existing.number,
      title,
      body,
      assignees,
      state: "open",
    });
    links.push(existing.html_url);
  } else {
    const { data } = await github.rest.issues.create({
      ...repo,
      title,
      body,
      assignees,
    });
    links.push(data.html_url);
  }
  await core.summary.addHeading("CI failure issues").addList(links).write();
};

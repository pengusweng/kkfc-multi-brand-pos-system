# Web testing handoff

Run commands from `web/` with Node.js 22.12 or newer (Node 22 is used in CI).
On Windows PowerShell, use `npm.cmd` / `npx.cmd` if script execution is disabled.

## First run

```sh
npm ci
npx playwright install chromium
```

Set `API_URL=http://127.0.0.1:3000` in `web/.env` before building or running Next.js.
The three starter tests do not require a running backend or database. The browser
smoke test opens the login page in a fresh browser session without submitting it.

## Commands

| Command | Purpose |
| --- | --- |
| `npm test` | Run all Vitest unit and integration tests once |
| `npm run test:unit` | Run unit tests only |
| `npm run test:integration` | Run component/server integration tests only |
| `npm run test:watch` | Watch Vitest tests during development |
| `npm run test:coverage` | Run Vitest with text, HTML and LCOV coverage |
| `npm run lint` | Check app, test and config source |
| `npm run typecheck` | Generate Next.js route types and check TypeScript |
| `npm run build` | Build the production app before browser tests |
| `npm run test:e2e` | Run Chromium tests against the production app |
| `npm run test:e2e:ui` | Open Playwright's interactive test runner |
| `npm run test:e2e:report` | Open the last Playwright HTML report |

Playwright starts `next start` on `127.0.0.1:3001` automatically after you build.
Locally it can reuse a running app at that address; stop any existing app first
when you specifically want to verify your new production build.

## Adding tests

- **Unit:** put `*.test.ts` alongside source. The starter
  `src/features/auth/schemas/loginSchema.test.ts` tests credential normalization.
- **Component integration:** put `*.test.tsx` alongside source. The starter
  `src/features/auth/components/login-card.test.tsx` exercises the real form,
  hook, React Query and API service, with MSW returning a 401 response.
- **Server integration:** use `*.integration.test.ts` with
  `// @vitest-environment node` at the top for route-handler/proxy tests.
  Direct handler tests do not prove Next.js routing or cookie behavior in a browser.
- **Browser:** put `*.spec.ts` under `tests/e2e/`. The starter `login.spec.ts`
  checks the home redirect and password visibility in a real browser.

Vitest's shared setup starts MSW, rejects unhandled network requests, resets
handlers and cleans up rendered components after every test. Use
`server.use(http.get/post(...))` for test-specific responses; put reusable handlers
in `tests/mocks/server.ts`. Create a fresh QueryClient per component test.
Keep assertions about observable behavior and use labels/roles for UI queries.

Async Server Components and actual Next.js redirects should be tested through
Playwright. Browser `page.route()` mocks cannot intercept server-side fetches.
For those cases, run a controlled upstream API server or the real NestJS API.

## CI and reports

`.github/workflows/web-ci.yml` runs lint, Vitest with coverage, production build,
type checking and Chromium smoke tests. The required CI workflow selects it for
`web/**` and web workflow changes and includes its result in the final `CI` check.
The workflow can also be run manually from GitHub Actions.
Web failures participate in the existing automatic issue reporter. Optionally set
the repository Actions variable `CI_WEB_ASSIGNEES` to QA usernames; existing
default-owner and author fallback rules apply when it is unset.

The `web-test-results` artifact contains JUnit results (`reports/`), coverage
(`coverage/`), Playwright HTML (`playwright-report/`) and failure screenshots and
traces (`test-results/`). These generated files are ignored by Git.
Coverage is informational initially; there is no arbitrary percentage gate.

## Next work for QA

Expand validation/error cases, loading behavior and route access coverage first.
For full-stack browser tests, add an isolated PostgreSQL service, apply Prisma
migrations, prepare deterministic role-specific users, and start NestJS on the
configured `API_URL` before Playwright. The backend CI and
`server/prisma/e2e-fixtures.ts` show the existing fixture lifecycle; review them
before reuse. Keep test accounts/data isolated and clean up after execution.

The starter smoke suite does **not** verify successful authentication, session
cookies, database persistence or protected-route authorization. In particular,
the current dashboard is a placeholder with no server-side access guard; agree
on the intended access behavior with development before adding passing access
tests. Keep existing backend Jest/Robot suites and Flutter suites in place.

# DevFlow AI — Master Project Context

**Version:** 1.3
**Status:** Repository-reconciled, with owner decisions recorded and the backend/frontend boundaries reflected. Supersedes v1.2 and earlier briefings.
**Last reconciled:** against the repository on `feature/repository-structure-refactor`, based on `e8ca84c`; current changes are uncommitted.
**Purpose:** A single portable briefing and navigation hub for any coding agent or human developer working on DevFlow AI.

> **Read order for agents:** this file, then `AGENTS.md`, then the subject documents listed in [§4 Source of truth](#4-source-of-truth-model).
> This file is an **index and orientation document**. It summarizes and links; it does not replace the detailed specifications.
> If documents conflict, follow the [conflict-resolution order](#9-conflict-resolution) instead of guessing.
>
> **Decision status (2026-10-13):** ADRs `0001`, `0002`, `0003`, `0004`, `0007`, `0008`, `0010`, and `0011` are **Accepted** and binding. ADRs `0005`, `0006`, and `0009` remain **Proposed** and are **not** binding. See [`docs/decisions/README.md`](docs/decisions/README.md).

---

## 1. What DevFlow AI is

DevFlow AI is intended to be a **controlled agentic software-engineering platform**: a control center for coordinating AI coding agents through task workflows, shared project context, permission-governed tools, human approval, and automated verification.

The problem it addresses is not simply "how to generate code." Developers using multiple coding agents can face fragmented context, conflicting edits, unclear progress, unsafe tool access, repeated manual coordination, and inconsistent verification. DevFlow AI aims to make this work more trackable, repeatable, observable, and governable.

**One-sentence description:** DevFlow AI turns coding requests into trackable, coordinated, testable, and permission-controlled workflows across AI coding agents.

### Intended users
- Individual developers coordinating one or more AI coding agents.
- Small engineering teams that need repeatable, auditable AI-assisted development.
- Maintainers who want to evaluate task outcomes and reduce unverified changes.

### What it is not
- Not a replacement for every coding model or agent.
- Not a guarantee that generated code is correct.
- Not unrestricted autonomous shell access.
- Not an automatic code-merging or deployment system without policy and approval.
- Not a reason to add microservices, vector databases, or multiple agents before the core workflow is reliable.

---

## 2. Verified repository state

**Verified implementation base:** M1 API foundation merged into `dev` by PR #2 at `f373ebc`, based on `e82ba8f`. The current owner-approved repository refactor is uncommitted on `feature/repository-structure-refactor`, based on `e8ca84c`; verify Git status before relying on local changes.

| Fact | Verified value |
|---|---|
| Branch | `feature/repository-structure-refactor` based on `dev` at `e8ca84c`; changes are uncommitted |
| Merge commit | PR #2, `f373ebcccac6984cc0c957127d804ccd40b6980b`; feature commit `acdd0d64f22539d745ae2d19972c788a45879f8b` |
| Implementation state | FastAPI foundation relocated under `backend/`; Docker Compose backend and PostgreSQL startup added; verify current diff and checks before merge |
| Application source code | Python API under `backend/devflow_api/`; `frontend/` is reserved with a README only; no frontend or workflow code |
| Dependency manifests / lockfiles | Self-contained backend `backend/pyproject.toml`, `backend/uv.lock`, and `backend/.python-version`; no frontend package manifest |
| Test suites / test config | pytest unit tests and guarded PostgreSQL integration test under `backend/tests/` |
| CI/CD workflows | **None.** `.github/` contains only `copilot-instructions.md` |
| Docker / deployment files | Root `compose.yaml` starts PostgreSQL and backend; migration is explicit. `docs/DEPLOYMENT.md` is planning guidance only; no production deployment is configured |
| Type of repository | Documentation and specifications plus the Python API foundation and root local Compose services |
| Executable scripts | Documentation validator plus the `devflow-api` entry point |
| Gitignored tooling | `.agents/`, `.claude/`, `.codex/`, `.opencode/` (installed skill libraries), `graphify-out/`, `.gemini/`, `.antigravity/` |

**Ignored agent directories are anticipatory, not present.** `.gemini/` and `.antigravity/` are listed in `.gitignore` (lines 60–61) but **do not exist** in this checkout. Both rules are on the machine-local tooling list for consistency with the other agent directories; if either is created and holds project-owned instructions, it must be added to the cross-agent matrix in `AGENTS.md` and evaluated on its merits rather than remaining ignored by default.

Re-verify with:

```bash
git rev-parse HEAD
git status --short
git ls-files
```

### Environment configuration

**`.env.example` is present** with local placeholder values. `.gitignore` excludes `.env` and permits `!.env.example`; no real credentials are tracked.

**Prefix convention:** application configuration uses `DEVFLOW_`. Genuinely conventional infrastructure keeps its ecosystem-standard names (`POSTGRES_*`) rather than being forced into the prefix.

**Required variable surface** (names fixed now so scripts, tests, and CI do not invent divergent ones):

| Group | Variables | Notes |
|---|---|---|
| Environment | `DEVFLOW_ENV`, `DEVFLOW_LOG_LEVEL`, `DEVFLOW_LOG_FORMAT` | `local` \| `ci` \| `production`; JSON logs in deployed environments |
| API | `DEVFLOW_API_HOST`, `DEVFLOW_API_PORT`, `DEVFLOW_CORS_ORIGINS`, `DEVFLOW_REQUEST_ID_HEADER` | |
| Database | `DEVFLOW_DATABASE_URL`, `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` | `DEVFLOW_DATABASE_URL` is the composed DSN the app reads (`postgresql+asyncpg://…`) |
| Redis | `DEVFLOW_REDIS_URL` | **Optional and empty by default.** Redis must never be required for correctness (ADR 0002) |
| Auth | `DEVFLOW_SESSION_SECRET`, `DEVFLOW_SESSION_TTL_SECONDS`, `DEVFLOW_SESSION_IDLE_TTL_SECONDS`, `DEVFLOW_PASSWORD_HASH`, `DEVFLOW_CSRF_ENABLED` | `DEVFLOW_PASSWORD_HASH=argon2id`; the secret is generated locally, never committed |
| Approvals | `DEVFLOW_APPROVAL_TTL_SECONDS` | Default 86400 (24 h), per ADR 0010 |
| Adapters | `DEVFLOW_AGENT_ADAPTER`, `DEVFLOW_ADAPTER_DEFAULT_ID`, `DEVFLOW_MOCK_SEED`, `DEVFLOW_MOCK_SCENARIO`, `DEVFLOW_LOCAL_ENDPOINT`, `DEVFLOW_LOCAL_MODEL_TAG`, `DEVFLOW_HOSTED_ENABLED`, `DEVFLOW_HOSTED_CREDENTIAL_REF`, `DEVFLOW_MAX_OUTPUT_TOKENS`, `DEVFLOW_REQUEST_TIMEOUT_SECONDS` | **`DEVFLOW_AGENT_ADAPTER=mock`** and **`DEVFLOW_HOSTED_ENABLED=false`** are the defaults; `DEVFLOW_HOSTED_CREDENTIAL_REF` holds a secret-manager **reference**, never an inline key |
| Limits | `DEVFLOW_TASK_WALL_CLOCK_SECONDS`, `DEVFLOW_MAX_STEPS_PER_TASK`, `DEVFLOW_MAX_TOOL_CALLS_PER_TASK`, `DEVFLOW_MAX_CONCURRENT_JOBS`, `DEVFLOW_MAX_CONCURRENT_MODEL_CALLS`, `DEVFLOW_TASK_COST_CAP_USD` | Values are **Proposed** defaults pending ADRs 0005/0009 |

**Rules:** placeholders only in `.env.example` — never a real value; production secrets come from a secret manager, not a file; secrets are never logged (`SR-15`); and no agent may invent a variable name outside this table without updating it in the same change set.

### Consequences you must not ignore
- **Product capabilities remain planned.** The initial API foundation implements only configuration, DB lifecycle, migrations, and health/readiness; no task lifecycle, authentication, workspace authorization, worker, dashboard, or product CLI exists.
- Milestone 0 documentation reconciliation is complete; Milestone 1 developer foundation is in progress. Do not describe later milestone work as existing.
- **No performance number has ever been measured.** All budgets are unverified targets. Never report one as achieved without recorded evidence (environment, load, percentiles, command).
- `graphify-out/` is present but **stale and low-value for this repository** (see [§8](#8-known-caveats-and-traps)).

### Documentation inventory (tracked)

| Document | Purpose |
|---|---|
| `PROJECT_CONTEXT.md` | This file — master overview and navigation |
| `README.md` | Entry point, MVP direction, engineering priorities |
| `PRD.md` | Product scope, users, requirements, non-goals, acceptance criteria |
| `SPEC.md` | Task lifecycle and initial API contract (externally observable behavior) |
| `ARCHITECTURE.md` | Components, boundaries, data flow, performance, reliability, security architecture |
| `Design-system.md` | Visual tokens, shadcn/ui conventions, accessibility, motion |
| `AGENTS.md` | Universal coding-agent rules and single-agent development workflow |
| `CLAUDE.md` | Claude Code-specific instructions (delegates to `AGENTS.md`) |
| `GEMINI.md` | Gemini CLI-specific instructions (delegates to `AGENTS.md`) |
| `CODE_STYLE.md` | Engineering conventions (Python, TypeScript, API, Git) |
| `docs/SECURITY.md` | Security baseline and review checklist |
| `docs/THREAT_MODEL.md` | Assets, trust boundaries, STRIDE analysis, mitigations, residual risk |
| `docs/TESTING.md` | Test levels, quality gates, performance measurement |
| `docs/PERFORMANCE.md` | Performance budgets and benchmark protocol |
| `docs/DEPLOYMENT.md` | Future server deployment requirements and current limitations |
| `docs/API_CONTRACTS.md` | API conventions, error model, versioning, SSE contract |
| `docs/AGENT_RUNTIME.md` | Adapter interfaces, workflow state, execution bounds, failure handling |
| `docs/DATABASE.md` | Entities, migrations, indexing, retention, ownership |
| `docs/REQUIREMENTS_TRACEABILITY.md` | Requirement → component → test → evidence mapping |
| `docs/DOCUMENTATION_INDEX.md` | Source-of-truth map, ownership, verification status |
| `docs/decisions/` | Architecture decision records (ADRs) |
| `.github/copilot-instructions.md` | GitHub Copilot-specific instructions (delegates to `AGENTS.md`) |
| Cross-agent support matrix | See [`AGENTS.md`](AGENTS.md) § Cross-agent support — which agents read `AGENTS.md` natively and which need an adapter |
| `.agent-state/CURRENT.md` | Verified current milestone and status |
| `.agent-state/ACTIVE-TASK.md` | Current bounded task, scope, acceptance criteria, handoff |
| `PLAN.md` | Milestone sequence and exit criteria |
| `tools/validate-docs.ps1` | Documentation validator (links, fences, Mermaid, claims, ADR status, consistency, staleness). Run it after any documentation change. |

Run the validator before handing off a documentation change:

```powershell
powershell -File tools/validate-docs.ps1
```

It currently **passes** against the full documentation set. See [`docs/DOCUMENTATION_INDEX.md`](docs/DOCUMENTATION_INDEX.md) § 7 for what it does and does not prove.

---

## 3. Owner-approved MVP direction

These are **selected architecture directions**, not proof that dependencies are installed or features implemented.

- **Web dashboard:** Next.js App Router, React, TypeScript, Tailwind CSS, shadcn/ui.
- **Backend API:** Python, FastAPI, Pydantic.
- **Workflow orchestration:** LangGraph.
- **CLI:** Python CLI using the same HTTP API as the dashboard.
- **Durable persistence:** PostgreSQL.
- **Redis:** optional and purpose-driven — queue coordination, caching, rate limiting, or ephemeral coordination where justified. Never the only durable store.
- **Long-running work:** separate background worker. Do not hold task-submission HTTP requests open while agents or LLMs work.
- **Progress:** Server-Sent Events (SSE), plus an authoritative task-status endpoint.
- **Tool integrations:** controlled adapters, eventually including MCP.
- **Context/retrieval:** RAG is a later capability, not a prerequisite for the first vertical slice.
- **UI direction:** consistent shadcn/ui components, `Design-system.md` tokens, accessibility, responsive behavior, restrained motion, measured performance.

### Free-first inference strategy
1. Start with a **deterministic mock model/agent adapter**. This allows workflow, task lifecycle, error, retry, approval, and progress tests without inference cost.
2. Add a **local model provider** such as Ollama behind a provider/agent adapter. Local inference avoids per-request hosted charges but consumes local compute and may be slower or less capable depending on hardware.
3. Consider **hosted free tiers only as optional adapters**. Do not make core architecture depend on any provider's free tier, limits, or continued availability.

Keep workflow orchestration separate from the model provider so switching providers does not require rewriting the task domain or LangGraph workflow.

---

## 4. Source-of-truth model

Each subject has exactly one authoritative document. Summaries elsewhere must link, not duplicate.

| Subject | Authoritative document |
|---|---|
| Product scope, users, requirements, non-goals, acceptance criteria, success metrics | `PRD.md` |
| Externally observable behavior: task states, transitions, error semantics, contract overview | `SPEC.md` |
| API conventions, error envelope, versioning, auth, SSE protocol | `docs/API_CONTRACTS.md` |
| System components, boundaries, data flow, performance/reliability/security architecture | `ARCHITECTURE.md` |
| Agent adapters, workflow stages, execution bounds, failure handling | `docs/AGENT_RUNTIME.md` |
| Data model, migrations, indexing, retention, data ownership | `docs/DATABASE.md` |
| Security requirements and threat analysis | `docs/SECURITY.md`, `docs/THREAT_MODEL.md` |
| Test levels, quality gates, performance measurement protocol | `docs/TESTING.md` |
| Performance budgets and benchmark protocol | `docs/PERFORMANCE.md` |
| Future deployment operations and current deployment limits | `docs/DEPLOYMENT.md` (planning guidance; ADR 0004 remains the topology decision) |
| Visual tokens, components, accessibility, motion | `Design-system.md` |
| Engineering conventions | `CODE_STYLE.md` |
| Universal agent rules and single-agent development workflow | `AGENTS.md` |
| Milestone sequence and exit criteria | `PLAN.md` |
| Requirement → component → test → evidence mapping | `docs/REQUIREMENTS_TRACEABILITY.md` |
| Durable decision rationale | `docs/decisions/` |
| Verified current state | `.agent-state/CURRENT.md` |
| Active bounded task | `.agent-state/ACTIVE-TASK.md` |
| Navigation and orientation | `PROJECT_CONTEXT.md` (this file) |

Ownership, staleness rules, and the full index are maintained in `docs/DOCUMENTATION_INDEX.md`.

---

## 5. What the system should do

### Example user journey
A user submits: "Add password reset to this repository and test it."

1. The user submits the task through the web dashboard or CLI.
2. FastAPI authenticates and validates the request.
3. The API persists the task and reliable dispatch intent, then responds promptly with `202 Accepted` and a task ID.
4. A background worker claims the task and runs the LangGraph workflow.
5. The workflow uses permitted agent/model/tool adapters and project context.
6. The workflow may pause in `needs_approval` before a consequential action.
7. Progress is persisted and made available to the dashboard/CLI.
8. The workflow runs the configured verification steps.
9. The user sees a final state and honest verification results.

### Core task states
- `queued`: accepted and waiting for a worker.
- `running`: worker is executing.
- `needs_approval`: paused for a human decision.
- `completed`: verified terminal success.
- `failed`: unrecoverable failure.
- `cancelled`: cancellation has been acknowledged.
- `blocked`: a dependency or policy condition prevents progress.

Allowed transitions (**owner-approved 2026-10-13**):
- `queued` → `running`, `cancelled`, `blocked`
- `running` → `needs_approval`, `completed`, `failed`, `cancelled`, `blocked`
- `needs_approval` → `running`, `failed`, `cancelled`, `blocked`
- `blocked` → `queued`, `cancelled`
- `completed`, `failed`, and `cancelled` are terminal (never reopened).

Centralize lifecycle validation in domain logic, not only in UI code. Record actor, timestamp, from/to state, reason, and attempt where applicable. Retries must be explicit; never silently reopen a terminal task.

**Approval outcomes.** A task in `needs_approval` reaches `failed` with a machine-readable `terminal_reason`: `approval_rejected` when a human declines, `approval_expired` when the decision window closes (default 24 hours, configurable by task type). A rejected or expired approval **never permits execution** — the gated action is permanently refused for that attempt. **Silence is never consent.** `needs_approval → blocked` is reserved for a non-approval policy condition at the gate; `needs_approval → completed` is forbidden. See `SPEC.md` § Approval outcomes and [`docs/decisions/0010-approval-outcome-transitions.md`](docs/decisions/0010-approval-outcome-transitions.md).

### Initial API contract (summary only)
- `POST /api/v1/tasks` — validates, persists task and dispatch intent, returns `202 Accepted` with `task_id`, status URL, and events URL.
- `GET /api/v1/tasks/{task_id}` — caller-authorized task snapshot.
- `GET /api/v1/tasks/{task_id}/events` — SSE progress/events with event IDs and reconnect/snapshot recovery.
- `POST /api/v1/tasks/{task_id}/cancel` — requests cancellation; distinguishes request accepted from worker-confirmed cancellation.
- `POST /api/v1/tasks/{task_id}/approval` — records an authorized approval/rejection only when a decision is pending.

Authoritative detail: `SPEC.md` and `docs/API_CONTRACTS.md`.

---

## 6. Architecture and responsibilities

### Next.js + shadcn/ui dashboard
- Task creation, list/detail, progress, approvals, results, errors, and history.
- Prefer Server Components for static/initial content; Client Components where interactivity is required.
- Lazy-load heavy editors and graph visualizations.
- Keep client bundles and rerenders small; batch/throttle noisy progress events.
- Provide loading, empty, error, reconnecting, approval-needed, blocked, success, and cancelled states.
- Respect keyboard navigation, visible focus, semantic markup, reduced motion, and responsive layouts.

### FastAPI
- Authentication, authorization, input validation, task API, event streaming, consistent errors.
- Correct async I/O; never block async handlers with long-running synchronous work.
- Task submission performs only bounded work: validate, persist task/dispatch intent, enqueue or record durable dispatch, return.
- Never runs the entire LangGraph workflow inside the submission request.

### LangGraph worker
- Runs separately from API request handlers.
- Explicit typed state and bounded stages: plan, execute, verify, report.
- Supports bounded retries, deadlines, cancellation checks, approval pause/resume, failure handling, checkpoint/recovery.
- Bounded concurrency.
- LangGraph checkpointing alone does not guarantee durable queue delivery; queue/database dispatch recovery must be designed separately.
- Worker delivery may be at-least-once. Handlers must be idempotent; do not claim exactly-once execution without evidence.

### PostgreSQL
- Durable source of truth for tasks, state transitions, attempts, approvals, and audit events.
- Transactions for task creation and lifecycle changes.
- Avoid losing a task between database commit and queue dispatch; evaluate a transactional outbox or proven durable job mechanism.
- Migrations, connection pooling, and indexes justified by query patterns.

### Redis
- Add only where justified. Not the only durable store for task/audit history.
- Pick and document a queue strategy, retry policy, and crash-recovery guarantee before implementing production worker dispatch.

### Python CLI
- Uses the same authenticated HTTP API and task contracts as the dashboard.
- Covers submit, status, follow progress, cancellation, and approval where authorized.
- Does not duplicate backend business logic.

### Agent adapters, tool gateway, MCP, and RAG
- Provider/agent adapters hide model-specific APIs from domain/workflow code.
- Tool gateway is the policy boundary: explicit allowlist, validated schemas, least privilege, timeouts, output limits, audit events.
- Treat model output, tool output, repository content, and retrieved documents as untrusted.
- MCP servers are privileged integrations; review identity, permissions, transport, credentials, and allowed methods.
- RAG is later work. Define provenance, access filtering, freshness, deletion, and evaluation before implementing retrieval.
- Retrieved content may inform decisions but cannot grant permissions or override system policy.

Authoritative detail: `ARCHITECTURE.md`, `docs/AGENT_RUNTIME.md`, `docs/THREAT_MODEL.md`.

---

## 7. Performance, security, and quality principles

### Performance
Performance is a requirement, but targets must be **measured**, not represented as achieved.

Initial targets (unverified):
- Lightweight/cached API reads: p95 under 100 ms.
- Database-backed API reads: p95 under 200 ms.
- Task submission: p95 under 200 ms.
- Web INP: at or below 200 ms.
- Web LCP: at or below 2.5 seconds.
- Aim for 60 FPS on representative hardware for common interactions.

Measure API server time **separately** from queue wait, LLM latency, tool latency, graph duration, and total task duration. A performance result must state environment, workload, concurrency, duration, percentiles, and the exact command used.

### Security and safety
- Authenticate non-public endpoints; authorize every task read, event stream, cancellation, approval, and result access.
- Opaque task IDs are not authorization.
- Secrets never belong in source control or logs.
- Tool execution is deny-by-default, allowlisted, schema-validated, permission-scoped, bounded, and audited.
- No unrestricted host shell/filesystem/network access for agents; risky operations run in a restricted sandbox.
- Human approval for configured consequential actions.
- Bound execution time, concurrency, retries, output sizes, and provider spend.
- Cancellation semantics must be explicit; duplicate queue delivery handled idempotently.
- Persist important transitions independently of transient SSE connections.
- Never claim a security control or test passed unless verified.

Full analysis: `docs/SECURITY.md` and `docs/THREAT_MODEL.md`.

### Testing
Required layers: unit (lifecycle, invalid transitions, terminal states, policy, idempotency, event serialization); API integration (validation, authorization, status/error contracts, durable acceptance, cancellation, approvals, SSE reconnection); worker/graph (success, failure, timeout, retries, cancellation, approval pause/resume, duplicate delivery, restart/recovery, bounded concurrency); frontend (flows, accessibility, loading/error/empty/reconnect, responsive, reduced motion); performance (API p50/p95/p99, queue wait, worker throughput, pool behavior, LLM/tool time, bundle size, INP, LCP, frame rate).

Prefer deterministic mock adapters. Live-provider tests are optional, separately labeled, and cost-controlled.

Authoritative detail: `docs/TESTING.md`, `docs/REQUIREMENTS_TRACEABILITY.md`.

---

## 8. Known caveats and traps

1. **`graphify-out/` is stale and noisy.** The graph was built from commit `92b26715`, far behind the current repository. Its 3,369 nodes are dominated by third-party skill libraries under `.agents/`, `.claude/`, `.codex/`, and `.opencode/`, and it does not include the API under `backend/`. `graphify-out/wiki/index.md` referenced by `CLAUDE.md` **does not exist**. Do not rely on the graph for DevFlow AI architecture questions until it is regenerated against first-party sources.
2. **The v1.0 briefing was inaccurate.** It listed files that do not exist in this checkout. Do not re-introduce them as if present.
3. **`docs/PERFORMANCE.md`, `PRD.md`, `ARCHITECTURE.md`, and `docs/TESTING.md` all restate the same budgets.** `docs/PERFORMANCE.md` is authoritative; the others should link to it rather than diverge.
4. **No CI exists.** Any "quality gate" language describes intent, not enforcement.
5. **Do not commit or push** without explicit owner authorization.

---

## 9. Conflict resolution

Order of precedence:
1. An **explicit latest owner decision** overrides an older proposal.
2. **Security and safety constraints** cannot be weakened silently.
3. **Detailed subject documents** govern their domains (see [§4](#4-source-of-truth-model)).
4. **`PROJECT_CONTEXT.md`** summarizes and links to those documents.
5. If two authoritative documents conflict and owner intent is unclear, **stop and ask** rather than choosing silently.

---

## 10. Coding-agent operating protocol

### Before work
1. Inspect `git status --short`, current branch, recent commits, and the actual tree.
2. Read this file, `AGENTS.md`, and the subject documents relevant to the change.
3. Identify relevant tool-specific instructions and skills.
4. Check existing changes and tests before editing.
5. State a bounded task, files in scope, acceptance criteria, and dependencies.

### During work
- Preserve user changes, existing instructions, and skills.
- Make small, coherent, testable changes.
- Do not perform broad rewrites or move files without a reason and explicit plan.
- Use one coding agent at a time by default; Codex is primary unless the user selects another.
- If parallel agents are explicitly authorized, use separate worktrees and branches, with one writer per shared file/feature and agreed ownership/contracts.
- **Ask before changing** secrets/configuration, deployment, security boundaries, retention, or product scope.
- Do not install large dependency sets without presenting the dependency list and rationale.
- Do not commit, push, publish, or deploy unless explicitly authorized.

### After work
Report: what changed and why; files changed; exact commands/tests run and their results; performance results with environment/load details; known limitations and follow-up work; decisions still requiring owner input; documentation needing updates.

**Never claim that code, tests, integrations, or performance targets exist or pass unless actually verified.**

---

## 11. How project details stay current

The project uses version-controlled documentation as durable memory rather than relying on an AI chat's memory.

When an agent proposes a betterment:
1. Explain the problem with evidence; describe the proposed change, alternatives, trade-offs, risks, and validation plan.
2. Inspect current documents and code before deciding.
3. If it is a material product/architecture/security decision, ask the owner or clearly mark it as a proposal. Do not silently change an owner-approved decision.
4. After approval, update all affected source-of-truth documents in the same change set (see the table in [§4](#4-source-of-truth-model)).
5. Run relevant checks and review `git diff`.
6. Commit only when the owner requests it.

Record durable decisions as ADRs in `docs/decisions/NNNN-short-title.md` containing status, context, decision, alternatives, consequences, and date.

---

## 12. Current status and next step

- The owner has approved the high-level MVP direction in [§3](#3-owner-approved-mvp-direction).
- The initial API foundation is merged into `dev`; this branch relocates it under `backend/`. Product workflows, frontend implementation, and CI remain unimplemented.
- Implementation status, Git state, package managers, dependencies, and measurements must always be verified locally.
- **No production-readiness, security-audit, or performance claim is implied by this document.**

**Next step:** Finish Milestone 1 by adding CI and its documentation-validation gate. See `.agent-state/CURRENT.md` and `PLAN.md`.

---

## 13. Quick-start prompt for any coding agent

> You are working on DevFlow AI. Read `PROJECT_CONTEXT.md`, then `AGENTS.md` and subject documents before editing. At baseline `e82ba8f` the repository contained specifications and documentation; the API foundation was merged into `dev` at `f373ebc`. Verify Git status and `.agent-state/CURRENT.md`. The owner-approved MVP remains a Next.js + shadcn/ui dashboard, FastAPI + LangGraph backend, Python CLI using the same API, PostgreSQL durable state, optional Redis, a separate background worker, and SSE progress. Keep task submission fast; preserve existing work and agent configuration. Do not claim tests or performance results without evidence. Do not commit or push unless explicitly requested.

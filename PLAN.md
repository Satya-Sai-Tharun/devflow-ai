# Development Plan

**Current direction:** Owner-selected MVP: Next.js + shadcn/ui dashboard, FastAPI + LangGraph backend, Python CLI, PostgreSQL, and Redis only where justified.

## Working rules
- `PRD.md` defines product scope and acceptance criteria.
- `SPEC.md` defines initial API/task contracts.
- `ARCHITECTURE.md` defines system boundaries and performance/reliability principles.
- `AGENTS.md` and existing tool-specific instructions define agent behavior.
- Preserve current skills, configurations, user changes, and repository-specific conventions.
- Each milestone has acceptance criteria and a testable handoff.
- Do not claim implementation, test success, or performance results without evidence.

## Milestone 0 — Documentation and decision alignment
- [x] Record the selected MVP interface and backend.
- [x] Define the fast request path and asynchronous worker principle.
- [x] Define an initial task lifecycle and performance budgets.
- [x] Reconcile every source-of-truth document with the actual local tree and existing instructions.
- [ ] Confirm package managers/runtime versions and durable dispatch strategy — **proposed** in [`docs/decisions/0007`](docs/decisions/0007-runtime-and-package-managers.md) and [`0002`](docs/decisions/0002-durable-job-dispatch.md); awaiting owner approval.

**Exit:** Consistent documents and visible remaining decisions. *(Documentation is consistent; ten decisions are recorded as Proposed in [`docs/decisions/`](docs/decisions/README.md).)*

### Milestone 0 deliverables (completed in this pass)
- [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) reconciled to the verified tree (it did not previously exist).
- [`docs/DOCUMENTATION_INDEX.md`](docs/DOCUMENTATION_INDEX.md) — source-of-truth map, ownership, staleness, and change-management rules.
- New specifications: [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md), [`docs/API_CONTRACTS.md`](docs/API_CONTRACTS.md), [`docs/AGENT_RUNTIME.md`](docs/AGENT_RUNTIME.md), [`docs/DATABASE.md`](docs/DATABASE.md), [`docs/REQUIREMENTS_TRACEABILITY.md`](docs/REQUIREMENTS_TRACEABILITY.md).
- [`docs/decisions/`](docs/decisions/README.md) — ADRs 0001–0010 recording the previously unwritten decisions.
- One open specification gap surfaced and documented: rejected/expired approval transitions ([`0010`](docs/decisions/0010-approval-outcome-transitions.md)). This blocks Milestone 2 until decided.

### Decisions blocking Milestone 1
Decisions are listed in the order they must be resolved, because several of them constrain the **database schema**, not just the milestone that consumes them.

| Decision | ADR | Must be resolved before | Why this early |
|---|---|---|---|
| Runtime versions and package managers | [0007](docs/decisions/0007-runtime-and-package-managers.md) | Any scaffolding, lockfile, or CI | Nothing is installable without it; it also decides single-package vs monorepo, which changes layout and import paths |
| Authentication and tenancy | [0003](docs/decisions/0003-auth-and-tenancy.md) | **Milestone 2 schema**, not only Milestone 3 | The tenancy boundary determines whether `tasks.owner_id`/`tenant_id` exist and whether every query carries a scope predicate. Adding tenancy after the first migration is a schema change plus an authorization audit; do it first |
| Durable job dispatch and recovery | [0002](docs/decisions/0002-durable-job-dispatch.md) | **Milestone 2 schema** (outbox), enforced in Milestone 5 | The chosen mechanism fixes the outbox shape, status vocabulary, and lease semantics that the migration will freeze |
| Database identity and migrations | [0008](docs/decisions/0008-database-identity-and-migrations.md) | Milestone 2 schema | Decides primary/public identity split and the migration tool; depends on the ORM/driver choice, which currently has no owning ADR |
| Approval outcome transitions | [0010](docs/decisions/0010-approval-outcome-transitions.md) | **Milestone 2 transition function** | `SPEC.md` has no legal transition for a rejected or expired approval. This **hard-blocks** the transition function and its test matrix — it is not deferrable to the approval milestone |
| Deployment topology | [0004](docs/decisions/0004-deployment-topology.md) | Local dev stack, health/readiness contract | Determines the compose surface and whether health endpoints exist at all |
| Model provider strategy and spend controls | [0005](docs/decisions/0005-model-provider-strategy.md) | Milestone 5 | Numeric spend ceilings and a global model-call concurrency limit are still absent |
| Tool execution sandbox | [0009](docs/decisions/0009-tool-execution-sandbox.md) | Milestone 7 | Sandbox bounds (timeout, memory, egress) have no values yet |
| Data retention and privacy | [0006](docs/decisions/0006-data-retention-and-privacy.md) | Before any content is stored | Security requirements `SR-23` and `SR-24` are unverifiable until this is Accepted |

**Not every decision blocks Milestone 1.** Only `0007`, `0003`, `0008`, `0002`, and `0010` block the first two milestones; the rest unblock later ones. Resolve them in the order above.

## Milestone 1 — Repository and developer foundation
- Audit tracked/untracked files, Git state, existing package managers, and tool instructions.
- Propose a target folder layout without moving existing files until approved.
- Select Python/Node versions and package managers.
- Establish formatting, lint, type-check, test, and local run commands.
- Add environment examples with placeholders only.
- Add minimal CI only after identifying current conventions.
- Wire the existing documentation validator ([`tools/validate-docs.ps1`](tools/validate-docs.ps1)) into that CI as the first gate. It already runs and passes locally (see [`docs/DOCUMENTATION_INDEX.md`](docs/DOCUMENTATION_INDEX.md) § 7); no CI exists yet, so it is currently a manual step.

**Exit:** Reproducible setup and baseline checks.

## Milestone 2 — Core task domain
- Implement task model and explicit lifecycle transition function.
- Add task attempts, transition history, timestamps, and stable error semantics.
- Add unit tests for valid/invalid transitions, terminal states, cancellation, and retry semantics.
- Select PostgreSQL schema and migration tooling.

**Exit:** Domain rules are test-covered and independent of web/CLI presentation.

## Milestone 3 — FastAPI contract and CLI
- Implement task submission, read, cancellation, and approval API contracts as appropriate.
- Submission persists task and dispatch intent, then returns `202 Accepted`.
- Implement CLI commands through the API.
- Add authentication/authorization stubs only if clearly marked; do not ship unprotected production endpoints.
- **`ADR 0003` must be Accepted before this milestone starts**, not merely before deployment: the tenancy decision from Milestone 2 determines the authorization predicate on every endpoint here. A stub that returns a fixed principal is acceptable **only** in tests and local development, must be impossible to enable in a deployed configuration, and must be marked in code as a stub with a test asserting it cannot be reached when the real mechanism is configured. Milestone exit criteria must **not** be claimed on the strength of a stub.
- Add API integration tests.

**Exit:** CLI can create/read a task using the same contract as the dashboard.

## Milestone 4 — Dashboard foundation
- Build Next.js App Router app and configure shadcn/ui using `Design-system.md`.
- Implement task list/detail and loading, empty, error, approval, and terminal states.
- Keep initial bundle and client state small.
- Add accessible keyboard, focus, reduced-motion, and responsive behavior tests.

**Exit:** Core dashboard flows work against the shared API contract.

## Milestone 5 — Durable background execution and LangGraph
- Choose and document queue, transactional dispatch/outbox, retry, and recovery design.
- Add worker lifecycle and bounded concurrency.
- Implement minimal LangGraph stages: plan, execute placeholder/safe adapter, verify, report.
- Add timeout, cancellation, idempotency, retry, failure, and restart tests.

**Exit:** API submission is decoupled from graph execution and worker recovery behavior is tested.

## Milestone 6 — SSE and human approval
- Publish task progress and lifecycle events.
- Add event IDs, reconnect behavior, snapshot reconciliation, and authorization.
- Implement approval pause/resume and cancellation semantics.

**Exit:** Dashboard and CLI can observe progress and recover current state after reconnect.

## Milestone 7 — Tool gateway and MCP
- Add explicit tool registry/allowlist and adapter contract.
- Validate inputs and outputs; bound time, output size, concurrency, and permissions.
- Add sandboxed execution, audit events, and approval gates.
- Test denied-by-default behavior.

**Exit:** Tool execution is governed and auditable.

## Milestone 8 — Context/RAG and evaluation
- Add retrieval only after source provenance, access filtering, freshness, and deletion behavior are defined.
- Evaluate retrieved context and agent outcomes against repeatable datasets.
- Track quality, latency, cost, and failure modes.

**Exit:** Evaluation results are reproducible and documented.

## Milestone 9 — Performance and hardening
- Benchmark API p50/p95/p99 under documented load.
- Measure queue wait, worker throughput, DB pool utilization, LLM/tool timing, and failure recovery.
- Measure frontend INP/LCP and representative interaction frame rate.
- Optimize based on profiling; do not use performance claims without results.
- Review secrets, authorization, tenant isolation, sandbox, retention, and operational recovery.

**Exit:** Measured performance and reliability results with documented limitations.

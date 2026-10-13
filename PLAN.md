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

### Decision status entering Milestone 1

**Owner decisions recorded 2026-10-13.** Seven ADRs moved from Proposed to **Accepted**; three remain **Proposed and non-binding**. The full index is in [`docs/decisions/README.md`](docs/decisions/README.md).

| Decision | ADR | Status | Must be resolved before | Why this early |
|---|---|---|---|---|
| Runtime versions and package managers | [0007](docs/decisions/0007-runtime-and-package-managers.md) | **Accepted** | Any scaffolding, lockfile, or CI | Python 3.12 + `uv`; Node 22 LTS + `pnpm`; single monorepo. Unblocks all of M1 |
| Authentication and tenancy | [0003](docs/decisions/0003-auth-and-tenancy.md) | **Accepted** | **Milestone 2 schema**, not only Milestone 3 | Argon2id + revocable opaque sessions; scoped PATs for the CLI; **workspace** is the isolation boundary with an owning user. Determines the workspace/owner columns and every scope predicate. **Workspace membership roles still need documenting** before access control is implemented |
| Database identity, migrations, and data access | [0008](docs/decisions/0008-database-identity-and-migrations.md), [0011](docs/decisions/0011-data-access-layer.md) | **Accepted** | Milestone 2 schema | Internal `bigint` PK + public UUIDv7 `public_id`; SQLAlchemy 2.x async + `asyncpg`; Alembic. The ORM choice now has an owning ADR (0011), which previously it did not |
| Durable job dispatch and recovery | [0002](docs/decisions/0002-durable-job-dispatch.md) | **Accepted** | **Milestone 2 schema** (outbox), enforced in Milestone 5 | PostgreSQL transactional outbox; at-least-once; idempotent; bounded retries; audited dead-letter re-drive. **Redis deferred and never required for correctness.** Freezes the outbox status vocabulary (`pending`, `claimed`, `delivered`, `dead_letter`) |
| Approval outcome transitions | [0010](docs/decisions/0010-approval-outcome-transitions.md) | **Accepted** | **Milestone 2 transition function** | `needs_approval → failed` added, with `terminal_reason` of `approval_rejected` or `approval_expired`. Previously a hard block; now unblocked |
| Deployment topology | [0004](docs/decisions/0004-deployment-topology.md) | **Accepted** | Local dev stack, health/readiness contract | Local-first + CI; separate API and worker processes; Docker Compose for the local database. No production target selected yet |
| MVP API contract | `docs/API_CONTRACTS.md` §4.1 | **Accepted** | Milestone 3 | `project_id` **removed**; no project entity or project-scoped endpoint in the MVP. Workspace tenancy supplies isolation |
| Health / readiness | `docs/API_CONTRACTS.md` §9.4 | **Accepted** | Milestone 4 | Public `/healthz` and `/readyz` outside `/api/v1`; readiness reports dependency failure honestly; `/metrics` internal or token-gated |
| Model provider strategy and spend controls | [0005](docs/decisions/0005-model-provider-strategy.md) | **Proposed — not binding** | Milestone 5 | Hosted-provider permission, concrete spend limits, and the local model/hardware baseline remain open. **Mock remains the default; hosted stays disabled** |
| Data retention and privacy | [0006](docs/decisions/0006-data-retention-and-privacy.md) | **Proposed — not binding** | Before any content is stored | Retention windows, raw prompt retention, deletion behavior, and operator access remain open. `SR-23` is unverifiable until Accepted |
| Tool execution sandbox | [0009](docs/decisions/0009-tool-execution-sandbox.md) | **Proposed — not binding** | Milestone 7 | Sandbox implementation, egress rules, approval-required operations, and resource ceilings remain open. **Tool permissions stay server-enforced and absence of an allow rule stays denial** |

**Standing restrictions while 0005, 0006, and 0009 remain Proposed:** mock inference is the default for tests and CI; hosted providers are disabled by default; secrets are never logged; tool permissions are server-enforced and absence of an allow rule means denial; **an expired approval permits no action.**

**Milestone 1 is unblocked.** Its prerequisites are all Accepted. Implementation tasks T2 onward additionally require the owner's explicit authorization to begin; see `.agent-state/CURRENT.md`.

## Milestone 1 — Repository and developer foundation
- [x] Audit tracked/untracked files, Git state, existing package managers, and tool instructions.
- [x] Confirm the API package location from `ARCHITECTURE.md`; create the initial API under `services/api/`.
- [x] Select Python 3.12 and `uv` for the API; Node 22 LTS and `pnpm` remain the documented web choices.
- [x] Establish pytest, Ruff, Pyright, Alembic, and API startup commands.
- [x] Add `.env.example` with placeholders only.
- Add minimal CI only after identifying current conventions.
- Wire the existing documentation validator ([`tools/validate-docs.ps1`](tools/validate-docs.ps1)) into that CI as the first gate. It already runs and passes locally (see [`docs/DOCUMENTATION_INDEX.md`](docs/DOCUMENTATION_INDEX.md) § 7); no CI exists yet, so it is currently a manual step.

**Current status:** M1-T1 API foundation and PostgreSQL acceptance verification are complete on the uncommitted feature/m1-api-foundation branch. Human review and CI remain outstanding, so Milestone 1 is not complete.

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

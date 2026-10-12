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
- [ ] Reconcile every source-of-truth document with the actual local tree and existing instructions.
- [ ] Confirm package managers/runtime versions and durable dispatch strategy.

**Exit:** Consistent documents and visible remaining decisions.

## Milestone 1 — Repository and developer foundation
- Audit tracked/untracked files, Git state, existing package managers, and tool instructions.
- Propose a target folder layout without moving existing files until approved.
- Select Python/Node versions and package managers.
- Establish formatting, lint, type-check, test, and local run commands.
- Add environment examples with placeholders only.
- Add minimal CI only after identifying current conventions.

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

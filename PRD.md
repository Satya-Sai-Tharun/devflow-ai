# DevFlow AI — Product Requirements

## Product statement
DevFlow AI is a controlled agentic software-engineering platform that helps developers coordinate AI coding agents through task workflows, repository context, policy-governed tools, human approval, and automated verification.

## Target users
- Individual developers coordinating one or more coding agents.
- Small engineering teams that need repeatable, auditable AI-assisted development.
- Maintainers who want to evaluate task outcomes and reduce unsafe or unverified changes.

## User problem
Using multiple coding agents can create fragmented context, conflicting edits, inconsistent tool permissions, weak progress visibility, and unreliable verification. DevFlow AI aims to provide one task lifecycle and a governed execution path.

## MVP interfaces and stack
- Web dashboard: Next.js App Router, React, TypeScript, Tailwind CSS, shadcn/ui.
- API: Python, FastAPI, Pydantic.
- Workflow orchestration: LangGraph.
- CLI: Python client using the same HTTP API as the dashboard.
- Durable data: PostgreSQL.
- Redis: only where justified for queue coordination, caching, rate limiting, or ephemeral coordination.
- Long-running agent work runs in a background worker, not in the task-submission request.
- SSE provides task progress updates.

## Goals
1. Submit and inspect tasks through both dashboard and CLI.
2. Keep task submission and ordinary API reads responsive.
3. Represent task state with explicit, validated transitions.
4. Run agent workflows asynchronously with observable progress.
5. Support human approval and cancellation at defined checkpoints.
6. Verify outputs with tests and report outcomes honestly.
7. Establish secure boundaries for tool and MCP execution.
8. Build measurable frontend and backend performance budgets.

## Functional requirements

- **PR-001 Task submission:** Authenticated clients can submit a task and receive `202 Accepted` plus a stable task identifier after durable acceptance.
- **PR-002 Task inspection:** Clients can retrieve the authoritative task state, timestamps, attempts, and permitted result details.
- **PR-003 Lifecycle integrity:** State transitions are validated centrally; invalid transitions are rejected and tested.
- **PR-004 Shared API:** Dashboard and CLI use the same API contract and authorization rules.
- **PR-005 Background execution:** Long-running LangGraph workflows execute in a worker, independent of HTTP request lifetime.
- **PR-006 Progress events:** Clients can receive task progress via SSE and recover by fetching the current task snapshot.
- **PR-007 Approval:** Tasks can pause for an explicit human decision before configured consequential operations.
- **PR-008 Cancellation and timeout:** Supported tasks can be cancelled; deadlines and timeout outcomes are visible.
- **PR-009 Verification:** Workflow results include verification status and test evidence when checks are run.
- **PR-010 Tool governance:** Tool/MCP execution is allowlisted, validated, bounded, permissioned, and audited.
- **PR-011 Recovery:** Worker errors, retries, duplicate deliveries, and restarts do not silently corrupt lifecycle state.
- **PR-012 Observability:** Logs and metrics correlate API requests, tasks, attempts, workflow stages, and tool calls without leaking secrets.
- **PR-013 Performance:** The project measures API latency, UI responsiveness, queue wait, and task execution separately.
- **PR-014 CLI parity:** CLI supports core task submission, status, event/progress viewing, cancellation, and approval actions as authorized.
- **PR-015 Usable UI states:** Dashboard includes loading, empty, success, error, reconnecting, approval-needed, and cancelled states.

## Non-goals for the first foundation milestone
- Unrestricted autonomous shell or filesystem access.
- Automatically merging or deploying code without explicit policy and approval.
- Building every agent adapter or MCP integration at once.
- Premature microservices or distributed infrastructure without measured need.
- Implementing advanced RAG/vector search before core task lifecycle and execution are reliable.
- Promising exactly-once execution or fixed LLM response times.
- Optimizing based on intuition without reproducible measurements.

## Performance budgets
Initial targets to benchmark, not claims of achieved performance:
- Lightweight/cached API reads: p95 < 100 ms.
- Database-backed reads: p95 < 200 ms.
- Task submission: p95 < 200 ms.
- INP ≤ 200 ms and LCP ≤ 2.5 s on representative test conditions.
- Aim for 60 FPS during representative UI interactions.
- Report API latency separately from model/tool latency and total task completion time.

## MVP acceptance criteria
1. A task can be submitted from CLI and dashboard and returns the same task identifier and status contract.
2. Submission does not wait for full graph execution.
3. Lifecycle transitions are unit-tested, including invalid transitions.
4. Task state survives API/worker restart under the chosen persistence design.
5. A client can reconnect to task progress and recover the current state.
6. Approval, failure, cancellation, and success states are distinguishable.
7. Tool access is denied by default unless explicitly allowed by policy.
8. Core API and UI paths have unit/integration tests.
9. Performance results include environment, load, percentiles, and test command.
10. Documentation distinguishes implemented features from planned features.

## Success metrics
- API p50/p95/p99 latency under defined load.
- Queue wait and task completion duration by workflow stage.
- Task success/failure/retry rates and verification pass rate.
- UI Core Web Vitals and interaction responsiveness.
- Recovery correctness after worker interruption.
- Percentage of consequential tool actions governed by policy and approval.
- Reproducibility of local setup and tests.

## Constraints and open decisions
- Preserve the current repository and agent configuration; reconcile before moving files.
- Choose and document package managers and supported runtime versions during the foundation milestone.
- Select a durable queue/dispatch design and recovery guarantees before implementing workers.
- Define authentication, tenancy, data retention, deployment, and sandbox policy before production use.

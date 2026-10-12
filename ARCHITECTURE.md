# DevFlow AI Architecture

**Status:** Owner-approved MVP direction; implementation details remain subject to repository inspection and testing.

## 1. Product and architecture goals

DevFlow AI coordinates AI coding agents through controlled workflows, shared task context, tool integrations, human approval, and automated verification.

The MVP includes:
- A web dashboard built with Next.js App Router, React, TypeScript, Tailwind CSS, and shadcn/ui.
- A Python API built with FastAPI and Pydantic.
- LangGraph for agent workflow orchestration.
- A Python CLI that uses the same HTTP API as the dashboard.
- PostgreSQL for durable task, workflow, and audit data.
- Redis only where justified for queue coordination, caching, rate limiting, or ephemeral coordination.
- A background worker for long-running workflow execution.
- Server-Sent Events (SSE) for one-way task-progress updates.

Primary quality attributes: low request latency, responsive UI, recoverability, security, observable behavior, and testability.

## 2. Architectural principles

1. **Fast request path:** HTTP handlers validate, persist/enqueue, and respond. They do not wait for an entire agent workflow.
2. **Asynchronous execution:** Long-running LLM calls, tool execution, retries, and verification run in a worker.
3. **One task domain:** The web UI and CLI use the same API contracts and lifecycle rules.
4. **Durable state:** Persist task transitions and workflow checkpoints needed for recovery. Do not treat in-memory state or Redis alone as the source of truth for durable task history.
5. **Explicit trust boundaries:** Agent output is untrusted input. Tools require allowlists, validated arguments, scoped permissions, and audit records.
6. **Human control:** Consequential actions pause for approval; cancellation and timeout are explicit states/operations.
7. **Measure before optimizing:** Establish latency, rendering, and load-test baselines before claiming performance.
8. **Incremental delivery:** Implement and test task lifecycle before adding broad agent integrations, RAG, or multi-agent collaboration.

## 3. Proposed repository layout

Reconcile this proposal with the actual tree before moving existing files. Do not delete or bulk-rewrite current agent configuration, skills, or project-specific instructions.

```text
devflow-ai/
├── apps/
│   ├── web/                 # Next.js dashboard and shadcn/ui
│   └── cli/                 # Python CLI; HTTP client for the API
├── services/
│   ├── api/                 # FastAPI application and API schemas
│   └── worker/              # Background job runner and LangGraph entrypoint
├── libs/
│   └── core/                # Task domain, lifecycle, policy interfaces
├── packages/
│   └── shared-types/        # OpenAPI-generated or language-neutral contracts
├── tests/
│   ├── unit/
│   ├── integration/
│   └── performance/
├── docs/
├── .agent-state/
└── project source-of-truth documents
```

This is a target layout, not a claim that these directories already exist. Avoid creating empty abstractions without a concrete use. Python code should not be imported directly by the TypeScript application; generate TypeScript contracts from OpenAPI or maintain a language-neutral schema.

## 4. Logical components

### Web dashboard
- Next.js App Router and TypeScript.
- shadcn/ui components styled through the existing design tokens.
- Server Components for static/initial content where appropriate; Client Components for interactive state.
- TanStack Query or an equivalent query/cache layer if it materially simplifies server-state synchronization.
- SSE client for task progress; reconnect and fetch the current task snapshot after reconnect.
- Avoid polling at high frequency when a stream is available.

### CLI
- Python CLI (Typer is the default candidate) using an HTTP client such as HTTPX.
- Uses the same authentication, API contracts, task lifecycle, and error semantics as the dashboard.
- Does not independently execute business workflows or bypass server policy.

### FastAPI service
- Pydantic request/response schemas and explicit versioned API contracts.
- Async endpoints for asynchronous I/O; do not call blocking operations directly from async handlers.
- Task submission creates a durable task and reliably dispatches it to the worker.
- Returns `202 Accepted` with a task identifier after successful acceptance.
- Exposes task reads, cancellation where supported, approval decisions, and an SSE event stream.
- Enforces authentication, authorization, validation, rate limits, and request-size limits.

### Task domain and persistence
- PostgreSQL is the durable source of truth for tasks, status transitions, user/tenant ownership where applicable, approvals, and audit events.
- Use transactions for task creation and lifecycle changes.
- Design queue dispatch to avoid losing a task between database commit and enqueue (for example, a transactional outbox or a proven durable job mechanism).
- Add indexes based on measured query patterns.
- Use connection pooling and bounded query timeouts.

### Worker and LangGraph
- A separately managed worker consumes accepted tasks and invokes LangGraph.
- LangGraph state is typed, bounded, and explicit; checkpoints enable supported pause/resume and recovery behavior.
- Keep planning, execution, verification, and reporting as explicit stages.
- Add bounded retries, deadlines, cancellation checks, idempotency, and failure handling.
- Limit concurrent jobs and tool calls; do not create unbounded parallelism.
- Worker delivery may be at-least-once. Handlers must be idempotent; do not promise exactly-once execution without a proven mechanism.

### Redis
Use only for a demonstrated need: ephemeral coordination, cache, rate limiting, or queue technology. Do not store the only copy of durable task/audit state in Redis. Choose one durable job-dispatch strategy and document its recovery guarantees before implementation.

### Tool gateway and MCP
- Central policy boundary for local tools and MCP servers.
- Explicit tool allowlist, schemas, authorization, timeouts, output-size limits, and audit events.
- Treat tool output, retrieved documents, and model output as untrusted.
- Require approval for consequential operations and isolate shell/filesystem execution in a restricted environment.
- Never expose arbitrary host shell access to an agent by default.

### Context and retrieval
RAG/vector search is a later milestone. First define source provenance, access filtering, freshness, deletion behavior, and evaluation criteria. Retrieval results are context, not instructions or authorization.

## 5. Task lifecycle

Initial proposed states:

- `queued`: accepted and awaiting worker execution.
- `running`: worker is executing the task.
- `needs_approval`: execution is paused pending a human decision.
- `completed`: task reached a verified terminal success state.
- `failed`: task ended with an unrecoverable error.
- `cancelled`: task was cancelled and the worker acknowledged cancellation.
- `blocked`: task cannot proceed because a required dependency or policy condition is unresolved.

Initial transition model (enforce centrally in domain logic, not only in UI):

```text
queued -> running | cancelled | blocked
running -> needs_approval | completed | failed | cancelled | blocked
needs_approval -> running | cancelled | blocked
blocked -> queued | cancelled
completed, failed, cancelled -> terminal
```

A retry should be represented deliberately: either create a new task/attempt or define a controlled transition with attempt history. Never silently reopen a terminal task. Every transition records actor, timestamp, prior state, next state, and reason where applicable.

## 6. API and event flow

1. Client sends `POST /api/v1/tasks`.
2. API authenticates and validates the request, creates a task and durable dispatch record, then returns `202 Accepted` with `task_id`.
3. Worker claims the job and changes `queued` to `running`.
4. Worker emits persisted task events as stages change.
5. Client consumes `GET /api/v1/tasks/{task_id}/events` via SSE and can fetch `GET /api/v1/tasks/{task_id}` for the authoritative snapshot.
6. Approval-required tasks pause in `needs_approval`; a user decision resumes or cancels according to policy.
7. Worker records final result, verification outcome, and audit events.

SSE is server-to-client only. Use ordinary authenticated API requests for task creation, cancellation, and approval decisions. Define event IDs and reconnect behavior; do not rely on an in-memory event stream as the only record of important state changes.

## 7. Performance strategy

Performance targets are initial budgets, not guarantees. Benchmark in a defined environment and revise with measured evidence.

| Measure | Initial target |
|---|---:|
| Lightweight/cached API reads, p95 | < 100 ms |
| Database-backed API reads, p95 | < 200 ms |
| Task submission API, p95 | < 200 ms |
| Core Web Vitals: INP | ≤ 200 ms |
| Core Web Vitals: LCP | ≤ 2.5 s |
| Animation | Aim for 60 FPS on representative hardware |

Measure API server time separately from LLM/tool time and end-to-end task completion. Include warm/cold behavior and realistic concurrency in tests.

### Backend
- Keep request handlers short and use async I/O correctly.
- Do not run LLM calls or agent graphs inline during submission.
- Use bounded worker concurrency, timeouts, connection pools, and query limits.
- Avoid N+1 queries and repeated serialization of large payloads.
- Cache only data with a clear invalidation policy.
- Add tracing/timing around database, queue, LLM, tool, and verification stages.
- Stream progress rather than making clients wait for the final result.

### Frontend
- Keep Client Components focused; prefer Server Components for static content.
- Lazy-load heavy editors, graph visualizations, and advanced views.
- Minimize unnecessary rerenders and large client bundles.
- Batch/throttle progress events before updating expensive UI.
- Use skeletons and immediate feedback; use optimistic updates only where rollback is safe.
- Prefer transform/opacity animations; respect `prefers-reduced-motion`.
- Avoid excessive backdrop blur, giant animated surfaces, and expensive effects in high-frequency views.

## 8. Reliability and observability
- Structured logs with request ID, task ID, worker attempt, and stage.
- Metrics for API latency, queue wait, job duration, failures, retries, DB pool saturation, SSE disconnects, and tool latency.
- Trace each task across API, queue, worker, graph, tools, and verification.
- Explicit timeouts, cancellation, retry limits, dead-letter/recovery policy, and shutdown handling.
- Health/readiness checks should distinguish API health from worker/queue readiness.
- Never log secrets, credentials, raw sensitive prompts, or unrestricted tool output by default.

## 9. Security boundaries
- Authenticate every non-public endpoint; authorize access to each task and event stream.
- Validate all user input and tool arguments.
- Store secrets outside source control; redact logs.
- Apply least privilege to database credentials, tools, and MCP servers.
- Use sandboxed execution for shell and repository changes, with filesystem/network restrictions.
- Require approval for high-impact actions; record the approver and decision.
- Apply limits for payloads, execution time, output size, concurrency, and spending where provider support permits.
- See `docs/SECURITY.md`.

## 10. Testing and release gates
- Unit tests for task transitions, idempotency, policy decisions, and event serialization.
- API tests for validation, authorization, status codes, error contracts, and SSE reconnect behavior.
- Worker/graph integration tests for success, failure, timeout, retry, cancellation, and approval pause/resume.
- Frontend tests for core interactions, keyboard access, reduced motion, loading/error/empty states.
- Performance tests for API p50/p95/p99, queue wait, concurrent tasks, and frontend Core Web Vitals.
- Do not claim targets are met until test output and environment are recorded.

## 11. Delivery sequence
1. Repository audit and source-of-truth reconciliation.
2. Developer foundation and task-domain lifecycle with tests.
3. FastAPI task API, CLI, and dashboard against the same contract.
4. Durable background execution and minimal LangGraph workflow.
5. SSE progress, checkpointing, approval pause/resume, cancellation, recovery.
6. Tool gateway and MCP with policy enforcement.
7. Retrieval/context and evaluation.
8. Performance hardening and deployment.

## 12. Decisions to record before production
- Python and Node package managers/versions.
- Durable job-dispatch implementation and outbox/recovery strategy.
- Authentication and tenancy model.
- Deployment topology and supported sandbox.
- LLM providers, budgets, and model-routing policy.
- Retention/privacy policy for prompts, logs, checkpoints, and repository contents.

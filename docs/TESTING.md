# Testing Strategy

## Principles
- Test domain invariants independently from infrastructure.
- Prefer deterministic tests with fake model/tool adapters.
- Run the relevant checks for every change and report exact commands/results.
- Performance targets remain unverified until benchmark output is recorded with environment and load details.

## Unit tests
- Task lifecycle: valid and invalid transitions, terminal states, blocked tasks, cancellation, approval, retry/attempt semantics.
- Domain and policy: authorization decisions, tool allowlists, argument validation, timeout mapping, output limits.
- Event contracts: serialization, event IDs, state snapshot consistency.
- Frontend utilities: API error handling, state mapping, progress batching.

## API integration tests
- Task submission returns `202` and a stable task identifier after durable acceptance.
- Invalid payloads and unauthorized requests are rejected with stable error contracts.
- Task access and SSE streams enforce ownership.
- Queue/dispatch failure does not leave a falsely accepted task without recoverable dispatch intent.
- Cancellation distinguishes request acceptance from confirmed cancellation.
- Approval is accepted only when the task is awaiting the decision.
- SSE reconnects can recover the current task state.

## Worker and LangGraph integration tests
- Successful completion and verification.
- Tool/model failure, timeout, retry exhaustion, cancellation, and blocked state.
- Approval pause and resume.
- Duplicate delivery/idempotency.
- Worker restart and checkpoint/recovery behavior.
- Bounded concurrency and graceful shutdown.
- Use fake adapters in normal CI; live-provider tests should be opt-in and separately labeled.

## Frontend tests
- Task creation and detail view.
- Loading, empty, success, error, blocked, approval, cancelled, and reconnecting states.
- Keyboard navigation, focus handling, accessible names, responsive layout, reduced motion.
- SSE reconnect and state reconciliation.
- Avoid tests that depend on arbitrary fixed delays when event/state assertions are possible.

## Performance tests
Record OS/runtime versions, hardware, dependency versions, dataset, concurrency, duration, warm/cold conditions, and exact command.

Measure separately:
- API server latency p50/p95/p99.
- Database-backed read latency.
- Task submission latency.
- Queue wait time.
- LLM and tool latency.
- End-to-end task duration.
- Worker throughput and failure rate.
- Database pool saturation and event-loop blocking.
- Frontend LCP, INP, bundle size, and representative animation/frame behavior.

Initial budgets:
- Lightweight/cached reads p95 < 100 ms.
- Database-backed reads p95 < 200 ms.
- Task submission p95 < 200 ms.
- INP ≤ 200 ms; LCP ≤ 2.5 s.
- Aim for 60 FPS on representative hardware.

Do not combine LLM wait time with API server latency when assessing the submission endpoint.

## Suggested quality gates
Choose tools after inspecting current conventions. Typical candidates:
- Python: pytest, Ruff, mypy or Pyright.
- TypeScript: ESLint, TypeScript compiler, Vitest or Jest, Playwright for browser flows.
- API: FastAPI TestClient/HTTPX.
- Performance: Locust, k6, or a small repeatable HTTP benchmark.
Do not install every candidate automatically. Select a minimal set and document the reason.

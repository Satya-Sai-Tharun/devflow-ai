# Testing Strategy

## Principles
- Test domain invariants independently from infrastructure.
- Prefer deterministic tests with fake model/tool adapters.
- Run the relevant checks for every change and report exact commands/results.
- Performance targets remain unverified until benchmark output is recorded with environment and load details.

The Python project and test suite live in `backend/`. From that directory, install with `uv sync --locked`, run unit tests with `uv run pytest`, and run the isolated PostgreSQL integration test with `uv run pytest -m integration` only after setting `DEVFLOW_DATABASE_URL` to a dedicated local `_test` database. The integration test rejects non-local, production, wrong-suffix, and non-empty databases; it does not drop or recreate databases. Root Docker Compose commands and the explicit migration step are documented in [`../README.md`](../README.md).

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

## Quality gates and tooling

**Tooling decided by the project owner on 2026-10-13** ([`decisions/0007`](decisions/0007-runtime-and-package-managers.md)). This list is binding; do not introduce a second tool for the same purpose without recording the reason.

| Concern | Tool | Notes |
|---|---|---|
| Python test runner | **pytest** | Deterministic; the default suite makes no network calls |
| Python lint + format | **Ruff** | One tool for both, configured once |
| Python type checking | **Pyright** | **Not** mypy — one type checker only, to avoid conflicting diagnostics |
| TypeScript lint | **ESLint** | Shared config across the monorepo |
| TypeScript type checking | **`tsc --noEmit`** | Strict mode |
| Frontend unit/component tests | **Vitest** | **Not** Jest |
| Browser end-to-end tests | **Playwright** | Only where a browser flow genuinely needs it |
| API testing | FastAPI TestClient / HTTPX | In-process where possible |
| Performance | Not yet chosen | Deferred until Milestone 9; see [`PERFORMANCE.md`](PERFORMANCE.md). Do not adopt a load-testing tool speculatively |

**Do not install every candidate automatically.** Install only the tools above, and record in `CODE_STYLE.md` the commands they run so local and CI invocations match.

**Deferred, deliberately:** the performance/load-testing tool is the only open item in this list. It is a Milestone 9 decision, because a load tool chosen without a measured baseline is a guess.

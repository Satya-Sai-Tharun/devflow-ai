# DevFlow AI

DevFlow AI is a controlled agentic software-engineering platform for coordinating coding agents through task workflows, repository context, policy-governed tools, human approval, and automated verification.

## MVP direction
- **Web dashboard:** Next.js App Router, React, TypeScript, Tailwind CSS, shadcn/ui.
- **API:** Python + FastAPI + Pydantic.
- **Orchestration:** LangGraph in a separate background worker.
- **CLI:** Python client using the same HTTP API.
- **Durable state:** PostgreSQL.
- **Redis:** only for justified queue coordination, caching, rate limiting, or ephemeral coordination.
- **Progress:** Server-Sent Events (SSE).

The API should accept a task, persist task/dispatch intent, and return `202 Accepted` with a task ID. The background worker runs the longer agent workflow. Do not hold task-submission requests open while waiting for LLMs or tools.

## Current implementation status
Milestone 1 Task 1 adds a minimal FastAPI service, PostgreSQL connectivity, an empty Alembic baseline, and automated checks. Authentication, workspace authorization, workflow execution, frontend, and CI remain unimplemented. No performance target has been measured. Verified repository facts are recorded in [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) § 2 and [`.agent-state/CURRENT.md`](.agent-state/CURRENT.md).

## Source-of-truth documents
Start with [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) — the master briefing, verified repository state, and navigation hub. [`docs/DOCUMENTATION_INDEX.md`](docs/DOCUMENTATION_INDEX.md) is authoritative for *which document governs which subject* and for the change-management protocol.

Product and behaviour:
- [`PRD.md`](PRD.md) — product scope, requirements, non-goals, acceptance criteria.
- [`SPEC.md`](SPEC.md) — task lifecycle, transitions, and initial API contract.
- [`docs/API_CONTRACTS.md`](docs/API_CONTRACTS.md) — HTTP conventions, error model, endpoints, SSE protocol.

Architecture and runtime:
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — component boundaries, data flow, performance, reliability.
- [`docs/AGENT_RUNTIME.md`](docs/AGENT_RUNTIME.md) — agent adapters, workflow stages, execution bounds, failure handling.
- [`docs/DATABASE.md`](docs/DATABASE.md) — data model, migrations, indexing, retention.

Security and quality:
- [`docs/SECURITY.md`](docs/SECURITY.md) — security baseline and review checklist.
- [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md) — assets, trust boundaries, STRIDE and AI-specific threats, security requirements, test plan.
- [`docs/TESTING.md`](docs/TESTING.md) — test strategy.
- [`docs/PERFORMANCE.md`](docs/PERFORMANCE.md) — authoritative performance budgets and benchmark protocol.
- [`docs/REQUIREMENTS_TRACEABILITY.md`](docs/REQUIREMENTS_TRACEABILITY.md) — requirement → component → test → evidence mapping.

Process and state:
- [`AGENTS.md`](AGENTS.md) — coding-agent workflow and safety rules; the single universal entry point for all agents, including a cross-agent support matrix.
- [`GEMINI.md`](GEMINI.md) — Gemini CLI adapter (delegates to `AGENTS.md`).
- [`CODE_STYLE.md`](CODE_STYLE.md) — engineering conventions.
- [`Design-system.md`](Design-system.md) — UI tokens, shadcn/ui, accessibility and motion guidance.
- [`PLAN.md`](PLAN.md) — milestone sequence and exit criteria.
- [`docs/decisions/`](docs/decisions/README.md) - architecture decision records; 8 accepted, 3 proposed.
- [`.agent-state/CURRENT.md`](.agent-state/CURRENT.md) — verified current state.
- [`.agent-state/ACTIVE-TASK.md`](.agent-state/ACTIVE-TASK.md) — active task and acceptance criteria.

## Development

Requirements: Windows PowerShell, Python 3.12 (managed by `uv`), and Docker Desktop for PostgreSQL integration checks. Copy `.env.example` to `.env`, replace its local placeholders, then run Compose.

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
uv sync --locked
docker compose up -d postgres
uv run alembic upgrade head
uv run pytest
uv run ruff check .
uv run ruff format --check .
uv run pyright
uv run devflow-api
```

The API listens on `127.0.0.1:8000`. `/healthz` checks process liveness; `/readyz` also requires PostgreSQL and the current migration head. Migrations are explicit and are not run at startup. The integration test requires a disposable `<POSTGRES_DB>_test` database; create it once with `docker compose exec postgres sh -c 'createdb -U "$POSTGRES_USER" "${POSTGRES_DB}_test"'`, then run `uv run pytest -m integration`.

Run `powershell -File tools/validate-docs.ps1` after Markdown changes. It validates documentation consistency, not application behavior; see [`docs/DOCUMENTATION_INDEX.md`](docs/DOCUMENTATION_INDEX.md) § 7.
## Engineering priorities
1. Reliable task domain and explicit lifecycle.
2. Low-latency task API and shared API contract.
3. CLI and dashboard core flows.
4. Durable worker execution and LangGraph.
5. SSE, approval, cancellation, and recovery.
6. Governed tools/MCP.
7. Retrieval, evaluation, performance and security hardening.

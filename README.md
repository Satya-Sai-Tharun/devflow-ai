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
The backend contains the initial FastAPI service, PostgreSQL connectivity, an empty Alembic baseline, and automated checks. Docker Compose starts PostgreSQL and the backend; the database migration remains an explicit step. The `frontend/` directory is reserved for the future Next.js application and has no application code or development server. Authentication, workspace authorization, workflow execution, and CI remain unimplemented. No performance target has been measured. Verified repository facts are recorded in [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) § 2 and [`.agent-state/CURRENT.md`](.agent-state/CURRENT.md).

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
- [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) — future server deployment requirements; no production deployment is configured.
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

## Local development

Docker Compose is the primary local startup interface. Install Docker Desktop, then create the local environment file once:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose up --build -d
docker compose ps
docker compose run --rm backend alembic upgrade head
docker compose logs -f backend
# Run after exiting the log view, when you want to stop the services:
docker compose down
```

`docker compose down` keeps the `devflow-postgres` volume. Do not add `-v` when stopping local services. PostgreSQL and the API are published on localhost only; the backend reaches PostgreSQL by the Compose service name `postgres`. Apply the migration before expecting `/readyz` to return `200`. `/healthz` checks process liveness, `/readyz` checks database connectivity and the current migration head, and `/docs` serves OpenAPI documentation.

`start-dev.bat` can start Compose from File Explorer and creates `.env` from development-only placeholders when missing. It does not apply migrations; run the migration command above in PowerShell. To run backend checks without a container, use Python 3.12 and `uv` from `backend/`:

```powershell
Set-Location backend
uv sync --locked
uv run pytest
uv run ruff check .
uv run ruff format --check .
uv run pyright
uv run devflow-api
```

The PostgreSQL integration test only accepts a local, non-production database named with the `_test` suffix and refuses a non-empty database. It never drops or recreates databases. Run `uv run pytest -m integration` only after providing a dedicated disposable test database as `DEVFLOW_DATABASE_URL`.

Run `powershell -File tools/validate-docs.ps1` after Markdown changes. It validates documentation consistency, not application behavior; see [`docs/DOCUMENTATION_INDEX.md`](docs/DOCUMENTATION_INDEX.md) § 7.

## Repository layout

- `backend/` — FastAPI package, Python project and lockfile, tests, Alembic config/migrations, and backend image.
- `frontend/` — reserved for the future Next.js App Router and pnpm application; it is not scaffolded.
- `docs/` — shared specifications, decisions, testing, security, and deployment guidance.
- `compose.yaml` — root local development services; `.env.example` — root development placeholders.

For future Linux/VPS deployment requirements and current limitations, see [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md). The current Compose setup is for local development and is not production-ready.
## Engineering priorities
1. Reliable task domain and explicit lifecycle.
2. Low-latency task API and shared API contract.
3. CLI and dashboard core flows.
4. Durable worker execution and LangGraph.
5. SSE, approval, cancellation, and recovery.
6. Governed tools/MCP.
7. Retrieval, evaluation, performance and security hardening.

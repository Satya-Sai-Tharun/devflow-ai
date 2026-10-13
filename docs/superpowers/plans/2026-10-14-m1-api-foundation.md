# Milestone 1 API Foundation Implementation Plan

**Goal:** Add a minimal, runnable FastAPI service with typed configuration, PostgreSQL readiness, explicit migrations, and repeatable Windows development checks.

**Architecture:** Keep the Python API under services/api as ARCHITECTURE.md specifies, with a root uv project and lockfile for the single monorepo. Build one async SQLAlchemy engine per process, serve DB-independent liveness, and make readiness fail closed unless PostgreSQL is reachable and Alembic is at its sole expected head.

**Tech Stack:** Python 3.12, uv, FastAPI, Pydantic Settings, SQLAlchemy 2.x async, asyncpg, Alembic, pytest, Ruff, Pyright, Docker Compose.

**Spec:** User-approved Milestone 1 task in the conversation; authoritative details in ARCHITECTURE.md, PROJECT_CONTEXT.md, docs/API_CONTRACTS.md §9.4, docs/DATABASE.md, accepted ADRs 0003/0004/0007/0008/0011.

## Global Constraints

- Python 3.12; uv is the Python package manager.
- API package path: services/api/ (ARCHITECTURE.md).
- App config uses the canonical DEVFLOW_ names; PostgreSQL infrastructure uses POSTGRES_ names.
- Database URL is postgresql+asyncpg; async sessions are scoped and closed; migrations are explicit and never run at startup.
- /healthz is public and independent of PostgreSQL; /readyz is public and requires DB connectivity plus migration head.
- Health responses disclose only status; no authentication, workspace authorization, domain schema, workers, Redis, or frontend.
- No real secrets in tracked files. The implementation handoff remained uncommitted until the owner authorized this PR integration.

## Task 1: Python project and configuration

**Files:** pyproject.toml, uv.lock, .python-version, .env.example, services/api/devflow_api/config.py, services/api/devflow_api/cli.py, tests/test_config.py.

- Pin Python 3.12 in .python-version and pyproject; add only runtime and approved quality/test dependencies.
- Create typed settings using the canonical DEVFLOW_ prefix; require a valid async PostgreSQL DSN and keep local-only values as examples.
- Add tests for missing/invalid DSN, valid settings, and allowed environment values. Run the new tests to observe expected failures before implementing settings.
- Generate uv.lock with uv; never hand-edit it.

## Task 2: Liveness, readiness, and resource lifecycle

**Files:** services/api/devflow_api/main.py, services/api/devflow_api/health.py, services/api/devflow_api/database.py, tests/test_health.py, tests/test_database.py.

- Test /healthz without any database connection.
- Test readiness success at the migration head; connection failure, timeout, missing/behind/unknown migration state, and state-query failure all return generic 503 degraded output.
- Build a single async engine in FastAPI lifespan and dispose it on shutdown; do not fail startup only because PostgreSQL is unavailable.
- Bound connection acquisition and probe queries; keep diagnostics out of response bodies and do not log secrets.
- Write the tests first and verify each fails for the missing behavior before implementing it.

## Task 3: Explicit Alembic baseline and local PostgreSQL

**Files:** alembic.ini, services/api/migrations/env.py, services/api/migrations/versions/0001_initial.py, compose.yaml, tests/integration/test_migrations.py.

- Add an empty, explicit baseline revision; Alembic reads the validated DEVFLOW_DATABASE_URL and does not run from API startup.
- Compose only PostgreSQL, bind its published port to loopback, require environment-based credentials, use a persistent volume, and add pg_isready health checks.
- Integration test migrations from a fresh dedicated test database and reapplication at head; refuse unsafe non-test database names.
- Verify readiness before migration is 503 and after migration is 200 against PostgreSQL when Docker is available.

## Task 4: Developer commands and state handoff

**Files:** README.md (only the developer setup section if needed), .agent-state/CURRENT.md, .agent-state/ACTIVE-TASK.md.

- Document PowerShell commands for uv sync --locked, Compose PostgreSQL, Alembic, pytest, Ruff, Pyright, and API startup.
- Update only stale state fields and append a concise task handoff; preserve prior task history and do not claim Milestone 1 complete.
- Run unit/integration tests as available, Ruff lint/format, Pyright, documentation validation if docs changed, git diff --check, and a final read-only review of the complete diff.

## Review Focus

1. DB outage or timeout must not break liveness or leak DSN/driver details; cover with endpoint tests.
2. Empty, behind, unknown, or unreadable Alembic state must never report ready; cover each branch.
3. A missing Alembic version table must produce degraded readiness until explicitly migrated; cover before/after against fresh PostgreSQL.
4. API startup must not migrate or require a working DB; verify lifespan and test startup with DB down.
5. Integration tests must not touch development or production databases; require an explicitly named disposable *_test database and assert this before migration.

## Verification Commands

```powershell
uv sync --locked
docker compose up -d postgres
uv run alembic upgrade head
uv run pytest
uv run ruff check .
uv run ruff format --check .
uv run pyright
uv run devflow-api
```

PostgreSQL-specific commands and any skipped checks will be reported with their actual results. No Git staging or commit step is permitted by the task instructions.

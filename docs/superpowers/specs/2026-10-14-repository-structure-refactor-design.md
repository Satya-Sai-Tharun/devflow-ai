# Repository Structure Refactor Design

## Goal and scope

Move the existing FastAPI service, migrations, tests, and Python project configuration into a self-contained `backend/` project. Keep Compose and shared documentation at the repository root, reserve `frontend/` with a README, and provide a reproducible local Docker workflow without adding product features.

The change preserves the FastAPI routes, PostgreSQL 17, Python 3.12, `uv`, Alembic revision history, and the integration test's local disposable-database checks. It does not add a frontend app, worker, Redis, authentication, or production deployment configuration.

## Structure and dependency management

- Move `services/api/devflow_api/` to `backend/devflow_api/`.
- Move `services/api/migrations/` to `backend/migrations/`, retaining `0001_initial.py` and its revision identifiers.
- Move root `tests/` to `backend/tests/`; update pytest paths and the migration test's Alembic config path.
- Move `pyproject.toml`, `uv.lock`, `.python-version`, and `alembic.ini` into `backend/`. Keep `uv` as the sole Python project and lockfile owner; regenerate the lock only if the project metadata requires it.
- Resolve Alembic's config path relative to the installed package and keep migrations explicit. Application startup must not run migrations.

## Local containers

Keep root `compose.yaml`, the localhost-only PostgreSQL port binding, and the existing named volume. Add one backend image built from `backend/Dockerfile`, with its app bound to `0.0.0.0:8000` inside the container and host port bound to localhost. Compose passes the root `.env` settings and supplies the in-network PostgreSQL DSN using service hostname `postgres`.

The backend waits for PostgreSQL health. A documented one-shot `docker compose run --rm backend alembic upgrade head` applies migrations; the API container never migrates automatically. The existing readiness route continues to report degraded until the current Alembic head is present.

Add `.dockerignore` for secrets, virtual environments, caches, and repository-only artifacts. Add a root `start-dev.bat` only if it can check Docker/Compose, run Compose from its own directory, and keep errors visible when double-clicked. Shutdown remains the non-destructive `docker compose down`; do not remove volumes.

## Configuration and documentation

Keep `.env.example` at the root with development-only placeholders and set container-reachable database configuration. Document copying it to `.env`, startup, explicit migration, status/log commands, endpoints, tests/quality commands, and shutdown. Document the backend/frontend boundary, shared docs and root Compose ownership, and future Linux/VPS deployment requirements without claiming production readiness.

Update current architecture and repository-state references to `backend/`; preserve old paths only when clearly historical. Record this task, scope, branch, decisions, and final evidence in `.agent-state/ACTIVE-TASK.md` and `.agent-state/CURRENT.md`. Do not weaken the universal agent rules or Git boundaries.

## Safety and verification

No existing database, test database, or Compose volume is reset or deleted. The migration integration test remains restricted to localhost, non-production URLs with a `_test` database name and an empty schema. Container migration verification uses a separately named disposable test database and never targets the default local database or any production host.

Verify the relocated locked install, Ruff, Pyright, pytest, documentation validator, `git diff --check`, Compose configuration, Docker build, container health, migration upgrade/repeat, `/healthz`, `/readyz`, and `/docs`. Report unavailable Docker or database checks as unverified.

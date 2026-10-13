# Repository Structure Refactor Implementation Plan

> **For agentic workers:** Execute inline as the primary writer. No commits are authorized. Steps use checkbox syntax for tracking.

**Goal:** Relocate the existing API to a self-contained `backend/`, establish root Compose startup, and document the reserved frontend boundary.

**Architecture:** Keep shared docs, `.env.example`, and `compose.yaml` at the root. Backend owns its `uv` project, tests, Dockerfile, Alembic config, and migrations. Compose starts PostgreSQL and one API service; migrations run only through an explicit one-shot command.

**Tech Stack:** Python 3.12, `uv`, FastAPI, Pydantic Settings, async SQLAlchemy, asyncpg, PostgreSQL 17, Alembic, Docker Compose.

**Spec:** `docs/superpowers/specs/2026-10-14-repository-structure-refactor-design.md`

## Global Constraints

- Preserve `/healthz`, `/readyz`, and `/docs` contracts.
- Preserve Alembic revision `0001_initial` and its revision identifiers.
- Never run migrations from backend application startup.
- Never delete, recreate, or reset a database or Docker volume.
- PostgreSQL host binding stays `127.0.0.1`; local database credentials remain development-only.
- Keep `.env.example` and `compose.yaml` at repository root.
- Do not add a frontend implementation, Redis, worker, authentication, cloud resources, or production secrets.
- Do not commit, push, merge, or deploy.

## Review Focus

- Relocated Alembic paths must work from both `backend/` and the container working directory; verify migration upgrade and repeat.
- Integration tests must still reject non-local, production, non-`_test`, and non-empty databases; retain and run the guard test suite without pointing it at any non-test DSN.
- Compose must pass a container-reachable PostgreSQL URL and must not migrate automatically; verify service config and explicit migration.
- Windows launcher paths and failures must remain visible under double-click invocation; verify command handling and do not use destructive Compose flags.
- Docker build context and ignore rules must exclude `.env`, `.venv`, caches, and credentials; inspect the final image build inputs and `.dockerignore`.

---

### Task 1: Relocate the Python project

**Files:** Move `services/api/devflow_api/` to `backend/devflow_api/`, `services/api/migrations/` to `backend/migrations/`, root `tests/` to `backend/tests/`, and root `pyproject.toml`, `uv.lock`, `.python-version`, `alembic.ini` to `backend/`. Modify moved project paths and database config resolution.

**Interfaces:** Keep package name `devflow_api`, CLI command `devflow-api`, endpoint behavior, and migration revision IDs unchanged. Pytest, Ruff, Pyright, Alembic, and `uv` commands run from `backend/`.

- [x] Move files with Git-aware rename semantics; inspect the initial migration's `revision` and `down_revision` before/after.
- [x] Update hatch wheel package path, pytest paths, Ruff `src`, Pyright include/extraPaths, and Alembic `script_location` for the backend root.
- [x] Resolve `ALEMBIC_CONFIG` from the package's parent `backend/` directory; verify the existing migration test path still resolves `backend/alembic.ini` and retain all database safety checks.
- [x] Run `uv sync --locked`, Ruff lint/format, Pyright, and unit pytest from `backend/`.
- [x] Run guarded migration integration tests only against a dedicated localhost `_test` database; no existing database or volume was modified.

### Task 2: Add container and local startup

**Files:** Create `backend/Dockerfile`, root `.dockerignore`, update root `compose.yaml` and `.env.example`; optionally create `start-dev.bat` if it can report prerequisite/startup errors and pause on failure.

**Interfaces:** Compose services are `postgres` and `backend`. Backend listens on port 8000 in-container and localhost only on the host. Migration command is `docker compose run --rm backend alembic upgrade head`.

- [x] Create a backend image using the backend lockfile and project, without copying `.env` or credentials.
- [x] Add Compose backend build, environment, PostgreSQL health dependency, restart policy, localhost API port binding, and container health check; preserve the `devflow-postgres` volume and localhost database binding.
- [x] Keep database URL host `postgres` inside Compose. Ensure root `.env` values resolve; keep development-only placeholder password documented.
- [x] Ensure the backend command starts only the app; document migration as explicit and one-shot.
- [x] Implement root-relative launcher checking Docker and Compose, running `docker compose up --build -d`, reporting status, and pausing on errors; it never removes volumes or alters Git.
- [x] Validate Compose, build the image, start services, inspect health, run explicit migration against a dedicated test database, and verify endpoints/docs. Never run `down -v`.

### Task 3: Reconcile documentation and coordination

**Files:** Update `README.md`, `PROJECT_CONTEXT.md`, `ARCHITECTURE.md`, `PLAN.md`, `AGENTS.md` where setup instructions are needed, relevant `docs/` source-of-truth files (`DOCUMENTATION_INDEX.md`, `DATABASE.md`, `API_CONTRACTS.md`, `SECURITY.md`, `THREAT_MODEL.md`, `TESTING.md`, `REQUIREMENTS_TRACEABILITY.md`, `AGENT_RUNTIME.md`), `CLAUDE.md`, `.agent-state/CURRENT.md`, `.agent-state/ACTIVE-TASK.md`. Create `frontend/README.md`. Mark the existing M1 plan's former layout references historical rather than rewriting history.

**Interfaces:** Current docs consistently describe `backend/`, root Compose and shared docs, frontend as unscaffolded, explicit migrations, local commands, and future deployment limitations.

- [x] Update authoritative architecture and navigation/current-state claims before summaries; keep feature implementation status honest.
- [x] Document `.env` setup; Compose up/ps/logs/down; explicit migration; health, readiness, docs; backend quality commands; persistence; server deployment requirements and limitations.
- [x] Add `frontend/README.md` stating Next.js App Router and pnpm are intended, with no app or dev server present.
- [x] Update agent read-first/setup guidance without weakening branch, review, authorization, or single-agent rules.
- [x] Record task scope, branch, decisions, blockers, and verified evidence in current and active task state.
- [x] Search old paths and retain only historical references; `powershell -File tools/validate-docs.ps1` passed.

### Task 4: Full verification and handoff

**Files:** No scope expansion. Fix only task-related findings.

- [x] Run backend locked install, Ruff check/format, Pyright, unit and safe integration tests.
- [x] Run docs validator and `git diff --check`.
- [x] Validate Compose, build backend image, start stack, inspect health, run migrations against dedicated test DB, and verify `/healthz`, `/readyz`, `/docs`.
- [x] Verify database safety guard behavior and inspect remaining `services/api/` references, migration identity, secrets, tree, diff, and Git status.
- [x] Update handoff with actual commands/results, unverified checks, remaining risks, branch, and status. Leave uncommitted and unpushed.

# Active Task

**Task ID:** REPO-STRUCT-001
**Status:** Implementation and requested local verification complete; uncommitted on the feature branch, awaiting owner review/merge authorization.
**Branch/base:** `feature/repository-structure-refactor` from `dev` at `e8ca84c1e8a64c2e355cb34fe97240bc1c039a41`.
**Objective:** Move the existing API, migrations, tests, and Python project into `backend/`; add explicit-migration Docker Compose startup; reserve `frontend/`; and reconcile docs and agent state.
**Scope exclusions:** Frontend implementation, authentication, workspace authorization, task/workflow domain, worker, LangGraph, Redis, production credentials/resources, deployment, and CI.
**Design:** [`docs/superpowers/specs/2026-10-14-repository-structure-refactor-design.md`](../docs/superpowers/specs/2026-10-14-repository-structure-refactor-design.md).
**Implementation plan:** [`docs/superpowers/plans/2026-10-14-repository-structure-refactor.md`](../docs/superpowers/plans/2026-10-14-repository-structure-refactor.md).

## Decisions and safety constraints

- Keep the root `compose.yaml`, `.env.example`, shared documentation, and tools; put Python project configuration and tests in `backend/`.
- Preserve Alembic revision `0001_initial` and the integration test's local `_test`, production, and empty-database guards.
- Keep migration execution explicit with a one-shot Compose command. API startup does not migrate.
- Preserve the `devflow-postgres` volume and localhost-only PostgreSQL host binding. Never use `down -v`, reset databases, or operate on a production/non-test DSN.
- Use service DNS `postgres` inside the backend container; bind API host exposure to localhost.
- No ADR is needed: this implementation shape is explicitly approved in the owner request and does not change the accepted product/deployment security boundaries.
- Ruling: Keep the integration test's `parents[2] / "alembic.ini"` path unchanged; after moving it under `backend/tests/integration/`, that resolves to `backend/alembic.ini`. An exploratory change to `parents[1]` failed the integration test and was reverted. Cost if wrong: the integration test would fail before migration.
- No separate task/decision/blocker/handoff ledger exists in this checkout; this file and `.agent-state/CURRENT.md` are the coordination records.

## Acceptance and verification

- Preserve endpoint contracts and migration identifiers; backend package installs with `uv sync --locked` from `backend/`.
- Ruff, Pyright, pytest, documentation validator, `git diff --check`, Compose config, Docker build/startup, explicit migration on a dedicated test database, and HTTP checks for `/healthz`, `/readyz`, `/docs`.
- Final diff and searches must show no unintended stale paths, missing governance/migrations, secrets, generated artifacts, or database/volume deletion.
- Report unavailable checks honestly. No commit, push, merge, or deployment.

## Handoff

- Relocated API, tests, Alembic, and Python project files into `backend/`; preserved revision `0001_initial` / `down_revision = None`.
- `backend/`: `uv sync --locked` passed; `uv run --locked pytest -q -p no:cacheprovider` reported 15 passed; Ruff check/format passed; Pyright reported 0 errors/warnings/information. `uv run --locked alembic heads` reports `0001_initial (head)`.
- Integration test on dedicated local PostgreSQL 17 database: `uv run --locked pytest -m integration -q -p no:cacheprovider` reported 1 passed. The existing `parents[2]` test config path correctly resolves after the move. Separate negative checks confirmed non-local URLs and non-empty `_test` databases are refused; the non-empty database remained without `alembic_version`.
- `docker compose --env-file .env.example config --quiet` passed. Backend image build passed with the base image pinned by digest. An isolated project on localhost ports 55432/18000 reached healthy status; host checks returned `/healthz` 200, `/docs` 200, `/readyz` 503 before migration and 200 after explicit migration. Repeating `alembic upgrade head` succeeded.
- The normal host port 5432 was already occupied by `devflow-ai-postgres-1` from another worktree. Verification therefore used a separate Compose project and ports. The pre-existing container and `devflow-ai_devflow-postgres` volume were not modified. The isolated test volume `devflow-refactor-test_devflow-postgres` was retained; only its containers and empty network were stopped/removed without `-v`.
- The Windows launcher missing-Docker path was exercised and returned exit code 1 with a visible error and pause. The successful Compose startup path was verified directly, not by launching the batch file through File Explorer.
- `powershell -File tools/validate-docs.ps1` passed: 40 documents, 320 links, 4 Mermaid diagrams. `git diff --check` passed. Remaining `services/api/` references are historical records or the new relocation plan/spec.
- `graphify update .` could not update its stale local graph because the existing graph has 3,369 nodes and the new scan has 704; graphify refused to overwrite without `--force`. No force overwrite was performed.
- No production deployment, security review, performance benchmark, frontend, worker, authentication, Redis, commit, push, or merge was performed.

---

## Previous task record (M1-PY-T1)

**Status:** M1-T1 API foundation merged into `dev` by PR #2 at `f373ebc`. Milestone 1 remains in progress because CI is outstanding.
**Objective:** Python 3.12 FastAPI service, typed configuration, async PostgreSQL access, explicit Alembic baseline, `/healthz` and `/readyz`, tests, and Windows developer setup.
**Scope exclusions:** Authentication, workspace authorization, membership roles, task/workflow domain, worker, LangGraph, Redis, frontend, deployment, and CI.

## Handoff

- API package: `services/api/devflow_api/`, matching `ARCHITECTURE.md`.
- Runtime setup: root `pyproject.toml`, generated `uv.lock`, `.python-version`, placeholder `.env.example`, and local PostgreSQL `compose.yaml`.
- Prior local verification: PostgreSQL migration integration (1 passed on fresh `devflow_m1_acceptance_20261014_test`); Alembic repeat left revision/catalog unchanged; additional live PostgreSQL acceptance checks are listed below. These DB checks were not rerun for PR #2.
- Live application-route checks against PostgreSQL: `/healthz` 200; `/readyz` 200 at head; `/readyz` 503 `{"status":"degraded"}` for an empty behind-head database and an unreachable port. FastAPI startup left `alembic_version` absent.
- Relation-guard check: table, view, sequence, and foreign table in non-system schema `relation_guard`; integration test refused before migration and left `alembic_version` absent. Existing `devflow_test` was not modified.
- Local PR #2 checks: pytest (15 passed, 1 integration deselected), Pyright (0 diagnostics), Ruff lint/format, docs validator (36 documents, 310 links, 4 Mermaid diagrams), and `git diff --check` passed. No CI workflow is configured.
- Independent read-only review found no API/database findings. Its documentation findings (branch-name text, coverage counts, and validator false positive) were fixed and the reviewer confirmed resolution.
- PR #2 was committed as `acdd0d64f22539d745ae2d19972c788a45879f8b`, pushed, and merged into `dev` as `f373ebcccac6984cc0c957127d804ccd40b6980b`.
- Recommended next task: add CI and wire in the documentation validator; keep Milestone 1 in progress until its remaining exit criteria are met.

---
## Previous task record (M1-T2)

M1-T2 compared coordination designs and recorded a local MCP + SQLite coordinator proposal. Installed Codex, OpenCode, and Claude MCP entry points were inspected, but cross-client interoperability was not tested. OpenCode configuration inspection failed because of a machine-local log access error; GitHub CLI was unavailable. No coordinator or client configuration was implemented. Its proposal and ADR were later removed under explicit owner authorization.

## Previous task record (M1-T1)

Task 1 governance was committed as `b7b6fe9` on `dev`. The universal documentation-validation rule and thin Copilot adapter were re-inspected for M1-T2; the committed diff for the requested files is empty. Historical Task 1 validation evidence: `git diff --check` passed; `powershell -File tools/validate-docs.ps1` passed (35 documents, 312 links, 4 Mermaid diagrams). No application test suite existed.

---

## Earlier task record (superseded)

---

## Previous task record (superseded)

**Task ID:** ARCH-002
**Title:** Reconcile the documentation set with the verified repository and create the missing implementation-ready specifications
**Status:** Documentation changes applied locally. Not committed. No application code written.
**Supersedes:** ARCH-001, whose "prepared but not verified" status is now resolved — the repository has been inspected directly.

## Objective

Turn a consistent-but-incomplete documentation set into an implementation-ready one, reconciled against the **actual** repository, so future coding agents can build DevFlow AI consistently without relying on prior chat context.

## Verified starting conditions

- Commit `57af064` on `main`, clean working tree, 18 tracked files.
- Repository is documentation-only: no application code, manifests, tests, migrations, CI, or deployment files.
- `PROJECT_CONTEXT.md` was absent despite being the designated master briefing.
- No link breakage existed in the tracked Markdown.
- `graphify-out/` is stale (built from `92b26715`) and graph-dominant on third-party skill libraries.

## Scope

**Created:**
- `PROJECT_CONTEXT.md`
- `docs/DOCUMENTATION_INDEX.md`
- `docs/THREAT_MODEL.md`
- `docs/API_CONTRACTS.md`
- `docs/AGENT_RUNTIME.md`
- `docs/DATABASE.md`
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/decisions/README.md` and `docs/decisions/0001`–`0010`
- `tools/validate-docs.ps1` — documentation validator (documentation tooling, not application code)

**Updated:**
- `README.md`
- `AGENTS.md`
- `ARCHITECTURE.md`
- `PLAN.md`
- `CODE_STYLE.md`
- `docs/SECURITY.md`
- `docs/TESTING.md`
- `docs/PERFORMANCE.md`
- `.agent-state/CURRENT.md`
- `.agent-state/ACTIVE-TASK.md`

**Preserved unchanged (content still accurate, not weakened):**
- `PRD.md` (product scope — reconciled by reference, requirements unchanged)
- `SPEC.md` (lifecycle and contract semantics remain authoritative)
- `Design-system.md`
- `CLAUDE.md`, `.github/copilot-instructions.md`, `LICENSE`, `.gitignore`, `.gitattributes`
- All third-party skill libraries under `.agents/`, `.claude/`, `.codex/`, `.opencode/` — **untouched**.

## Procedure followed

1. Inspected Git branch, status, recent commits, tracked/untracked/ignored files, and the full tree.
2. Read every project-owned Markdown file and the relevant agent configuration.
3. Distinguished verified fact from documented requirement from proposal from unresolved decision.
4. Verified internal link targets across all tracked documents.
5. Created missing specifications; updated stale status claims; kept task states, endpoints, and terminology identical across documents.
6. Ran documentation validation and recorded exact commands and results.

## Acceptance criteria

- [x] The repository's true state (documentation-only) is stated plainly and cannot be mistaken for implemented software.
- [x] Exactly one authoritative document exists per subject; overlaps link instead of duplicating.
- [x] Project scope, architecture, security boundaries, data model, agent runtime, and API conventions are specified.
- [x] Requirements map to components, tests, and evidence expectations.
- [x] Material owner decisions are recorded as ADRs with status **Proposed** and are not silently treated as approved.
- [x] Performance budgets remain clearly labeled unverified targets.
- [x] Documentation consistency is machine-checkable via `tools/validate-docs.ps1`, which passes and is proven to detect injected defects.
- [x] No application code, dependency, migration, or product executable was added.
- [x] Nothing was committed, pushed, or published.

## Out of scope

- Creating the application scaffold or installing dependencies.
- Moving existing files into a monorepo layout.
- Implementing any runtime, worker, tool gateway, or MCP integration.
- Committing, pushing, or changing remote GitHub state.

## Handoff

1. Read `PROJECT_CONTEXT.md`, then `docs/DOCUMENTATION_INDEX.md`.
2. Review `git diff` and `git status` — all changes are Markdown only.
3. Answer the open decisions in `docs/decisions/` (highest priority: runtime/package managers, durable dispatch, auth and tenancy).
4. Begin **Milestone 1 — developer foundation** in `PLAN.md` only after those decisions are confirmed.
5. Update `.agent-state/CURRENT.md` only with verified results.

# Current Project State

**Last verified base:** 2026-10-14, `HEAD` at `e8ca84c1e8a64c2e355cb34fe97240bc1c039a41`, after PR #3 merged into `dev` (based on `e82ba8f`). Current repository changes are uncommitted on the feature branch.
**Product direction:** Confirmed MVP direction (owner-approved).
**Active milestone:** Milestone 1 developer foundation is in progress. M1-T1 API foundation is merged; CI remains outstanding.
**Implementation status:** FastAPI configuration, database lifecycle, health/readiness, the empty baseline migration, tests, and quality tooling originated in the merged M1 foundation. This branch moves them under `backend/` and adds root Compose startup for PostgreSQL/backend with explicit migrations. Authentication, workspace authorization, product domain, worker, frontend app, and CI are not implemented.

**Active work:** Owner-approved repository structure and Docker startup refactor is implemented and locally verified on `feature/repository-structure-refactor`, based on `dev` commit `e8ca84c1e8a64c2e355cb34fe97240bc1c039a41`. Changes remain uncommitted and unmerged. Design and implementation plan: [`docs/superpowers/specs/2026-10-14-repository-structure-refactor-design.md`](../docs/superpowers/specs/2026-10-14-repository-structure-refactor-design.md) and [`docs/superpowers/plans/2026-10-14-repository-structure-refactor.md`](../docs/superpowers/plans/2026-10-14-repository-structure-refactor.md).
### How the verification commit is checked

`tools/validate-docs.ps1` verifies that the commit named below is a **real commit and an ancestor of current `HEAD`**. It deliberately does not require exact equality with `HEAD`: a document does not become false merely because a later commit exists, and an equality check would fail after every commit and train readers to ignore it. The check still fails if the recorded commit is unknown to the repository or has left `HEAD`'s history through a rewrite, reset, or rebase — both of which genuinely invalidate the verification.

When more than one commit has landed since the recorded commit, re-run `git rev-parse HEAD`, compare, and update this file if the repository facts below changed.

---

## Verified repository facts

Verified against `dev` merge commit `f373ebc` (PR #2; feature commit `acdd0d6`).

| Fact | Verified value |
|---|---|
| Branch | `feature/repository-structure-refactor` based on `dev` at `e8ca84c`; uncommitted |
| Merge commit | `f373ebc` (`feat: add API foundation`) |
| Verification commit | `e8ca84c` (ancestor of current HEAD; checked by the documentation validator) |
| Implementation state | API foundation relocated to `backend/`; Dockerfile and backend Compose service added; review uncommitted diff before merge |
| Application source | `backend/devflow_api/`; no frontend application, workflow, auth, or domain implementation |
| Dependency manifests | `backend/pyproject.toml`, `backend/uv.lock`, `backend/.python-version` |
| Tests | pytest unit tests and guarded PostgreSQL integration test under `backend/tests/` |
| Migrations | Explicit empty Alembic baseline at `backend/migrations/versions/0001_initial.py` |
| Local database | PostgreSQL Compose service with localhost-only port, persistent `devflow-postgres` volume, and health check; backend readiness waits for an explicit migration |
| Deployment | Planning guidance only; production topology, secrets, HTTPS, backups, and security review are not configured or verified |
| CI/CD workflows | None |
| Real PostgreSQL validation | Verified 2026-10-14 on isolated `_test` databases: fresh baseline/repeat, live readiness, startup without migrations, and relation guard; refactor branch reran the relocated migration integration test |
| Documentation validator | `tools/validate-docs.ps1`; run after documentation edits |
### ADR approval status at this commit

Eight ADRs are **Accepted** (including owner-approved `0001`): `0001`–`0004`, `0007`, `0008`, `0010`, `0011`. `0005`, `0006`, and `0009` remain **Proposed** and are not binding. See `docs/decisions/README.md`.

**Interpretation:** the API foundation is implemented and relocated in this uncommitted branch. Product requirements in `PRD.md` and `SPEC.md` remain planned unless specifically evidenced; no product workflow or frontend app is implemented.

---

## Agreed MVP (owner-approved)

- Next.js App Router + React + TypeScript + Tailwind CSS + shadcn/ui dashboard.
- Python FastAPI + Pydantic API.
- LangGraph workflows in a separate background worker.
- Python CLI using the same HTTP API.
- PostgreSQL for durable tasks, state, and audit records.
- Redis only where justified; never the sole durable store.
- SSE for task progress, with an authoritative task-status snapshot endpoint.
- Task submission must not wait for full agent execution.

## Core performance direction

Initial **targets** (never measured, never achieved): task submission p95 < 200 ms; lightweight/cached reads p95 < 100 ms; database-backed reads p95 < 200 ms; INP ≤ 200 ms; LCP ≤ 2.5 s; aim for 60 FPS on representative hardware. Authoritative detail: `docs/PERFORMANCE.md`.

**No benchmark has ever been run in this repository.** There is no load-test tooling or recorded performance environment. Treat all budgets as hypotheses.

---

## Documentation layer status

Reconciled and committed in `e8a4d71`; reconciled further in the ADR-approval pass of 2026-10-13:

- `PROJECT_CONTEXT.md` created (previously referenced as the master briefing but **absent** from the repository and referenced by no file).
- Source-of-truth map, ownership, and conflict rules documented in `docs/DOCUMENTATION_INDEX.md`.
- Missing specifications created: `docs/THREAT_MODEL.md`, `docs/API_CONTRACTS.md`, `docs/AGENT_RUNTIME.md`, `docs/DATABASE.md`, `docs/REQUIREMENTS_TRACEABILITY.md`, `docs/decisions/`.
- **Eight ADRs Accepted** (including owner-approved `0001`): `0001`–`0004`, `0007`, `0008`, `0010`, `0011`. `0005`, `0006`, and `0009` remain Proposed.
- **Automated documentation validation:** [`tools/validate-docs.ps1`](../tools/validate-docs.ps1) checks link integrity, code-fence balance, Mermaid block syntax, unqualified implementation/performance claims, ADR status validity and index completeness, canonical task-state coverage, verification-commit ancestry, machine-specific absolute paths, and **line endings against the `.gitattributes` LF policy**. It was verified in both directions — deliberate defects were injected to confirm it detects them. **It is not yet wired into CI because no CI exists**; that is a Milestone 1 deliverable.

## Known traps

- **`graphify-out/` is stale and low-value.** Built from commit `92b26715`, far behind the current repository. Its ~3,369 nodes are dominated by third-party skill libraries and do not include the current API under `backend/`. `graphify-out/wiki/index.md`, referenced by `CLAUDE.md`, **does not exist**. Do not use the graph for architecture answers until regenerated against first-party sources.
- **No CI exists.** Any "quality gate" language in the docs describes intent, not enforcement.
- **The validator must be run manually** and will fail on line-ending violations; keep text files at LF.

---

## Next actions

1. Add CI and wire in the documentation validator as the remaining Milestone 1 foundation work.
2. Keep workspace membership roles unresolved; do not implement authorization until those semantics are decided.


**Do not commit or push** without explicit owner authorization.

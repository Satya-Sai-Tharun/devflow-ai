# Current Project State

**Last verified:** by direct repository inspection at commit `57af064` (`main`), clean working tree.
**Product direction:** Confirmed MVP direction (owner-approved).
**Active milestone:** Milestone 0 — documentation reconciliation — **substantially complete for the documentation layer**. Next is Milestone 1 — developer foundation.
**Implementation status:** **No application code exists.** This is a verified fact, not an assumption.

---

## Verified repository facts

Verified with `git rev-parse HEAD`, `git status --short`, and `git ls-files`:

| Fact | Verified value |
|---|---|
| Branch | `main` |
| HEAD at last audit | `57af064` |
| Working tree at HEAD | Clean; no untracked files — this describes commit `57af064` **before** the documentation audit |
| Working tree now | **Dirty, and that is expected.** The audit's documentation changes are uncommitted: modified `.agent-state/*`, `AGENTS.md`, `ARCHITECTURE.md`, `CLAUDE.md`, `PLAN.md`, `README.md`, `SPEC.md`, `docs/SECURITY.md`; new `PROJECT_CONTEXT.md`, `GEMINI.md`, `tools/`, `docs/THREAT_MODEL.md`, `docs/API_CONTRACTS.md`, `docs/AGENT_RUNTIME.md`, `docs/DATABASE.md`, `docs/DOCUMENTATION_INDEX.md`, `docs/REQUIREMENTS_TRACEABILITY.md`, `docs/decisions/`. **Nothing has been committed or pushed.** Do not read the "clean" row above as a current fact — re-run `git status --short` |
| Tracked files at `57af064` | 18 — all Markdown except `LICENSE`, `.gitignore`, `.gitattributes` |
| Application source | None (no Python, no TypeScript/React, no entry points) |
| Dependency manifests / lockfiles | None (no project-owned `pyproject.toml`, `requirements.txt`, or `package.json`) |
| Tests / test configuration | None |
| Migrations / schema | None |
| CI/CD workflows | None — `.github/` contains only `copilot-instructions.md` |
| Container / deployment files | None |
| Environment examples | None (`.gitignore` already permits `!.env.example`; the file does not exist yet — `docs/SECURITY.md` requires it, and `PLAN.md` Milestone 1 produces it) |
| Documentation validator | `tools/validate-docs.ps1` — passes (documentation checks only, not application tests) |
| Gitignored tooling | `.agents/`, `.claude/`, `.codex/`, `.opencode/` (third-party skill libraries), `graphify-out/` |

**Interpretation:** the repository is currently a **specification and documentation set** for software that has not been built. Every capability described in `PRD.md`, `SPEC.md`, and `ARCHITECTURE.md` is planned. No feature is implemented.

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

**No benchmark has ever been run in this repository.** There is no load-test tooling, no running service, and no recorded environment. Treat all budgets as hypotheses.

---

## Documentation layer status

Reconciled in this pass:

- `PROJECT_CONTEXT.md` created (previously referenced as the master briefing but **absent** from the repository and referenced by no file).
- Source-of-truth map, ownership, and conflict rules documented in `docs/DOCUMENTATION_INDEX.md`.
- Missing specifications created: `docs/THREAT_MODEL.md`, `docs/API_CONTRACTS.md`, `docs/AGENT_RUNTIME.md`, `docs/DATABASE.md`, `docs/REQUIREMENTS_TRACEABILITY.md`, `docs/decisions/`.
- Internal Markdown link integrity verified across all tracked documents.
- **Automated documentation validation added:** [`tools/validate-docs.ps1`](../tools/validate-docs.ps1) checks link integrity, code-fence balance, Mermaid block syntax, unqualified implementation/performance claims, ADR status validity and index completeness, canonical task-state coverage, commit-freshness against HEAD, and machine-specific absolute paths. **It passes** against the full set (33 documents, 274 links, 4 Mermaid diagrams) and was verified in both directions — deliberate defects were injected to confirm it detects them. It is not yet wired into CI because no CI exists.

## Known traps

- **`graphify-out/` is stale and low-value.** Built from commit `92b26715`; HEAD is `57af064`. Its ~3,369 nodes are dominated by third-party skill libraries, and there is no first-party source code to graph. `graphify-out/wiki/index.md`, referenced by `CLAUDE.md`, **does not exist**. Do not use the graph for architecture answers until regenerated against first-party sources.
- **No CI exists.** Any "quality gate" language in the docs describes intent, not enforcement.

---

## Next actions

1. **Milestone 1 (developer foundation).** Owner decisions first: runtime versions, Python and Node package managers, target folder layout approval. Then scaffolding, `.env.example`, and format/lint/type-check/test commands.
2. Confirm the durable job-dispatch/recovery strategy (`docs/decisions/0002-durable-job-dispatch.md`) before any worker code is written.
3. Confirm authentication and tenancy (`docs/decisions/0003-auth-and-tenancy.md`) before any endpoint is exposed.
4. Implement the task lifecycle domain and its tests (Milestone 2) before LangGraph, MCP, or RAG work.
5. Update this file only after verifying actual repository changes and test results.

**Do not commit or push** without explicit owner authorization.

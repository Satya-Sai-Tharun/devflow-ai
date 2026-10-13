# Current Project State

**Last verified:** by direct repository inspection at commit `e8a4d71` (`main`), clean working tree.
**Product direction:** Confirmed MVP direction (owner-approved).
**Active milestone:** Milestone 0 — documentation reconciliation — **complete and committed**. Milestone 1 (developer foundation) is **prepared but not started**; see `PLAN.md`.
**Implementation status:** **No application code exists.** This is a verified fact, not an assumption.

### How the verification commit is checked

`tools/validate-docs.ps1` verifies that the commit named below is a **real commit and an ancestor of current `HEAD`**. It deliberately does not require exact equality with `HEAD`: a document does not become false merely because a later commit exists, and an equality check would fail after every commit and train readers to ignore it. The check still fails if the recorded commit is unknown to the repository or has left `HEAD`'s history through a rewrite, reset, or rebase — both of which genuinely invalidate the verification.

When more than one commit has landed since the recorded commit, re-run `git rev-parse HEAD`, compare, and update this file if the repository facts below changed.

---

## Verified repository facts

Verified with `git rev-parse HEAD`, `git status --short`, and `git ls-files`:

| Fact | Verified value |
|---|---|
| Branch | `main` |
| Verification commit | `e8a4d71` — an ancestor of `HEAD`; checked by the validator |
| HEAD at time of writing | `e8a4d71`, in sync with `origin/main` |
| Working tree | **Clean** at that commit |
| Tracked files | 38 — documentation and one validator script; no application source |
| Application source | None (no Python, no TypeScript/React, no entry points) |
| Dependency manifests / lockfiles | None (no project-owned `pyproject.toml`, `requirements.txt`, or `package.json`) |
| Tests / test configuration | None |
| Migrations / schema | None |
| CI/CD workflows | None — `.github/` contains only `copilot-instructions.md` |
| Container / deployment files | None (`compose.yaml` is a Milestone 1 deliverable) |
| Environment examples | None. `.gitignore` permits `!.env.example`; the file does not exist yet — `docs/SECURITY.md` requires it and `PLAN.md` Milestone 1 produces it |
| Documentation validator | `tools/validate-docs.ps1` — documentation checks only, not application tests |
| Gitignored tooling | `.agents/`, `.claude/`, `.codex/`, `.opencode/` (third-party skill libraries), `graphify-out/`, `.gemini/`, `.antigravity/` |

### ADR approval status at this commit

Seven ADRs are **Accepted** by explicit owner decision on 2026-10-13: `0002`, `0003`, `0004`, `0007`, `0008`, `0010`, `0011`. ADR `0001` is Accepted from the pre-existing owner-approved MVP direction. Three remain **Proposed** and are **not binding**: `0005` (model providers and spend), `0006` (retention and privacy), `0009` (tool sandbox). See `docs/decisions/README.md`.

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

Reconciled and committed in `e8a4d71`; reconciled further in the ADR-approval pass of 2026-10-13:

- `PROJECT_CONTEXT.md` created (previously referenced as the master briefing but **absent** from the repository and referenced by no file).
- Source-of-truth map, ownership, and conflict rules documented in `docs/DOCUMENTATION_INDEX.md`.
- Missing specifications created: `docs/THREAT_MODEL.md`, `docs/API_CONTRACTS.md`, `docs/AGENT_RUNTIME.md`, `docs/DATABASE.md`, `docs/REQUIREMENTS_TRACEABILITY.md`, `docs/decisions/`.
- **Seven ADRs accepted by explicit owner decision on 2026-10-13:** `0002`, `0003`, `0004`, `0007`, `0008`, `0010`, `0011` (0011 newly created). `0005`, `0006`, `0009` remain Proposed.
- **Automated documentation validation:** [`tools/validate-docs.ps1`](../tools/validate-docs.ps1) checks link integrity, code-fence balance, Mermaid block syntax, unqualified implementation/performance claims, ADR status validity and index completeness, canonical task-state coverage, verification-commit ancestry, machine-specific absolute paths, and **line endings against the `.gitattributes` LF policy**. It was verified in both directions — deliberate defects were injected to confirm it detects them. **It is not yet wired into CI because no CI exists**; that is a Milestone 1 deliverable.

## Known traps

- **`graphify-out/` is stale and low-value.** Built from commit `92b26715`, which is far behind `HEAD`. Its ~3,369 nodes are dominated by third-party skill libraries, and there is no first-party source code to graph. `graphify-out/wiki/index.md`, referenced by `CLAUDE.md`, **does not exist**. Do not use the graph for architecture answers until regenerated against first-party sources.
- **No CI exists.** Any "quality gate" language in the docs describes intent, not enforcement.
- **The validator must be run manually** and will fail on line-ending violations; keep text files at LF.

---

## Next actions

1. **Milestone 1 (developer foundation).** Owner decisions for `0007`, `0003`, `0008`, `0011`, `0002`, and `0004` are now **recorded as Accepted** — the remaining prerequisite is the owner's authorization to begin the implementation tasks (T2 onward). T1-class documentation reconciliation is complete.
2. `0005`, `0006`, and `0009` remain **Proposed** and must be accepted before model integration (M5), content storage, and tool/MCP integration (M7) respectively.
3. Implement the task lifecycle domain and its tests (Milestone 2) only after the accepted transition table — including `needs_approval → failed` — is unambiguous. It now is.
4. Update this file only after verifying actual repository changes and test results.

**Do not commit or push** without explicit owner authorization.

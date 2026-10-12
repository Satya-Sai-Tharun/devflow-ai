# Current Project State

**Product direction:** Confirmed MVP direction  
**Active milestone:** Milestone 0 — documentation reconciliation, then Milestone 1 — developer foundation  
**Implementation status:** Not verified from the user's local repository in this document update.

## Agreed MVP
- Next.js App Router + React + TypeScript + Tailwind CSS + shadcn/ui dashboard.
- Python FastAPI + Pydantic API.
- LangGraph workflows in a background worker.
- Python CLI using the same HTTP API.
- PostgreSQL for durable tasks, state, and audit records.
- Redis only where justified.
- SSE for task progress.
- Task submission must not wait for full agent execution.

## Core performance direction
Initial targets: task submission p95 < 200 ms; lightweight/cached reads p95 < 100 ms; database-backed reads p95 < 200 ms; INP ≤ 200 ms; LCP ≤ 2.5 s; aim for 60 FPS on representative hardware. These are targets, not measured results.

## Repository facts to verify
- Inspect `git status --short`, recent commits, tracked files, and the current tree before editing.
- Earlier user-provided output showed no tracked app source directories or dependency manifests matching common patterns, but that snapshot may be stale.
- Existing agent configs and UI/UX skills must be preserved.
- Do not assume any app code, dependency, test, or integration exists without checking.

## Next actions
1. Reconcile source-of-truth docs with current local files and tool-specific instructions.
2. Confirm runtime versions, package managers, and target folder layout.
3. Select a durable job-dispatch/recovery strategy.
4. Implement task lifecycle and tests before broad LangGraph/MCP/RAG work.
5. Update this state only after verifying actual repository changes and test results.

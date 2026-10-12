# Active Task

**Task ID:** ARCH-001  
**Title:** Align architecture and project documentation with the selected performance-first MVP  
**Status:** Documentation update prepared; local repository application and validation are not verified.

## Objective
Align project source-of-truth documents around the owner-selected MVP: Next.js + shadcn/ui dashboard, FastAPI + LangGraph, Python CLI, PostgreSQL, optional purpose-driven Redis, durable background execution, SSE progress, and measurable performance budgets.

## Scope
- `PRD.md`
- `SPEC.md`
- `ARCHITECTURE.md`
- `Design-system.md`
- `AGENTS.md`
- `CODE_STYLE.md`
- `docs/SECURITY.md`
- `docs/TESTING.md`
- `PLAN.md`
- `README.md`
- `.agent-state/CURRENT.md`
- `.agent-state/ACTIVE-TASK.md`

## Procedure
1. Inspect Git status, recent commits, and current files.
2. Compare proposed updates with repository-specific content and preserve useful existing rules.
3. Do not overwrite `CLAUDE.md`, `.github/copilot-instructions.md`, or agent/tool configuration without reviewing their existing content and merging only necessary changes.
4. Preserve all existing skills, including UI/UX and design-system skills.
5. Check internal Markdown links, terminology, file casing, and lifecycle/API consistency.
6. Run available documentation checks and report only those actually executed.
7. Do not commit or push without explicit authorization.

## Acceptance criteria
- MVP stack and API/CLI/dashboard parity are explicit.
- API task submission is decoupled from long-running LangGraph execution.
- Task lifecycle, SSE recovery, approval, cancellation, retry, and worker recovery are specified.
- Performance targets are measurable and clearly marked as unverified targets.
- UI design guidance supports shadcn/ui, accessibility, and low-cost interactions.
- Security, testing, and agent rules agree.
- Existing repository-specific guidance and user changes are preserved.
- Implementation and test status are not fabricated.

## Out of scope
- Creating the application scaffold.
- Installing dependencies.
- Moving current files into a new monorepo layout.
- Implementing real agent execution, shell tools, or MCP integrations.
- Committing, pushing, or changing remote GitHub state.

## Handoff
After applying these changes locally, inspect the diff and run Markdown/link checks if available. Then begin Milestone 1 only after verifying the repository tree and package conventions.

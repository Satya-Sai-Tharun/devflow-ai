# DevFlow AI

Agentic AI software-engineering platform built around workflow orchestration, MCP tool integration, project context, constrained execution, human approval, and evidence-based evaluation.

> Documentation in this bundle is a proposed baseline. Reconcile it with the actual repository and approve open decisions before treating proposals as implemented facts.

## Start here

- [`PRD.md`](PRD.md) — what we're building, for whom, requirements, non-goals, and acceptance criteria.
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — how the system is intended to be structured and how components connect.
- [`AGENTS.md`](AGENTS.md) — how AI coding agents and contributors should work in this repository.
- [`Design-system.md`](Design-system.md) — provisional visual tokens and UI conventions.
- [`CODE_STYLE.md`](CODE_STYLE.md) — engineering conventions.
- [`docs/SECURITY.md`](docs/SECURITY.md) — security baseline and required security tests.
- [`docs/TESTING.md`](docs/TESTING.md) — test strategy and result classifications.
- [`PLAN.md`](PLAN.md) — proposed milestone sequence.
- [`.agent-state/CURRENT.md`](.agent-state/CURRENT.md) — documentation state and next actions.
- [`.agent-state/ACTIVE-TASK.md`](.agent-state/ACTIVE-TASK.md) — active documentation reconciliation task.

## Current status

The documents describe intended direction and open decisions; they do not prove that the corresponding application modules or integrations exist. Inspect the repository and its dependency manifests before running commands or making implementation assumptions.

## Working safely

1. Check `git status --short` and inspect existing changes.
2. Read `AGENTS.md` and the relevant product/architecture/security/testing docs.
3. Coordinate shared file ownership when multiple agents are working.
4. Make focused changes and run the checks configured in the repository.
5. Report exact verification results and any checks not run.
6. Do not commit, push, merge, or deploy unless explicitly requested.

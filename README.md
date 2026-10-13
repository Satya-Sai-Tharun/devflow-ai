# DevFlow AI

DevFlow AI is a controlled agentic software-engineering platform for coordinating coding agents through task workflows, repository context, policy-governed tools, human approval, and automated verification.

## MVP direction
- **Web dashboard:** Next.js App Router, React, TypeScript, Tailwind CSS, shadcn/ui.
- **API:** Python + FastAPI + Pydantic.
- **Orchestration:** LangGraph in a separate background worker.
- **CLI:** Python client using the same HTTP API.
- **Durable state:** PostgreSQL.
- **Redis:** only for justified queue coordination, caching, rate limiting, or ephemeral coordination.
- **Progress:** Server-Sent Events (SSE).

The API should accept a task, persist task/dispatch intent, and return `202 Accepted` with a task ID. The background worker runs the longer agent workflow. Do not hold task-submission requests open while waiting for LLMs or tools.

## Current implementation status
**This repository currently contains documentation and specifications only.** There is no application code, no dependency manifest, no test suite, no migration, and no CI. Every capability described below is planned, not implemented, and no performance target has been measured. Verified repository facts are recorded in [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) § 2 and [`.agent-state/CURRENT.md`](.agent-state/CURRENT.md).

## Source-of-truth documents
Start with [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md) — the master briefing, verified repository state, and navigation hub. [`docs/DOCUMENTATION_INDEX.md`](docs/DOCUMENTATION_INDEX.md) is authoritative for *which document governs which subject* and for the change-management protocol.

Product and behaviour:
- [`PRD.md`](PRD.md) — product scope, requirements, non-goals, acceptance criteria.
- [`SPEC.md`](SPEC.md) — task lifecycle, transitions, and initial API contract.
- [`docs/API_CONTRACTS.md`](docs/API_CONTRACTS.md) — HTTP conventions, error model, endpoints, SSE protocol.

Architecture and runtime:
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — component boundaries, data flow, performance, reliability.
- [`docs/AGENT_RUNTIME.md`](docs/AGENT_RUNTIME.md) — agent adapters, workflow stages, execution bounds, failure handling.
- [`docs/DATABASE.md`](docs/DATABASE.md) — data model, migrations, indexing, retention.

Security and quality:
- [`docs/SECURITY.md`](docs/SECURITY.md) — security baseline and review checklist.
- [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md) — assets, trust boundaries, STRIDE and AI-specific threats, security requirements, test plan.
- [`docs/TESTING.md`](docs/TESTING.md) — test strategy.
- [`docs/PERFORMANCE.md`](docs/PERFORMANCE.md) — authoritative performance budgets and benchmark protocol.
- [`docs/REQUIREMENTS_TRACEABILITY.md`](docs/REQUIREMENTS_TRACEABILITY.md) — requirement → component → test → evidence mapping.

Process and state:
- [`AGENTS.md`](AGENTS.md) — coding-agent workflow and safety rules; the single universal entry point for all agents, including a cross-agent support matrix.
- [`GEMINI.md`](GEMINI.md) — Gemini CLI adapter (delegates to `AGENTS.md`).
- [`CODE_STYLE.md`](CODE_STYLE.md) — engineering conventions.
- [`Design-system.md`](Design-system.md) — UI tokens, shadcn/ui, accessibility and motion guidance.
- [`PLAN.md`](PLAN.md) — milestone sequence and exit criteria.
- [`docs/decisions/`](docs/decisions/README.md) — architecture decision records; **9 of 10 are still Proposed and need owner input**.
- [`.agent-state/CURRENT.md`](.agent-state/CURRENT.md) — verified current state.
- [`.agent-state/ACTIVE-TASK.md`](.agent-state/ACTIVE-TASK.md) — active task and acceptance criteria.

## Development

**There is nothing to install or run yet.** This repository contains documentation only: no dependency manifest, no application code, no test suite, no migration, and no CI. A clean clone yields no runnable software.

The **one command that works today** validates the documentation set:

```powershell
powershell -File tools/validate-docs.ps1
```

It checks link integrity, code-fence balance, Mermaid syntax, unsupported implementation/performance claims, ADR status honesty, lifecycle-contract consistency, and stale repository facts. It passes. It validates prose, not software — see [`docs/DOCUMENTATION_INDEX.md`](docs/DOCUMENTATION_INDEX.md) § 7 for what it does and does not prove.

**Setup and run commands are deliberately absent.** They will be added by [`PLAN.md`](PLAN.md) Milestone 1 *after* the runtime versions and package managers are decided and the commands have actually been run. Do not copy commands from a generic template and claim they work.

**Building the first code is currently blocked on owner decisions** — principally [`docs/decisions/0007`](docs/decisions/0007-runtime-and-package-managers.md) (runtime versions and package managers), [`0003`](docs/decisions/0003-auth-and-tenancy.md) (auth and tenancy), and [`0010`](docs/decisions/0010-approval-outcome-transitions.md) (approval outcomes, which hard-blocks the task-lifecycle milestone). Nine of ten decision records are still **Proposed**; see [`docs/decisions/README.md`](docs/decisions/README.md) and [`PLAN.md`](PLAN.md) § Decisions blocking Milestone 1.

## Engineering priorities
1. Reliable task domain and explicit lifecycle.
2. Low-latency task API and shared API contract.
3. CLI and dashboard core flows.
4. Durable worker execution and LangGraph.
5. SSE, approval, cancellation, and recovery.
6. Governed tools/MCP.
7. Retrieval, evaluation, performance and security hardening.

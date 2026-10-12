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
The repository must be inspected before claiming which application features exist. This document describes the target MVP architecture, not proof that the app has been implemented or that performance targets have been met.

## Source-of-truth documents
- [`PRD.md`](PRD.md) — product scope, requirements, non-goals, acceptance criteria.
- [`SPEC.md`](SPEC.md) — task lifecycle and initial API contract.
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — component boundaries, data flow, performance, reliability.
- [`Design-system.md`](Design-system.md) — UI tokens, shadcn/ui, accessibility and motion guidance.
- [`AGENTS.md`](AGENTS.md) — coding-agent workflow and safety rules.
- [`CODE_STYLE.md`](CODE_STYLE.md) — engineering conventions.
- [`docs/SECURITY.md`](docs/SECURITY.md) — security baseline.
- [`docs/TESTING.md`](docs/TESTING.md) — test strategy and performance budgets.
- [`PLAN.md`](PLAN.md) — milestone sequence.
- [`.agent-state/CURRENT.md`](.agent-state/CURRENT.md) — current work state.
- [`.agent-state/ACTIVE-TASK.md`](.agent-state/ACTIVE-TASK.md) — active task and acceptance criteria.

## Development
Setup and run commands must be added after the actual package managers, manifests, and runtime versions are verified. Do not copy commands from a generic template and claim they work without running them.

## Engineering priorities
1. Reliable task domain and explicit lifecycle.
2. Low-latency task API and shared API contract.
3. CLI and dashboard core flows.
4. Durable worker execution and LangGraph.
5. SSE, approval, cancellation, and recovery.
6. Governed tools/MCP.
7. Retrieval, evaluation, performance and security hardening.

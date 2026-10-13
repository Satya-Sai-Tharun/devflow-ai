# 0001. MVP stack and interface boundaries

- **Status:** Accepted — owner-approved direction (recorded, not inferred)
- **Date:** 2026-10-12
- **Deciders:** project owner
- **Related requirements:** PR-001 … PR-015
- **Related documents:** `ARCHITECTURE.md`, `SPEC.md`, `PRD.md`, `PROJECT_CONTEXT.md` §3

## Context

DevFlow AI coordinates multiple AI coding agents. Without a fixed interface boundary, work fragments across agents: duplicated business logic, conflicting contracts, and unverifiable results. The project needed a single explicit interface set and an execution model that keeps interactive latency independent of long-running agent work.

At the time of recording, the repository contained documentation only — no application code or manifests.

## Decision

Adopt and build behind these boundaries:

| Concern | Decision |
|---|---|
| Web dashboard | Next.js App Router, React, TypeScript, Tailwind CSS, shadcn/ui |
| Backend API | Python, FastAPI, Pydantic |
| Orchestration | LangGraph, running in a separate background worker |
| CLI | Python CLI consuming the **same** HTTP API as the dashboard |
| Durable state | PostgreSQL |
| Ephemeral coordination | Redis only where justified; never the sole durable store |
| Progress transport | Server-Sent Events, plus an authoritative task snapshot endpoint |
| Task submission | Bounded work only: validate, persist task + dispatch intent, return `202 Accepted`. Never runs the graph inline. |

Binding consequences of this decision:

1. The dashboard and CLI are both clients of one versioned HTTP contract. Business logic lives in the API/domain layer, never in the CLI.
2. Python code must never be imported by the TypeScript frontend. Contracts are shared as OpenAPI-generated types or a language-neutral schema.
3. Long-running model and tool work executes only in the worker, never in an HTTP request handler.
4. Lifecycle validation is centralized in domain logic, not in UI or transport code.

## Alternatives considered

- **Server-rendered monolith (e.g. Django templates) with no separate dashboard/API.** Rejected: the CLI and dashboard must share one contract, and a decoupled dashboard is required for the interactive progress/approval experience.
- **Node/TypeScript backend for stack uniformity.** Rejected: the owner selected Python/FastAPI, and the LangGraph and evaluation ecosystem is Python-first.
- **Running LangGraph inline in the API request with a streaming response.** Rejected: it couples request lifetime to model latency, breaks the submission latency budget, and makes cancellation and recovery far harder.
- **WebSockets instead of SSE.** Rejected for progress: progress is one-way server→client, so SSE is simpler, reconnects more predictably, and traverses proxies more easily. Ordinary authenticated requests handle cancellation and approval.
- **Redis as the primary task store.** Rejected: task and audit history are durable records that must survive cache loss and support recovery.

## Consequences

**Positive:** one contract, one lifecycle, testable domain isolated from infrastructure, independent scaling of API and worker, and a clear untrusted boundary around agent/tool execution.

**Negative / accepted costs:** two languages and two toolchains; an operational worker process to deploy and monitor; contract drift risk that must be managed by generating shared types; and the need to solve durable dispatch correctly (see ADR 0002) because submission no longer implies completion.

**Explicitly not decided by this ADR:** queue technology, authentication mechanism, tenancy model, deployment topology, model providers, and retention. Those are ADR 0002–0009.

## Verification

This decision is architectural, not testable by a single test. It is verified by review:

- Any new dependency or component must fit one of the boundaries above or require a superseding ADR.
- A reviewer checks that no CLI command reimplements API/domain logic.
- A reviewer checks that no HTTP handler awaits graph execution.
- `PRD.md`, `SPEC.md`, and `ARCHITECTURE.md` describe the same stack with no contradiction.

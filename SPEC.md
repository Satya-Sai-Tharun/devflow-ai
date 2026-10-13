# DevFlow AI — MVP Specification

## Status
This specification records the agreed MVP direction. Detailed implementation choices must be validated against the repository before changes are made.

## Interfaces
- Web: Next.js App Router, React, TypeScript, Tailwind CSS, shadcn/ui.
- CLI: Python CLI over the shared HTTP API.
- Backend: FastAPI + Pydantic.
- Orchestration: LangGraph in a background worker.
- Persistence: PostgreSQL.
- Redis: optional and purpose-driven, not the durable source of truth.

## Initial API contract

### `POST /api/v1/tasks`
Creates a task. Validate input, authorize the caller, persist task and dispatch intent, then return promptly.

Success: `202 Accepted`
```json
{
  "task_id": "opaque-stable-id",
  "status": "queued",
  "created_at": "ISO-8601 timestamp",
  "status_url": "/api/v1/tasks/opaque-stable-id",
  "events_url": "/api/v1/tasks/opaque-stable-id/events"
}
```

The example is illustrative. The actual ID format and schema are implementation decisions. Return a validation error for malformed input; do not return success if durable acceptance/dispatch intent failed.

### `GET /api/v1/tasks/{task_id}`
Returns the authorized caller's current task snapshot and allowed result metadata.

### `GET /api/v1/tasks/{task_id}/events`
SSE stream of task lifecycle and progress events. Define event IDs, heartbeat behavior, reconnect semantics, authorization, and replay/snapshot strategy. Important state transitions must be persisted independently of a transient connection.

### `POST /api/v1/tasks/{task_id}/cancel`
Requests cancellation. The API must distinguish accepted cancellation request from worker-confirmed cancellation.

### `POST /api/v1/tasks/{task_id}/approval`
Records an authorized approval/rejection decision for a task paused in `needs_approval`. Validate that the task is actually awaiting that decision.

## Task lifecycle
States: `queued`, `running`, `needs_approval`, `completed`, `failed`, `cancelled`, `blocked`.

Allowed transitions:
- `queued` → `running`, `cancelled`, `blocked`
- `running` → `needs_approval`, `completed`, `failed`, `cancelled`, `blocked`
- `needs_approval` → `running`, `cancelled`, `blocked`
- `blocked` → `queued`, `cancelled`
- `completed`, `failed`, `cancelled` are terminal.

Record actor, timestamp, from/to states, reason, and attempt where applicable. Retries must be explicit and idempotent; do not silently reopen terminal tasks.

### Known gap: approval rejection and expiry have no transition

The table above cannot express two of the three approval outcomes required by PR-007 and specified in [`docs/API_CONTRACTS.md`](docs/API_CONTRACTS.md):

| Approval outcome | Expressed by the table above? |
|---|---|
| Approved | Yes — `needs_approval` → `running` |
| **Rejected** | **No.** `cancelled` conflates a declined action with a user cancellation; `blocked` implies a resolvable external dependency. |
| **Expired** | **No.** `failed` is not reachable from `needs_approval`; silence is not consent, so returning to `running` is unacceptable. |

**Status: unresolved — owner decision required.** The recommended resolution is recorded in [`docs/decisions/0010-approval-outcome-transitions.md`](docs/decisions/0010-approval-outcome-transitions.md): add `failed` as an allowed transition from `needs_approval`, with distinct machine-readable reason codes for rejection and expiry. Until the owner decides, the transition set above remains authoritative and the Milestone 2 transition function is blocked.

## Error semantics
Use consistent structured errors with a stable machine-readable code, human-readable message, request/correlation ID, and field details where appropriate. Do not leak stack traces, secrets, internal paths, or provider credentials.

## Worker semantics
- Job execution is separate from HTTP request handling.
- Use bounded concurrency, deadlines, cancellation checks, and retries.
- Plan for duplicate job delivery and idempotent processing.
- Persist enough state to recover from worker restarts.
- Define queue/database consistency strategy before production.
- LangGraph checkpoints support graph recovery but do not by themselves guarantee reliable queue delivery.

## Performance measurement
Record server-side API duration separately from queue wait, LLM latency, tool latency, graph duration, and total task duration. Use p50/p95/p99 and representative concurrency. UI budgets are specified in `PRD.md` and `ARCHITECTURE.md`.

## Security requirements
All task and event access is authorized per task. Tool arguments are schema-validated. Tools are deny-by-default and constrained by allowlists, least privilege, timeouts, output limits, audit events, and approval gates for consequential operations.

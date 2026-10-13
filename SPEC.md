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
- `needs_approval` → `running`, `failed`, `cancelled`, `blocked`
- `blocked` → `queued`, `cancelled`
- `completed`, `failed`, `cancelled` are terminal.

Record actor, timestamp, from/to states, reason, and attempt where applicable. Retries must be explicit and idempotent; do not silently reopen terminal tasks.

### Approval outcomes and terminal reasons

**Approved by explicit owner decision on 2026-10-13** (see [`docs/decisions/0010-approval-outcome-transitions.md`](docs/decisions/0010-approval-outcome-transitions.md)). A task paused in `needs_approval` has these possible outcomes:

| Outcome | Transition | `terminal_reason` | Notes |
|---|---|---|---|
| Human approves | `needs_approval` → `running` | — | Single-use; bound to the recorded action scope and state version |
| Human rejects | `needs_approval` → `failed` | `approval_rejected` | The gated action is permanently refused for that attempt |
| Decision window expires | `needs_approval` → `failed` | `approval_expired` | **Silence is never consent.** Expiry authorizes nothing |
| Cancellation confirmed while paused | `needs_approval` → `cancelled` | `cancelled_by_request` | The pending approval is closed as superseded |
| Non-approval policy condition at the gate | `needs_approval` → `blocked` | a policy code | **Not** an approval outcome. `blocked` is non-terminal and revisitable |

Rules that cannot be relaxed:

1. **A rejected or expired approval must never permit execution.** The gated action is permanently refused for that attempt; the model cannot re-request it and have it run.
2. **Expiry and silence never authorize.** A fall-through to `running` on timeout is a security defect, not a convenience.
3. **An approval is bound to a specific action scope, attempt, and state version.** It is single-use and is never inherited by a later attempt.
4. **Only an authorized human decision resumes a paused task.** Model output, tool output, MCP output, retrieved content, and repository content can *request* an approval but can never grant, widen, or satisfy one.
5. **`needs_approval` → `completed` is not permitted.** Work cannot complete by skipping the gate.

`terminal_reason` is a required machine-readable code on every terminal transition; `reason` carries the human-readable detail. Default approval expiry is **24 hours, configurable by task type** (an owner-approved default; the concrete per-type values remain open).

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

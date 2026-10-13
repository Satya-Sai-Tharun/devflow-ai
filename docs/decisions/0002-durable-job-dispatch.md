# 0002. Durable job dispatch and recovery strategy

- **Status:** **Proposed** — requires owner confirmation before any worker code is written
- **Date:** 2026-10-12
- **Deciders:** project owner (decision required); agent recommendation
- **Related requirements:** PR-005, PR-008, PR-011, PR-012
- **Related documents:** `ARCHITECTURE.md` §4/§8, `SPEC.md` § Worker semantics, `docs/DATABASE.md` § outbox, `docs/AGENT_RUNTIME.md`

## Context

Task submission must return `202 Accepted` after **durable acceptance**, but the work itself runs in a separate worker. This creates the classic dual-write problem: the API writes the task to PostgreSQL and then signals a queue. If the process dies between the commit and the enqueue, the task is accepted but never executed — a silent, permanent stall. If the enqueue happens first and the commit fails, the worker receives a job for a task that does not exist.

`ARCHITECTURE.md` requires that dispatch design "avoid losing a task between database commit and enqueue (for example, a transactional outbox or a proven durable job mechanism)". `SPEC.md` warns that LangGraph checkpointing supports graph recovery but does **not** by itself guarantee reliable queue delivery.

This decision blocks Milestone 5 and must be settled before worker implementation.

## Decision (recommended)

Adopt a **transactional outbox in PostgreSQL** as the durable dispatch mechanism, with the outbox table written in the *same transaction* as the task row.

Recommended shape:

1. `POST /api/v1/tasks` opens one transaction: insert `tasks` row plus `outbox` row (`status = pending`). Commit. Return `202 Accepted`.
2. A dispatcher loop claims outbox rows using `SELECT … WHERE status = 'pending' AND next_attempt_at <= now() FOR UPDATE SKIP LOCKED LIMIT n`, marks them `dispatched`, records the claim, and signals the worker.
3. The worker may also poll the outbox directly, making Redis an optional notification accelerator rather than a correctness dependency.
4. Workers claim work with a **lease** (owner identity + expiry). A worker that dies lets the lease expire; the job becomes reclaimable.
5. Steps are made idempotent via per-attempt/per-step idempotency keys persisted in `task_steps` (see `docs/DATABASE.md`).

**Guarantee this provides: at-least-once delivery.** Handlers must be idempotent. Exactly-once execution is *not* claimed and must not be documented or promised anywhere.

Retry policy: bounded attempts with exponential backoff and jitter, a maximum attempt count, and transfer to a dead-letter state/table after exhaustion, requiring manual or operator-driven recovery.

## Alternatives considered

- **Direct enqueue to Redis after commit (no outbox).** Simplest, and the common default. Rejected as the primary mechanism: it retains the commit→enqueue loss window and makes Redis a correctness dependency, contradicting the requirement that Redis never be the sole durable store.
- **Redis Streams with consumer groups as the queue.** Attractive because it offers delivery tracking and pending-entry claiming. Rejected as the *durability* mechanism for the same reason — task history must survive Redis loss. Remains viable as an optional accelerator on top of the outbox.
- **Database table used directly as the queue (outbox-as-queue, no Redis at all).** Genuinely viable and recommended for the first vertical slice: fewer moving parts, one source of truth, trivially auditable. Trade-off is polling load and `SKIP LOCKED` contention at high throughput. **Recommendation: start here, add Redis notification only when measured polling cost justifies it.**
- **A dedicated broker (RabbitMQ, SQS, NATS JetStream).** Buys delivery and DLQ mechanics without hand-rolling them. Rejected for the MVP: an extra production dependency and operational surface before the core workflow is proven reliable. Worth revisiting if throughput or routing demands outgrow PostgreSQL.
- **Synchronous execution inside the request.** Rejected in ADR 0001.
- **Triggering the worker from a PostgreSQL `LISTEN/NOTIFY`.** Useful as a low-latency wake-up that avoids polling, but notification is not durable and is lost if no listener is connected. Only acceptable as an optimization layered on the outbox, never as the record.

## Consequences

**Positive:** no loss window between commit and dispatch; one durable source of truth; dispatch state is auditable and queryable; recovery is testable by killing a worker mid-job; Redis becomes optional rather than load-bearing.

**Negative / accepted costs:** at-least-once semantics obligate every handler to be idempotent — this is real design work, not a formality. Outbox rows require pruning/archival. Polling costs a small amount of continuous database work. Ordering is not guaranteed across tasks (and must not be assumed).

**Risks to manage:** unbounded outbox growth if rows are never pruned; lease expiry set too short causing duplicate concurrent execution of slow jobs; too long, causing slow recovery — the lease duration must exceed the longest legitimate step and be renewed by heartbeat.

## Verification

- **Unit:** outbox claim query is atomic under concurrency; state transitions from `pending`→`dispatched` are not double-applied.
- **Integration:** simulate a crash between task commit and dispatch — assert the task still executes after restart.
- **Integration:** deliver the same job twice — assert exactly one effective state transition and no duplicated side effects.
- **Integration:** kill a worker holding a lease — assert the job is reclaimed after lease expiry and completes.
- **Integration:** exhaust retries — assert the job reaches dead-letter state and is observable, never silently dropped.
- **Load:** measure dispatcher polling throughput and `SKIP LOCKED` contention; record whether Redis notification is justified by measurement, not intuition.

## Open questions for the owner

1. Approve the outbox-in-PostgreSQL approach, or mandate a broker now?
2. Add Redis notification in the first implementation, or defer until polling is measured as a bottleneck?
3. Required recovery-time objective after a worker crash, which sets the lease duration?

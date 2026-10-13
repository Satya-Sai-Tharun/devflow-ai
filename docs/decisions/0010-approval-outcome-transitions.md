# 0010. Approval outcome transitions (spec gap)

- **Status:** **Accepted** — approved by the project owner on 2026-10-13
- **Date:** 2026-10-12 (proposed); 2026-10-13 (accepted)
- **Deciders:** project owner
- **Related requirements:** PR-007, PR-008, PR-003
- **Related documents:** `SPEC.md` § Approval outcomes, `docs/API_CONTRACTS.md` § 6, `docs/AGENT_RUNTIME.md`, `PRD.md`

> **Owner decision (2026-10-13):** Rejected approvals transition `needs_approval → failed` with `terminal_reason=approval_rejected`. Expired approvals transition `needs_approval → failed` with `terminal_reason=approval_expired`. **Proposed default expiry is 24 hours, configurable by task type.** **Expiry and silence must never authorize execution.** The complete accepted transition table is recorded below and in `SPEC.md`.

## Context

`SPEC.md` defines the allowed transition set as:

```text
queued          -> running | cancelled | blocked
running         -> needs_approval | completed | failed | cancelled | blocked
needs_approval  -> running | cancelled | blocked
blocked         -> queued | cancelled
terminal: completed, failed, cancelled
```

`PRD.md` PR-007 requires that "tasks can pause for an explicit human decision before configured
consequential operations", and `docs/API_CONTRACTS.md` § 6 specifies that a pending approval may be
**approved**, **rejected**, or **expire**. The lifecycle table has no transition that expresses two of
those three outcomes:

| Approval outcome | Intended meaning | Expressible today? |
|---|---|---|
| **Approved** | The human authorized the gated action; execution resumes. | Yes — `needs_approval → running` |
| **Rejected** | The human declined the gated action; the task must not perform it. | No direct transition. `needs_approval → cancelled` is the closest fit but conflates "the user declined this action" with "the user cancelled the task"; `needs_approval → blocked` is wrong, because nothing is preventing progress — a decision was made. |
| **Expired** | No decision arrived within the allowed window; the task cannot proceed. | No direct transition. Neither `cancelled` (nobody cancelled) nor `blocked` (nothing external is blocking) is accurate; `failed` is unreachable from `needs_approval`. |

This is a genuine contradiction between the lifecycle table and the approval semantics, not a
terminology preference. It must be resolved before the domain transition function is implemented
(Milestone 2), because that function is the single source of truth for allowed transitions and its
test matrix is derived from this table.

## Decision (recommended)

Extend the lifecycle table, rather than overloading existing states.

1. **Rejected approval → the task transitions to `failed`**, with a recorded reason distinguishing
   "approval rejected" from other failures, and with the rejection recorded in `approvals` as a
   human decision.
   *Rationale:* the requested work cannot be completed as specified. Marking it `cancelled` would
   misattribute the cause and mislead reporting on cancellation rates; marking it `blocked` would
   imply a resolvable external dependency that does not exist.
2. **Expired approval → the task transitions to `failed`**, with a distinct terminal reason
   (approval timeout), so expiry is observable as its own outcome rather than hidden inside a generic
   failure. Retrying is a new attempt or a new task, per the existing retry rule.
3. **`needs_approval` gains `failed` as an allowed transition.** The resulting **accepted** table:

```text
queued          -> running | cancelled | blocked
running         -> needs_approval | completed | failed | cancelled | blocked
needs_approval  -> running | failed | cancelled | blocked
blocked         -> queued | cancelled
terminal:         completed | failed | cancelled      (never reopened)
```

**Complete accepted transition trigger table** — this is the authoritative form, mirrored in `SPEC.md` § Approval outcomes:

| From | To | Trigger | `terminal_reason` |
|---|---|---|---|
| `running` | `needs_approval` | Graph reaches a policy-marked gate | — |
| `needs_approval` | `running` | Authorized human approves | — |
| `needs_approval` | `failed` | Authorized human rejects | `approval_rejected` |
| `needs_approval` | `failed` | Decision window expires (default 24 h, per-type configurable) | `approval_expired` |
| `needs_approval` | `cancelled` | Authorized cancellation, worker-confirmed | `cancelled_by_request` |
| `needs_approval` | `blocked` | Non-approval policy condition at the gate | policy code |
| `queued` | `running` | Worker claims the job | — |
| `queued` | `cancelled` | Cancellation confirmed before a claim | `cancelled_by_request` |
| `queued` | `blocked` | Required dependency or policy condition unavailable | policy code |
| `running` | `completed` | Verification passed | `completed_verified` |
| `running` | `failed` | Unrecoverable error, retries exhausted | error class |
| `running` | `cancelled` | Cancellation confirmed by the worker | `cancelled_by_request` |
| `running` | `blocked` | Required capability or policy condition unavailable | policy code |
| `blocked` | `queued` | The blocking condition was resolved | — |
| `blocked` | `cancelled` | Cancellation confirmed while blocked | `cancelled_by_request` |

**Forbidden:** `needs_approval → completed`; `needs_approval → running` without a recorded authorized decision; any transition out of `completed`, `failed`, or `cancelled`; expiry treated as approval.

4. **A rejection or expiry must never resume execution.** Once the outcome is recorded, the gated
   action is permanently refused for that attempt. Any re-attempt is a new attempt with a new
   approval requirement — an approval is bound to a specific action scope and attempt, never
   inherited.
5. **The approval record is retained independently of the task outcome** (subject to
   `docs/decisions/0006-data-retention-and-privacy.md`), so an audit can answer who approved or
   declined what, and when.

## Alternatives considered

- **Map rejection to `cancelled`.** Needs no table change and is the smallest fix. Rejected: it makes
  the cancellation metric — which `PRD.md` lists as a success metric — misleading, since a declined
  approval is not a user cancellation, and it loses the ability to distinguish the two in reporting.
- **Map rejection and expiry to `blocked`.** Rejected: `blocked` means a dependency or policy
  condition prevents progress and the task may later return to `queued`. A declined approval is a
  terminal human decision, so `blocked` would create a state the task can never legitimately leave.
- **Add a distinct terminal state such as `rejected`.** Semantically the most precise, and worth
  considering. Rejected for the MVP as premature state-space growth: every new state multiplies the
  transition matrix, UI states, and test cases. A `failed` state with a machine-readable reason code
  carries the same information with no new state. Revisit if rejection analysis becomes a first-class
  product concern.
- **Let an approval expire by falling back to `running` and skipping the gated action.** Rejected
  outright: silence is not consent. This would be a security defect, allowing a consequential action
  to proceed because nobody answered.
- **Allow `needs_approval → running` only, treating "no decision" as an indefinite pause.** Rejected:
  an indefinite pause consumes a lease and worker capacity, and provides no defined outcome for the
  task. Expiry must be explicit.

## Consequences

**Positive:** every approval outcome has a defined, testable destination; cancellation metrics stay
meaningful; timeouts become observable rather than silent; the domain transition function and its test
matrix can be written unambiguously.

**Negative / accepted costs:** the transition table in `SPEC.md` must be updated, and every document
that restates it (`PROJECT_CONTEXT.md` §5, `ARCHITECTURE.md` §5, `docs/API_CONTRACTS.md`,
`docs/AGENT_RUNTIME.md`, `docs/REQUIREMENTS_TRACEABILITY.md`) must change in the same set — this is
exactly the consistency burden that makes a single authoritative table valuable.

**Blocked until decided:** the Milestone 2 transition function and its unit-test matrix.

## Verification

- **Unit:** `needs_approval → failed` is permitted; `needs_approval → completed` remains rejected.
- **Unit:** a rejected approval records the human decision, the reason code, and the actor, and the
  task ends `failed` with reason `approval_rejected`.
- **Unit:** an expired approval ends the task `failed` with reason `approval_expired`, distinguishable
  from `approval_rejected` in the task snapshot.
- **Unit:** after a rejection, the gated action cannot execute on the same attempt, even if the model
  requests it again.
- **Integration:** the approval record survives independently of the terminal task state and is
  retrievable for audit.
- **Integration:** expiry fires at the configured deadline and is not extendable by the model, a tool,
  or an unauthenticated caller.

## Owner decision and remaining items

Resolved by the owner on 2026-10-13:

1. **`failed` as the destination, or a distinct terminal state?** → **`failed`**, with distinct structured `terminal_reason` codes: `approval_rejected` and `approval_expired`. No additional terminal state.
2. **Default approval expiry window, configurable per task type?** → **24 hours default, configurable by task type.** The per-type values remain to be set.
3. **Must a transition-table change always require explicit owner sign-off?** → **Yes for this table.** It is a security-relevant contract: a new edge here can authorize execution. An agent may *propose* an extension (recorded as an ADR) but may not apply one without owner acceptance.

Still open (does not block the Milestone 2 transition function):

- **Concrete per-task-type expiry values** beyond the 24-hour default.
- **Notification behavior on near-expiry**, so a human is warned before a gate closes. Whether to notify at all, and how.
- **Escalation path.** Whether an expiring approval may escalate to a different approver before it fails, or always fails. Current accepted behavior is that it fails; an escalation path would be a new decision.

## Full accepted transition table

```text
queued          -> running | cancelled | blocked
running         -> needs_approval | completed | failed | cancelled | blocked
needs_approval  -> running | failed | cancelled | blocked
blocked         -> queued | cancelled
terminal:         completed | failed | cancelled      (never reopened)
```

Exactly one edge was added to the previous table: **`needs_approval → failed`**. `needs_approval → completed` is and remains forbidden.

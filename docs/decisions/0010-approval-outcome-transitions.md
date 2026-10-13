# 0010. Approval outcome transitions (spec gap)

- **Status:** **Proposed** — requires owner decision; identified during the documentation audit
- **Date:** 2026-10-12
- **Deciders:** project owner (decision required); agent analysis
- **Related requirements:** PR-007, PR-008, PR-003
- **Related documents:** `SPEC.md` § Task lifecycle, `docs/API_CONTRACTS.md` § 6, `docs/AGENT_RUNTIME.md`, `PRD.md`

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
3. **`needs_approval` gains `failed` as an allowed transition.** The resulting updated table:

```text
queued          -> running | cancelled | blocked
running         -> needs_approval | completed | failed | cancelled | blocked
needs_approval  -> running | failed | cancelled | blocked
blocked         -> queued | cancelled
terminal: completed, failed, cancelled
```

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

## Open questions for the owner

1. Approve `failed` as the destination for rejected and expired approvals, or introduce a distinct
   terminal state (for example `rejected`)?
2. What is the default approval expiry window, and may it be configured per task type?
3. Should an allowed transition table change such as this require an explicit owner sign-off every
   time, or may agents extend it when an extension is clearly justified and recorded?

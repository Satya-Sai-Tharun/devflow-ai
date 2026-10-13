# Architecture Decision Records

This directory holds the durable, reviewable record of DevFlow AI architecture decisions.

## Why these exist

`ARCHITECTURE.md` §12 already enumerated decisions that "must be recorded before production", and `PROJECT_CONTEXT.md` §11 requires material decisions to be durable rather than dependent on a chat session. Previously no record existed, so a future agent could not tell an approved decision from an unexamined default. These ADRs close that gap.

## Format

Each record uses this structure:

```text
# NNNN. Short title
- Status: Proposed | Accepted | Rejected | Superseded by NNNN | Deprecated
- Date: YYYY-MM-DD
- Deciders: owner | agent proposal
- Supersedes / Superseded by
- Related requirements: PR-xxx

## Context
## Decision
## Alternatives considered
## Consequences
## Verification
```

## Status vocabulary — read this before acting

- **Proposed** — a recommendation from an agent or a decision that needs the owner's confirmation. **Not yet binding.** The current documents already describe intended behavior, but implementation must not begin on a *Proposed* material decision without the owner's answer.
- **Accepted** — the owner has explicitly approved it. Binding.
- **Rejected** — considered and declined. Do not re-propose without new evidence.
- **Superseded** — replaced by a later record, which is linked.
- **Deprecated** — no longer relevant but retained for history.

## Rules

1. Do not change an existing **Accepted** record. Write a new record that supersedes it and update the status of the old one.
2. A material decision that is still **Proposed** must not be cited as settled in any other document.
3. Low-risk, reversible implementation detail (naming, file layout inside an approved boundary, test helper design) does **not** need an ADR.
4. An ADR is required for: product scope, core architecture, security boundaries, data retention, deployment strategy, major dependencies, queue/dispatch mechanism, and authentication/tenancy.
5. Record the decision in the same change set that updates the affected source-of-truth documents, per `PROJECT_CONTEXT.md` §11.

## Index

**Approval status as of 2026-10-13.** Eight records are **Accepted** (binding); three remain **Proposed** (not binding — see rule 2 above).

| ADR | Title | Status |
|---|---|---|
| [0001](0001-mvp-stack-and-interface-boundaries.md) | MVP stack and interface boundaries | **Accepted** (owner-approved direction) |
| [0002](0002-durable-job-dispatch.md) | Durable job dispatch and recovery strategy | **Accepted** (2026-10-13) |
| [0003](0003-auth-and-tenancy.md) | Authentication and tenancy model | **Accepted** (2026-10-13) |
| [0004](0004-deployment-topology.md) | Deployment topology and environments | **Accepted** (2026-10-13) |
| [0005](0005-model-provider-strategy.md) | Model provider strategy and spend controls | **Proposed** — not binding |
| [0006](0006-data-retention-and-privacy.md) | Data retention, privacy, and classification | **Proposed** — not binding |
| [0007](0007-runtime-and-package-managers.md) | Runtime versions and package managers | **Accepted** (2026-10-13) |
| [0008](0008-database-identity-and-migrations.md) | Database identity strategy and migration tooling | **Accepted** (2026-10-13) |
| [0009](0009-tool-execution-sandbox.md) | Tool execution sandbox and permission model | **Proposed** — not binding |
| [0010](0010-approval-outcome-transitions.md) | Approval outcome transitions (spec gap) | **Accepted** (2026-10-13) |
| [0011](0011-data-access-layer.md) | Data access layer (ORM, driver, session conventions) | **Accepted** (2026-10-13) |

### What remains Proposed, and what it blocks

| ADR | Open subject | Must be accepted before |
|---|---|---|
| 0005 | Hosted-provider permission, concrete spend limits, local model and hardware baseline | Model integration (Milestone 5) |
| 0006 | Retention windows, raw prompt retention, deletion behavior, operator access | Any storage of real content |
| 0009 | Sandbox implementation, egress rules, approval-required operations, resource ceilings | Tool/MCP integration (Milestone 7) |

### Standing restrictions that hold while those remain Proposed

These are **not** lifted by the accepted decisions and must be preserved in every document:

- **Mock inference is the default** for tests and CI.
- **Hosted providers remain disabled by default** (`DEVFLOW_HOSTED_ENABLED=false`).
- **Secrets are never logged.**
- **Tool permissions are server-enforced**, and **absence of an allow rule means denial**.
- **An expired approval permits no action.**

## Reading order for a new agent

1. `0001` — the approved boundary you are building inside.
2. `0002`, `0003`, `0007`, `0008`, `0011` — the accepted decisions that determine layout, schema, and data access.
3. `0010` — the accepted lifecycle transition table, including approval outcomes.
4. `0004` — the accepted local/CI topology.
5. `0005`, `0006`, `0009` — **Proposed**; read them for direction, but do not treat them as settled.

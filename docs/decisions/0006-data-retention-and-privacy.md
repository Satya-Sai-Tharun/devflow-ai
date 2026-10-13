# 0006. Data retention, privacy, and classification

- **Status:** **Proposed** — required before production; no owner decision recorded
- **Date:** 2026-10-12
- **Deciders:** project owner (decision required); agent recommendation
- **Related requirements:** PR-002, PR-012
- **Related documents:** `docs/SECURITY.md` § Secrets and data handling, `docs/DATABASE.md` § Retention, `docs/THREAT_MODEL.md`

## Context

DevFlow AI will process some of the most sensitive material a developer has: proprietary source code, internal documentation, prompts, model completions, tool output, and approval decisions. `docs/SECURITY.md` requires retention and deletion behavior to be defined for "prompts, repository content, checkpoints, results, and audit events before production", and `PRD.md` lists retention as a constraint to resolve.

Two forces conflict and cannot both be satisfied maximally:

- **Auditability** wants durable, tamper-resistant history of decisions and actions.
- **Privacy and deletion obligations** want the ability to remove content on request or on expiry.

Without an explicit policy, the default outcome is unbounded retention of sensitive content — a liability, not an asset.

## Decision (recommended)

**Classify data, then apply per-class retention with content minimization by default.**

Recommended classification:

| Class | Examples | Handling |
|---|---|---|
| **Secret** | Provider keys, DB credentials, tokens | Never persisted in application tables; never logged; never sent to a model. |
| **Highly sensitive** | Repository file contents, source diffs, prompts, completions, tool output | Persist only what is operationally required; default to **references/digests over raw copies**; short retention; never in logs by default. |
| **Sensitive** | Task titles/descriptions, approval decisions, actor identity | Scoped to tenant; retained for the operational window; access-audited. |
| **Operational** | States, timestamps, attempts, durations, error classifications, correlation IDs | Retained longer; safe to log; no raw payloads. |
| **Public** | Documentation, product metadata | Unrestricted. |

Recommended rules:

1. **Minimize by default.** Store a pointer/digest to large or sensitive artifacts rather than duplicating content into task rows, logs, or audit records.
2. **Redaction is a requirement, not a convention.** Logging and audit writers must redact secrets and sensitive payloads by construction, with a test proving a known-secret-shaped value never reaches a log or audit record.
3. **Retention windows are configuration, not literals.** Define per-class windows (see `docs/DATABASE.md` § Retention for proposed values) and make them configurable so an owner can change policy without a code change.
4. **Deletion is a designed procedure**, covering the task, its steps, artifacts, checkpoints, and cached copies — while preserving the minimum audit fact that an action occurred, divorced from sensitive content.
5. **SSE is never a record.** Transient stream buffers carry no retention obligation; the durable snapshot is authoritative.
6. **Checkpoints and step outputs are pruned** on the same schedule as their class — they are the most common accidental long-term store of sensitive content.

## Alternatives considered

- **Retain everything indefinitely ("storage is cheap").** Rejected: it maximizes breach impact and deletion cost, conflicts with least-privilege principles, and turns the database into a long-term repository of proprietary source code.
- **Delete everything immediately after task completion.** Rejected: destroys the auditability and debuggability that are core product value (`PRD.md` PR-012), and makes failure investigation impossible.
- **Hard-delete audit records on erasure request.** Rejected: it undermines the integrity of the decision trail and invites abuse. Recommendation is to separate the *decision fact* (who approved what, when) from the *sensitive content* (the diff, the prompt), allowing the former to survive and the latter to be erased.
- **Store raw prompts/completions for evaluation quality.** Deferred rather than rejected: valuable for evaluation, but only with explicit scope, redaction, and a defined window. An unresolved owner decision.
- **Encrypt-at-rest as the whole answer.** Insufficient alone: encryption protects against storage theft but not against over-broad access, over-retention, or log leakage. Complementary, not substitutive.

## Consequences

**Positive:** reduced breach blast radius; bounded storage growth; a defensible answer to deletion requests; logs and audit records safe to operate on.

**Negative / accepted costs:** debuggability is reduced when raw content is not retained — mitigated by digests, structured error classifications, and opt-in verbose capture in local development only. Retention jobs add operational surface. Redaction-by-construction requires deliberate interfaces rather than ad-hoc logging calls.

**Residual risk:** even with minimal retention, a compromised worker can exfiltrate whatever it can read during execution. This is a sandbox and egress-control problem (ADR 0009, `docs/THREAT_MODEL.md`), not a retention problem.

## Verification

- **Unit:** the redaction layer removes known secret-shaped values from log and audit payloads.
- **Integration:** retention/pruning jobs delete expired rows of each class and preserve the audit decision fact.
- **Integration:** a deletion request removes sensitive content across task, steps, artifacts, and checkpoints, and the residue contains no sensitive payload.
- **Review:** no secret is committed to source control; `.gitignore` continues to exclude `.env` variants while permitting `.env.example`.
- **Review:** every persisted sensitive field is justified in `docs/DATABASE.md`.

## Open questions for the owner

1. What retention windows are acceptable for task payloads, prompts/completions, checkpoints, and audit records?
2. Is any raw prompt/completion retention permitted for evaluation, and under what scope and window?
3. Are there regulatory or contractual obligations (GDPR-style erasure, sector rules) that set hard requirements?
4. Must the *decision fact* of an approval survive an erasure request, or must it also be removed?
5. Is operator access to task content in scope, and must it be access-audited?

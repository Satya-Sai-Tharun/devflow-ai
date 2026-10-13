# Requirements Traceability

**Purpose:** Map every product requirement to the architecture that satisfies it, the test that will prove it, and the evidence required — so no requirement is silently dropped and no test is claimed without evidence.

**Status of this document:** Product requirements remain forward-looking. Milestone 1 adds partial foundation evidence for secret-safe configuration, health/readiness, and reproducible local setup; this does not satisfy broader product requirements.

The repository layout and local Compose workflow are developer infrastructure. They do not mark any product requirement below as met; frontend behavior remains unimplemented.

**Authoritative sources:** `PRD.md` (requirement text), `SPEC.md` (lifecycle and contract semantics), `ARCHITECTURE.md` (components). This document adds only the mapping and evidence expectations; where it appears to conflict with a source document, the source document wins.

---

## How to read this table

| Column | Meaning |
|---|---|
| **Req** | Requirement ID from `PRD.md` |
| **Requirement** | Condensed text; `PRD.md` is authoritative |
| **Components** | Where the behavior will be implemented |
| **Authoritative spec** | Document that defines the behavior in detail |
| **Required tests** | Test types that must exist before the requirement can be claimed met |
| **Evidence required** | Artifact that proves the requirement is satisfied |
| **Milestone** | Delivering milestone per `PLAN.md` |

**Evidence status legend:** `Not started` / `Partial` / `Met`. Product requirement rows below remain `Not started`; partial foundation evidence is recorded for applicable non-functional/security requirements.

---

## Functional requirements

### PR-001 — Task submission

| Field | Detail |
|---|---|
| **Requirement** | Authenticated clients can submit a task and receive `202 Accepted` plus a stable task identifier after durable acceptance. |
| **Components** | FastAPI task router; task domain; PostgreSQL `tasks` + `outbox`; CLI submit command; dashboard create form |
| **Authoritative spec** | `SPEC.md` § `POST /api/v1/tasks`; `docs/API_CONTRACTS.md` § 4.1 |
| **Required tests** | Unit: task creation invariants. Integration: `202` + stable ID returned; malformed payload rejected; unauthenticated rejected; **durable acceptance** — task and outbox row committed in one transaction; crash between commit and dispatch still executes the task. |
| **Evidence required** | Integration test output; the recorded commit→dispatch crash-recovery test result |
| **Milestone** | 3 (API), dependency on 5 (dispatch) |
| **Evidence status** | Not started |

### PR-002 — Task inspection

| Field | Detail |
|---|---|
| **Requirement** | Clients can retrieve the authoritative task state, timestamps, attempts, and permitted result details. |
| **Components** | FastAPI task router; PostgreSQL `tasks`, `task_attempts`; dashboard detail view; CLI status command |
| **Authoritative spec** | `SPEC.md` § `GET /api/v1/tasks/{task_id}`; `docs/API_CONTRACTS.md` § 4.2 |
| **Required tests** | Integration: snapshot matches persisted state; authorization enforced; cross-tenant access denied identically to not-found; internal sequential key never exposed. |
| **Evidence required** | Integration test output including the ID-exposure assertion |
| **Milestone** | 3 |
| **Evidence status** | Not started |

### PR-003 — Lifecycle integrity

| Field | Detail |
|---|---|
| **Requirement** | State transitions are validated centrally; invalid transitions are rejected and tested. |
| **Components** | Task domain (single transition function); PostgreSQL constraints as backstop |
| **Authoritative spec** | `SPEC.md` § Task lifecycle |
| **Required tests** | Unit: every allowed transition succeeds; **every disallowed transition is rejected**; terminal states cannot be reopened; blocked/needs_approval paths; actor/timestamp/from/to/reason recorded. |
| **Evidence required** | Unit test output covering the full transition matrix |
| **Milestone** | 2 |
| **Evidence status** | Not started |

### PR-004 — Shared API

| Field | Detail |
|---|---|
| **Requirement** | Dashboard and CLI use the same API contract and authorization rules. |
| **Components** | OpenAPI contract; generated/shared types; CLI HTTP client; dashboard API client |
| **Authoritative spec** | `ARCHITECTURE.md` § CLI; `docs/API_CONTRACTS.md` § 8.4 |
| **Required tests** | Integration: the same request issued from CLI and dashboard yields equivalent results; CLI contains no duplicated domain logic (review + no direct DB access from CLI). |
| **Evidence required** | Contract-generation step in CI; parity integration test output |
| **Milestone** | 3–4 |
| **Evidence status** | Not started |

### PR-005 — Background execution

| Field | Detail |
|---|---|
| **Requirement** | Long-running LangGraph workflows execute in a worker, independent of HTTP request lifetime. |
| **Components** | Worker process; dispatcher; LangGraph graph; agent adapters |
| **Authoritative spec** | `ARCHITECTURE.md` § Worker and LangGraph; `docs/AGENT_RUNTIME.md` |
| **Required tests** | Integration: submission returns before graph completion; worker consumes and completes the task; **API restart mid-task does not affect execution**; worker crash → lease expiry → reclaim → completion. |
| **Evidence required** | Integration test output; recorded evidence that no HTTP handler awaits graph execution |
| **Milestone** | 5 |
| **Evidence status** | Not started |

### PR-006 — Progress events

| Field | Detail |
|---|---|
| **Requirement** | Clients can receive task progress via SSE and recover by fetching the current task snapshot. |
| **Components** | SSE endpoint; persisted events; dashboard stream client; CLI follow command |
| **Authoritative spec** | `SPEC.md` § `GET /api/v1/tasks/{task_id}/events`; `docs/API_CONTRACTS.md` § 7 |
| **Required tests** | Integration: events delivered with monotonic IDs; `Last-Event-ID` reconnect replays missed events; snapshot fetch reconciles state after reconnect; authorization enforced at connect **and** reconnect; heartbeat observed on idle. |
| **Evidence required** | Integration test output for reconnect and replay |
| **Milestone** | 6 |
| **Evidence status** | Not started |

### PR-007 — Approval

| Field | Detail |
|---|---|
| **Requirement** | Tasks can pause for an explicit human decision before configured consequential operations. |
| **Components** | Approval endpoint; graph checkpoint pause/resume; tool gateway gate; dashboard approval UI |
| **Authoritative spec** | `SPEC.md` § `POST /api/v1/tasks/{task_id}/approval`; `docs/API_CONTRACTS.md` § 6; `docs/AGENT_RUNTIME.md` |
| **Required tests** | Integration: task pauses in `needs_approval`; **rejection transitions to `failed` with `terminal_reason=approval_rejected`**; **expiry transitions to `failed` with `terminal_reason=approval_expired`**; approval accepted only when a decision is pending; **unauthorized approver rejected**; **a tool call or model output cannot satisfy an approval**; **an expired approval permits no action and cannot resume the task**; approval is single-use and bound to its scope and state version; approval cannot be bypassed via the CLI path. |
| **Evidence required** | Integration + adversarial test output; recorded approval audit record |
| **Milestone** | 6–7 |
| **Evidence status** | Not started |

### PR-008 — Cancellation and timeout

| Field | Detail |
|---|---|
| **Requirement** | Supported tasks can be cancelled; deadlines and timeout outcomes are visible. |
| **Components** | Cancel endpoint; worker cancellation checks; deadlines/budget enforcement; task state |
| **Authoritative spec** | `SPEC.md` § cancel; `docs/API_CONTRACTS.md` § 5; `docs/AGENT_RUNTIME.md` § cancellation |
| **Required tests** | Integration: requested vs worker-confirmed cancellation are distinguishable; repeated cancel is idempotent; cancel on a terminal task is handled explicitly; timeout produces an honest distinguishable outcome. |
| **Evidence required** | Integration test output for both cancellation phases and timeout |
| **Milestone** | 6 |
| **Evidence status** | Not started |

### PR-009 — Verification

| Field | Detail |
|---|---|
| **Requirement** | Workflow results include verification status and test evidence when checks are run. |
| **Components** | Graph `verify` stage; verification result records; task result payload |
| **Authoritative spec** | `docs/AGENT_RUNTIME.md` § stages and evaluation |
| **Required tests** | Integration: verification pass and fail both recorded; a task cannot report `completed` in the "verified success" sense without a verification outcome; missing verification is surfaced, not silently treated as success. |
| **Evidence required** | Integration test output; a sample recorded verification result |
| **Milestone** | 5 |
| **Evidence status** | Not started |

### PR-010 — Tool governance

| Field | Detail |
|---|---|
| **Requirement** | Tool/MCP execution is allowlisted, validated, bounded, permissioned, and audited. |
| **Components** | Tool gateway; tool registry; sandbox; audit writer; MCP adapters |
| **Authoritative spec** | `docs/SECURITY.md`; `docs/THREAT_MODEL.md`; `docs/decisions/0009-tool-execution-sandbox.md` |
| **Required tests** | Integration: unregistered tool refused even when the model requests it; arguments schema-validated; timeout/output/memory limits enforced; sandbox write-scope enforced; egress default-deny verified; denials audited. Adversarial: prompt injection in repository content cannot trigger a privileged action. |
| **Evidence required** | Integration + adversarial test output; audit record samples |
| **Milestone** | 7 |
| **Evidence status** | Not started |

### PR-011 — Recovery

| Field | Detail |
|---|---|
| **Requirement** | Worker errors, retries, duplicate deliveries, and restarts do not silently corrupt lifecycle state. |
| **Components** | Outbox dispatcher; leases; idempotent step handlers; retry/backoff; dead-letter |
| **Authoritative spec** | `docs/decisions/0002-durable-job-dispatch.md`; `docs/AGENT_RUNTIME.md` § failure handling |
| **Required tests** | Integration: duplicate delivery produces exactly one effective transition; worker kill mid-job → reclaim → completion; retry exhaustion → dead-letter, never silent drop; checkpoint resume correctness; graceful shutdown releases leases. |
| **Evidence required** | Fault-injection test output; recorded at-least-once behaviour (never claimed as exactly-once) |
| **Milestone** | 5 |
| **Evidence status** | Not started |

### PR-012 — Observability

| Field | Detail |
|---|---|
| **Requirement** | Logs and metrics correlate API requests, tasks, attempts, workflow stages, and tool calls without leaking secrets. |
| **Components** | Structured logging; correlation IDs; metrics; tracing |
| **Authoritative spec** | `ARCHITECTURE.md` § 8; `docs/AGENT_RUNTIME.md` § observability |
| **Required tests** | Unit: redaction removes secret-shaped values from log/audit payloads. Integration: correlation ID propagates API→queue→worker→tool. Review: no secret material in logs. |
| **Evidence required** | Redaction unit test output; a traced task spanning all components |
| **Milestone** | 5, extended through 9 |
| **Evidence status** | Not started |

### PR-013 — Performance

| Field | Detail |
|---|---|
| **Requirement** | The project measures API latency, UI responsiveness, queue wait, and task execution separately. |
| **Components** | Instrumentation; benchmark tooling; timing breakdown |
| **Authoritative spec** | `docs/PERFORMANCE.md` (authoritative budgets and protocol) |
| **Required tests** | Performance: API p50/p95/p99 by endpoint class; queue wait; worker throughput; DB pool saturation; model/tool latency; frontend INP/LCP and bundle size. Each result must record environment, workload, concurrency, duration, percentiles, and command. |
| **Evidence required** | A recorded benchmark report meeting the `docs/PERFORMANCE.md` protocol. **No benchmark has been run yet; no budget is met or disproven.** |
| **Milestone** | 9 |
| **Evidence status** | Not started |

### PR-014 — CLI parity

| Field | Detail |
|---|---|
| **Requirement** | CLI supports core task submission, status, event/progress viewing, cancellation, and approval actions as authorized. |
| **Components** | Python CLI; shared HTTP client |
| **Authoritative spec** | `ARCHITECTURE.md` § CLI; `docs/API_CONTRACTS.md` |
| **Required tests** | Integration: each core command works against the live API; authorization failures surfaced clearly; CLI performs no direct database access and embeds no lifecycle rules. |
| **Evidence required** | Integration test output; review confirming no duplicated logic |
| **Milestone** | 3 |
| **Evidence status** | Not started |

### PR-015 — Usable UI states

| Field | Detail |
|---|---|
| **Requirement** | Dashboard includes loading, empty, success, error, reconnecting, approval-needed, and cancelled states. |
| **Components** | Dashboard routes/components; SSE client state machine |
| **Authoritative spec** | `Design-system.md` § Components and states |
| **Required tests** | Frontend: each state renders; keyboard navigation and focus; accessible names; reduced-motion respected; responsive layouts; SSE reconnect reconciliation. Automated accessibility checks. |
| **Evidence required** | Component/E2E test output; accessibility check results |
| **Milestone** | 4, extended in 6 |
| **Evidence status** | Not started |

---

## Non-functional requirements

### NFR-01 — Submission does not wait for execution

| Field | Detail |
|---|---|
| **Requirement** | Task submission remains fast and never awaits full graph execution. |
| **Authoritative spec** | `ARCHITECTURE.md` § 2 principle 1; `docs/PERFORMANCE.md` |
| **Required tests** | Integration: submission returns while the task is still non-terminal. Performance: submission p95 under the documented budget **with graph execution deliberately slow** (mock adapter with an injected delay). |
| **Evidence required** | Benchmark report including the slow-graph condition |
| **Milestone** | 5, measured in 9 |
| **Evidence status** | Not started |

### NFR-02 — Secret hygiene

| Field | Detail |
|---|---|
| **Requirement** | No secrets in source control, logs, error payloads, or model prompts. |
| **Authoritative spec** | `docs/SECURITY.md`; `docs/decisions/0006-data-retention-and-privacy.md` |
| **Required tests** | Unit: redaction. Integration: error responses never contain internal paths, stack traces, or credentials. Review: `.gitignore` excludes environment files while permitting `.env.example`; a secret scan runs in CI. |
| **Evidence required** | Secret-scan output; redaction test output |
| **Milestone** | 1, continuous |
| **Evidence status** | Partial - configuration error tests verify malformed/missing settings are rejected without exposing supplied credentials; broader secret hygiene is unverified |

### NFR-03 — Bounded resource consumption

| Field | Detail |
|---|---|
| **Requirement** | Execution time, concurrency, retries, output size, and spend are bounded. |
| **Authoritative spec** | `docs/AGENT_RUNTIME.md` § budgets; `docs/decisions/0005-model-provider-strategy.md` |
| **Required tests** | Integration: step/tool/token/time ceilings enforced; runaway loop terminated by the circuit breaker; concurrency limit respected under load. |
| **Evidence required** | Integration + load test output demonstrating each ceiling triggers |
| **Milestone** | 5, extended in 7 |
| **Evidence status** | Not started |

### NFR-04 — Reproducible setup

| Field | Detail |
|---|---|
| **Requirement** | A clean clone can be set up and its checks run reproducibly. |
| **Authoritative spec** | `docs/decisions/0007-runtime-and-package-managers.md`; `PLAN.md` Milestone 1 |
| **Required tests** | CI: clean-clone install from lockfiles succeeds; lint, type-check, and unit tests pass from a clean checkout. |
| **Evidence required** | Recorded CI run; documented setup commands that were actually executed |
| **Milestone** | 1 |
| **Evidence status** | Partial - locked install, unit checks, lint, formatting, type checking, and documented Windows commands were run; clean-clone CI evidence is absent |

### NFR-05 — Security controls are tested, not asserted

| Field | Detail |
|---|---|
| **Requirement** | No security control is claimed unless a test demonstrates it. |
| **Authoritative spec** | `docs/SECURITY.md` § review checklist; `docs/THREAT_MODEL.md` § security test plan |
| **Required tests** | The security test plan in `docs/THREAT_MODEL.md` maps each significant threat to a concrete test. |
| **Evidence required** | Completed security checklist with linked test evidence — currently **entirely unchecked** in `docs/SECURITY.md` |
| **Milestone** | Continuous; gate in 9 |
| **Evidence status** | Not started |

---

## Security requirements (SR-01 … SR-25)

`docs/THREAT_MODEL.md` § 7 defines 25 testable security requirements, each derived from one or more of the 46 identified threats. They are reproduced here **only as an index** so that a reviewer can see coverage at a glance; `docs/THREAT_MODEL.md` is authoritative for their text, derivation, and test plan.

Statuses below reflect the full security requirements, not just the foundation slice. SR-15 and SR-21 are **Partial** based on limited local evidence; other security requirements remain **Not started**.

| SR | Summary | Primary threat(s) | Milestone | Status |
|---|---|---|---|---|
| SR-01 | Every non-public endpoint authenticates in one shared dependency; a route without it fails closed | TM-S-01 | 3 | Not started |
| SR-02 | Per-task authorization on every read/stream/cancel/approve/result; `task_id` never confers authorization | TM-S-02, TM-I-01 | 3 | Not started |
| SR-03 | Cross-tenant isolation enforced at query time, never as a post-retrieval filter | TM-I-01, TM-AI-12 | 3 | Not started |
| SR-04 | Transitions validated centrally; only the domain function writes task state | TM-T-01 | 2 | Not started |
| SR-05 | Tool/MCP execution deny-by-default and allowlisted per task and stage | TM-E-02 | 7 | Not started |
| SR-06 | **Authorization derives solely from server-side policy; never from model, tool, MCP, retrieved, or repository content** | TM-E-01, TM-AI-06 | 3, 7 | Not started |
| SR-07 | Tool arguments schema-validated, with path scope enforced after normalization | TM-E-05 | 7 | Not started |
| SR-08 | Timeout, output-size, and argument-size bounds on every tool call; fail rather than truncate silently | TM-D-04, TM-E-02 | 7 | Not started |
| SR-09 | Security-relevant decisions audited append-only with actor/task/attempt/stage/outcome/correlation | TM-T-06, TM-R-03 | 5 | Not started |
| SR-10 | Shell and repo-modifying operations sandboxed; egress denied by default except allowlist | TM-E-03, TM-AI-07, TM-AI-08 | 7 | Not started |
| SR-11 | Consequential operations require a durable, single-use, scope-bound approval re-checked on resume | TM-E-06, TM-AI-14 | 6, 7 | Not started |
| SR-12 | Wall-clock deadlines, iteration bounds, retry budgets, tool-call ceilings enforced | TM-D-02, TM-D-05, TM-AI-09 | 5 | Not started |
| SR-13 | Per-task and per-tenant token/cost ceilings enforced before provider and tool calls | TM-AI-10 | 5 | Not started |
| SR-14 | Model/tool/MCP/retrieved/repository content treated as untrusted data, never in the instruction position | TM-AI-02, TM-AI-03, TM-AI-04 | 5, 7 | Not started |
| SR-15 | Secrets absent from tracked files, logs, and error envelopes; redacted at the logging boundary | TM-I-02 | 1 | Partial — configuration tests verify malformed/missing settings do not expose supplied credentials; broader tracked-file, logging, and redaction coverage remains unverified |
| SR-16 | Idempotent job handling; duplicate delivery yields exactly one recorded effect | TM-T-03 | 5 | Not started |
| SR-17 | Cancellation acceptance represented distinctly from worker-acknowledged `cancelled` | TM-R-02 | 6 | Not started |
| SR-18 | Request size/content-type/shape validated; submission, cancel, approve rate-limited | TM-D-01 | 3 | Not started |
| SR-19 | Checkpoints integrity-protected, deserialized via safe typed schemas, policy re-validated on resume | TM-T-02, TM-AI-11 | 5 | Not started |
| SR-20 | Verification derived only from executed checks; "not run" distinguished from "passed"; runs in sandbox | TM-T-05, TM-AI-07 | 5, 7 | Not started |
| SR-21 | Health/readiness endpoints leak no version, host, connection, or configuration detail | TM-I-06 | 3, 4 | Partial - generic `/healthz` and `/readyz` responses have unit and live outage evidence; full security requirement remains open |
| SR-22 | Least-privilege DB roles per component; no application role can modify or delete audit records | TM-I-05, TM-T-06 | 2 | Not started |
| SR-23 | Retention/deletion defined per artifact class with a working deletion path | TM-I-03 | 1, 9 | Not started — **blocked on ADR 0006** |
| SR-24 | Sandbox egress and hosted-provider use governed by explicit documented policy | TM-AI-07, TM-AI-08 | 7 | Not started — **blocked on ADR 0005/0009** |
| SR-25 | Approval surfaces distinguish platform vs model content; state action, scope, and effect; deduplicate | TM-AI-13, TM-AI-14 | 6 | Not started |

**Note on SR-23 and SR-24:** these two requirements cannot be implemented or verified until their governing decisions are **Accepted**. The related ADRs are currently **Proposed**, which is explicitly non-binding per `docs/decisions/README.md`.

---

## Coverage summary

Counts below treat `Delivered` and `Verified` as complete requirement acceptance; partial foundations are shown separately.

| Category | Count | Delivered | Partial | Verified |
|---|---:|---:|---:|---:|
| Functional requirements (PR-xxx) | 15 | 0 | 0 | 0 |
| Non-functional requirements (NFR-xx) | 5 | 0 | 2 | 0 |
| Security requirements (SR-xx, `docs/THREAT_MODEL.md`) | 25 | 0 | 2 | 0 |
| Identified threats (`docs/THREAT_MODEL.md`) | 46 | n/a | n/a | 0 mitigated |
| Security checklist items (`docs/SECURITY.md`) | 7 | 0 | 0 | 0 |
| Performance budgets (`docs/PERFORMANCE.md`) | 6 | n/a | n/a | **0 measured** |
| Owner decisions recorded as ADRs | 11 | n/a | n/a | 8 Accepted, 3 Proposed |

**Product feature requirements remain unimplemented.** The initial foundation provides partial evidence only for rows marked Partial; this does not satisfy full product or security requirements.

---
## Maintenance rules

1. **Update this table in the same change set** that implements or tests a requirement.
2. **Never mark a row `Met` without linked evidence** — a command output, a test report, or a recorded benchmark. A design document alone is not evidence.
3. When a requirement changes, update `PRD.md` first, then this table — not the reverse.
4. When a new requirement is added, add its row before implementing it.
5. If a requirement is dropped or deferred, record that decision in `docs/decisions/` rather than deleting the row.

## Related documents

- [`../PRD.md`](../PRD.md) — authoritative requirement text and acceptance criteria
- [`../SPEC.md`](../SPEC.md) — lifecycle and contract semantics
- [`../ARCHITECTURE.md`](../ARCHITECTURE.md) — component responsibilities
- [`../PLAN.md`](../PLAN.md) — milestone definitions and exit criteria
- [`TESTING.md`](TESTING.md) — test levels and quality gates
- [`SECURITY.md`](SECURITY.md) — security baseline and checklist
- [`THREAT_MODEL.md`](THREAT_MODEL.md) — threats, mitigations, and security test plan
- [`PERFORMANCE.md`](PERFORMANCE.md) — authoritative performance budgets and protocol

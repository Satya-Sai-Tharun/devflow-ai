# Development Plan

**Status:** Proposed sequencing. Reconcile with the actual repository and obtain owner approval before broad implementation.

## Working rules

- Treat `PRD.md` as product scope and acceptance criteria.
- Treat `ARCHITECTURE.md` as a proposed design until decisions are confirmed.
- Do not start broad implementation while material scope/security decisions remain unresolved.
- Each milestone needs acceptance criteria, tests, and a clear handoff.
- Update `.agent-state/CURRENT.md` when the active milestone or verified repository state changes.

## Milestone 0 — Documentation and decisions

- [x] Capture product, architecture, agent, security, style, design-system, and testing guidance in a reviewable draft.
- [ ] Confirm PRD, non-goals, and MVP acceptance criteria.
- [ ] Confirm the actual current repository tree and reconcile these drafts with existing files.
- [ ] Resolve or explicitly defer key MVP decisions.

**Exit criteria:** Owner-reviewed source-of-truth documents; conflicts and open decisions visible.

## Milestone 1 — Repository and developer foundation

- Inspect the actual application stack, dependency management, and current code.
- Establish or verify setup, formatting, lint, type-check, and test commands.
- Add a minimal CI baseline if requested and compatible with the repo.
- Establish environment examples and secret-handling guidance.

**Exit criteria:** Reproducible local setup and verified baseline checks.

## Milestone 2 — Core task domain

- Define task schema, acceptance criteria, status model, and allowed transitions.
- Implement validation and persistence selected by owner.
- Add unit tests for lifecycle invariants and invalid transitions.

**Exit criteria:** Task records and state transitions are test-covered.

## Milestone 3 — Workflow orchestration

- Implement a minimal LangGraph workflow with explicit state and bounded transitions.
- Separate planning, execution, verification, and final reporting.
- Add timeout, cancellation, retry, and failure paths.

**Exit criteria:** End-to-end workflow tests demonstrate success and failure paths.

## Milestone 4 — Controlled tools and MCP

- Define tool allowlist and adapter contract.
- Add schema validation, permissions, audit events, and execution constraints.
- Add approval gates for consequential operations.

**Exit criteria:** Disallowed calls and approval bypass attempts are blocked by tests.

## Milestone 5 — Project context and retrieval

- Load repository instructions and relevant files.
- Add retrieval only after selecting data sources and indexing strategy.
- Treat retrieved content as untrusted and test prompt-injection resistance.

**Exit criteria:** Relevant context is traceable and cannot override trusted policy.

## Milestone 6 — Audit and human oversight

- Persist task events, approvals, tool outcomes, and verification evidence.
- Implement pause/resume and rejected-approval behavior.
- Ensure reports distinguish actual evidence from model claims.

**Exit criteria:** Approval lifecycle and audit history are tested.

## Milestone 7 — Evaluation and observability

- Build a versioned evaluation set and explicit scoring criteria.
- Track completion, policy compliance, verification quality, failures, and latency/cost where available.
- Establish a baseline before optimization.

**Exit criteria:** Results are reproducible and do not rely solely on model self-assessment.

## Milestone 8 — Interface

- Confirm CLI/web interface and user workflows.
- Implement shared components using `Design-system.md`.
- Add responsive, keyboard, focus, loading, empty, and error states.

**Exit criteria:** Core task lifecycle is usable and accessibility checks are recorded.

## Milestone 9 — Hardening and release readiness

- Review security boundaries, dependency posture, logs, retention, and deployment configuration.
- Run functional, integration, security, and evaluation suites.
- Document known limitations and rollback/recovery approach.

**Exit criteria:** Release checklist completed with evidence; unresolved risks accepted by the owner.

## Open decisions blocking detailed implementation

- MVP interface and authentication model.
- First agent adapter and MCP tool/server allowlist.
- Persistence, sandboxing, retrieval, and deployment technologies.
- Evaluation dataset and release thresholds.

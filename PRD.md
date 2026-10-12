# Product Requirements Document (PRD)

**Product:** DevFlow AI  
**Status:** Draft — product decisions requiring owner confirmation are marked **Open decision**.  
**Purpose:** The source of truth for what DevFlow AI should do, who it serves, and how success is measured.

## 1. Product statement

DevFlow AI is an agentic software-engineering platform that coordinates AI coding agents and controlled tools to help developers plan, implement, verify, and review software changes with traceable evidence and human oversight.

## 2. Problem and opportunity

Developers using AI coding agents must often provide context repeatedly, coordinate multiple tools manually, verify generated changes, and keep security and quality requirements consistent. Unrestricted automation can also make unsafe changes or report success without sufficient evidence.

DevFlow AI aims to provide a consistent workflow, project context, constrained tool access, explicit approval gates, and verification records around agent-assisted engineering.

## 3. Target users

- **Primary:** Individual developers and engineering teams using AI coding agents.
- **Secondary:** Technical leads and reviewers who need visibility into task progress, decisions, risks, and verification.
- **Potential future users:** Platform and security teams that need policy-controlled agent execution.

## 4. User needs

- Define a task with a clear goal and acceptance criteria.
- Give agents relevant repository and project context.
- Route work through explicit, observable workflow stages.
- Limit tool access and require approval for consequential actions.
- Verify changes with actual test and review evidence.
- Inspect task history, failures, approvals, and final results.

## 5. Goals

1. Make agent-assisted engineering workflows reproducible and observable.
2. Keep task scope, project instructions, and acceptance criteria available throughout execution.
3. Make tool execution permissioned, auditable, and constrained.
4. Require evidence before reporting a task as complete.
5. Support evaluation of workflow quality independently from a successful-looking agent response.

## 6. Must-have functional requirements

Requirements are testable; implementation details belong in `ARCHITECTURE.md`.

- **PR-001 — Task definition:** A task records its goal, context, acceptance criteria, constraints, and status.
- **PR-002 — Explicit lifecycle:** A task moves only through defined, validated workflow states. Invalid transitions are rejected and recorded.
- **PR-003 — Project instructions:** Before editing, the workflow loads the applicable `AGENTS.md` and project documentation.
- **PR-004 — Planning and execution:** The workflow separates task understanding/planning from implementation and verification.
- **PR-005 — Context retrieval:** Retrieved repository or knowledge-base content is identified as untrusted input and cannot override system or project policy.
- **PR-006 — Controlled tools:** Tool calls go through a policy-enforcing gateway with validated arguments, least privilege, and an allowlist.
- **PR-007 — Human approval:** Consequential, destructive, external, or otherwise policy-gated actions require explicit approval before execution.
- **PR-008 — Verification evidence:** The system records which checks were run and their actual results. It never claims a test passed when it was skipped, blocked, or not run.
- **PR-009 — Audit history:** Task status changes, tool calls, approval decisions, failures, and verification results are traceable.
- **PR-010 — Failure handling:** Failures and timeouts are surfaced clearly; the workflow does not silently convert them into success.
- **PR-011 — Final report:** The result summarizes changes, checks, outstanding risks, and anything not verified.
- **PR-012 — Evaluation:** Agent/workflow evaluation uses explicit criteria and recorded evidence rather than the agent's self-assessment alone.

## 7. Non-goals

- Unrestricted autonomous control of a developer's machine or production environment.
- Arbitrary shell execution without policy checks or isolation.
- Automatic production deployment, destructive actions, or merges without the required approval.
- Guaranteeing that generated code is correct, secure, or free of defects.
- Replacing human ownership of architecture, product scope, or risk acceptance.
- Treating retrieved documents, issue text, repository comments, or model output as trusted policy.
- Supporting every coding agent, tool provider, or deployment target in the first release.

## 8. MVP scope

The MVP should demonstrate one end-to-end task lifecycle: define task → load project context → plan → propose/execute permitted changes → run verification → request approvals where needed → produce an evidence-based report.

Candidate MVP capabilities:
- Task and acceptance-criteria representation.
- LangGraph-based workflow orchestration.
- One initially supported coding-agent integration, selected after an explicit decision.
- A small allowlisted set of tools behind a policy gateway.
- Human approval for policy-gated actions.
- Basic audit/event history and verification reporting.
- Automated tests for lifecycle invariants and tool-policy enforcement.

These are intended MVP requirements, not claims that these capabilities already exist.

## 9. Constraints and assumptions

- Repository instructions and secrets must be respected.
- Secrets are supplied through environment variables or an approved secret manager, never committed.
- Tool execution must be constrained and must fail closed when policy cannot be evaluated.
- Tests and command results must be reported truthfully.
- The repository's actual stack and existing implementation must be inspected before choosing commands or making structural changes.
- **Open decision:** Interface for the MVP (CLI, web UI, or both).
- **Open decision:** Authentication and authorization model.
- **Open decision:** First coding-agent adapter and supported MCP servers/tools.
- **Open decision:** Persistence layer, deployment target, sandbox technology, and evaluation metrics.

## 10. Success measures

The following are proposed measurements; numeric targets should be agreed before a release:
- Percentage of tasks with complete acceptance criteria and a recorded final report.
- Percentage of completion claims backed by recorded verification evidence.
- Rate of invalid or unauthorized tool calls blocked by policy.
- Rate of successful workflow completion on a maintained evaluation set.
- Human approval latency and frequency of approval-required actions.
- Regression rate and severity of defects found after agent-generated changes.
- Reproducibility of evaluation results across repeated runs.

## 11. Acceptance criteria for the MVP

The MVP is acceptable when:
1. A user can submit a task with acceptance criteria and constraints.
2. The workflow follows a documented state machine and rejects invalid transitions.
3. Project instructions are loaded before code-editing steps.
4. Tool calls are validated against a configured allowlist and permissions.
5. A policy-gated action cannot execute before approval.
6. The task record contains the actual verification results and final status.
7. A failed, skipped, or unrun check is not reported as passed.
8. Automated tests cover the critical lifecycle, approval, and tool-policy rules.
9. The README documents setup and the verified development/test commands.
10. Remaining limitations and open decisions are disclosed.

## 12. Release and change control

Changes to target users, MVP scope, non-goals, security boundaries, or acceptance criteria require explicit product-owner review. Update this document when requirements change, and update `ARCHITECTURE.md`, `PLAN.md`, and tests when the change affects design or implementation.

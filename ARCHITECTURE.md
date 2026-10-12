# Architecture

**Product:** DevFlow AI  
**Status:** Proposed logical architecture. This document does not assert that the described components are already implemented.  
**Purpose:** Explain system boundaries, data flow, and where changes belong.

## 1. Architecture overview

DevFlow AI is intended to orchestrate agent-assisted software tasks through explicit workflow states, controlled tools, project context, verification, and human approval.

Conceptual flow:

`User / CLI / UI → Task API → LangGraph workflow → Context + Agent adapters → Tool policy gateway → Isolated execution → Verification → Audit/result store → Final report`

The final component boundaries and deployment topology remain open until the repository implementation and MVP decisions are confirmed.

## 2. Proposed component responsibilities

| Component | Responsibility |
|---|---|
| Entry point / UI | Collect task goal, constraints, acceptance criteria, and approval decisions |
| Task/API layer | Validate requests, enforce identity/authorization, expose task status |
| Workflow orchestrator | Manage state transitions, retries, branching, approvals, and verification stages |
| Agent adapters | Normalize interactions with supported coding agents and model providers |
| Context service | Load project instructions and retrieve relevant repository/knowledge context |
| Tool policy gateway | Validate tool identity, arguments, permissions, and approval requirements |
| Execution boundary | Run permitted commands or code operations in a constrained environment |
| Approval service | Pause workflow until an authorized human approves or rejects a gated action |
| Verification service | Run configured checks and record actual outcomes |
| Persistence/audit | Store task state, events, approvals, tool results, and verification evidence |
| Evaluation/observability | Measure workflow outcomes, latency, failures, and evaluation-set performance |

These are logical boundaries, not a mandate to create a separate service for each row. Prefer the simplest deployable structure that preserves security boundaries.

## 3. Repository structure

Use the existing repository layout as the source of truth. The following is a target responsibility map, not a claim that every directory currently exists:

- `app/` or the established application source directory — runtime application code.
- `tests/` — automated tests, fixtures, and test helpers.
- `docs/` — security, testing, design, and operational documentation.
- `.agent-state/` — concise coordination state for multi-agent work; do not store secrets.
- `.agents/skills/` — reusable agent skills and their references.
- `.github/` — repository automation and Copilot instructions.
- `README.md` — project entry point, setup, verified commands, and links to core docs.
- `PRD.md` — product scope and acceptance criteria.
- `ARCHITECTURE.md` — system boundaries and data flow.
- `PLAN.md` — milestones and sequencing.
- `AGENTS.md` — instructions for coding agents.

Before creating or renaming directories, inspect the current tree and preserve established conventions.

## 4. Data flow

1. A user submits a task with goal, acceptance criteria, and constraints.
2. The API validates the request and creates a task record.
3. The workflow loads repository instructions and relevant context.
4. The planning stage proposes a bounded plan and identifies uncertainties.
5. The workflow invokes only configured agent adapters and policy-approved tools.
6. A gated action pauses for explicit human approval before execution.
7. Permitted operations run inside the selected execution boundary.
8. Verification runs configured checks and records command, exit status, and result classification.
9. The workflow updates task state and writes an audit trail.
10. The final report separates completed work, verified claims, failures, skipped checks, and unresolved risks.

The source of truth for task state should be the task/workflow record, not a UI-only local state. The exact persistence technology is an open decision.

## 5. State and trust boundaries

- Treat user prompts, repository files, issue descriptions, retrieved documents, logs, and agent outputs as potentially untrusted.
- Retrieved content may inform task execution but must not override system policy, authorization, or project safety rules.
- Tool policy must be enforced outside the language model's judgment.
- Validate tool arguments at the gateway and again at sensitive execution boundaries where appropriate.
- Use least-privilege credentials and narrowly scoped permissions.
- Fail closed if authorization or policy evaluation is unavailable.
- Require approval for consequential actions as defined in `docs/SECURITY.md`.
- Do not expose secrets in prompts, logs, traces, or final reports.

## 6. Integrations

Potential integrations identified by the project direction:
- LangGraph for workflow orchestration.
- MCP for standardized tool integration.
- Coding-agent adapters such as Codex, Claude Code, or OpenCode.
- Retrieval and vector search for relevant project context.
- Model providers and evaluation tooling.

These are candidate integrations, not proof that each is wired into the current codebase. Confirm supported providers, MCP servers, storage engines, and deployment targets before implementation. Maintain an explicit allowlist.

## 7. Architectural patterns

Prefer:
- Explicit task state machines and typed workflow state.
- Small modules with clear responsibilities.
- Adapter interfaces for model and tool providers.
- Policy checks outside model-generated decisions.
- Structured logs and auditable events.
- Idempotent operations where retries are possible.
- Timeouts, bounded retries, cancellation, and clear failure propagation.
- Tests for security and workflow invariants.

Avoid:
- Letting model output directly authorize privileged actions.
- Unbounded autonomous loops or unlimited retries.
- Broad shell access by default.
- Hidden state changes or silent failure-to-success conversions.
- Duplicated provider-specific logic across the orchestration core.
- Introducing distributed services before there is a demonstrated need.

## 8. Adding a feature

1. Read `PRD.md`, this document, `AGENTS.md`, `docs/SECURITY.md`, `docs/TESTING.md`, and `CODE_STYLE.md`.
2. Inspect the repository, current Git state, existing interfaces, and related tests.
3. Check `.agent-state/ACTIVE-TASK.md` and coordinate with other agents before editing shared files.
4. Define the user-visible behavior and acceptance criteria; ask for clarification if scope is ambiguous.
5. Identify affected components, data flow, permissions, failure modes, and migration needs.
6. Implement the smallest cohesive change using established patterns.
7. Add or update unit, integration, workflow, and security tests as appropriate.
8. Run relevant checks and record the exact commands and outcomes.
9. Update docs if architecture, security boundaries, setup, or behavior changed.
10. Report files changed, evidence, skipped checks, and remaining risks.

## 9. Failure handling and observability

Represent errors explicitly, preserve useful diagnostic context without leaking secrets, and distinguish retryable from non-retryable failures. Record workflow transitions, policy decisions, approval outcomes, tool invocation metadata, and verification results. Avoid logging raw secrets or unnecessary sensitive input.

## 10. Open architecture decisions

- CLI, web UI, or both for MVP.
- Authentication and authorization model.
- Task/event persistence and schema.
- Initial agent adapter and supported MCP server/tool allowlist.
- Sandbox/execution isolation mechanism.
- RAG index and retrieval strategy.
- Deployment target and secret-management approach.
- Evaluation dataset, quality thresholds, and observability stack.

Record material decisions as ADRs or in this section; do not silently treat proposals as approved implementation choices.

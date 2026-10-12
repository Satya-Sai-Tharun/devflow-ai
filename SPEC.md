# Technical Specification

**Product:** DevFlow AI  
**Status:** Proposed technical requirements; implementation choices remain subject to confirmation.  
**Relationship:** `PRD.md` defines product requirements and acceptance criteria. This document translates them into technical behavior. `ARCHITECTURE.md` describes the proposed component boundaries.

## 1. Scope

The system should support a traceable software-task lifecycle: task intake, context loading, planning, controlled execution, approval pauses, verification, and evidence-based reporting.

This specification is not a claim that these capabilities are implemented.

## 2. Core entities

Proposed domain records:
- **Task:** identifier, goal, context references, acceptance criteria, constraints, current status, timestamps.
- **Workflow run:** task reference, workflow version, current stage, run status, timing, failure information.
- **Tool invocation:** tool identifier, validated arguments or sanitized summary, authorization decision, approval reference if required, execution status, result metadata.
- **Approval:** requested action and scope, requester, decision, approver, timestamp, expiration or invalidation information.
- **Verification result:** check name, command or check identifier, status classification, exit status when applicable, timestamps, and sanitized output reference.
- **Audit event:** event type, actor/source, task/run reference, timestamp, and non-secret metadata.

Field-level schemas, storage engine, retention, and migration strategy are open decisions.

## 3. Workflow contract

1. Validate the task request and required acceptance criteria.
2. Load applicable project instructions and bounded context.
3. Create a workflow run with an explicit initial state.
4. Produce a plan and identify ambiguities or approval requirements.
5. Invoke only registered agent adapters and allowlisted tools.
6. Validate every tool call independently of model output.
7. Pause when an approval policy applies; resume only after a valid decision.
8. Run configured verification checks and record actual outcomes.
9. Derive completion status from workflow state and required evidence, not from a free-form model statement.
10. Produce a final report with changes, verification, limitations, and unresolved risks.

## 4. State and result semantics

Use explicit, validated state transitions. The exact state names should be agreed during implementation; likely task states include `queued`, `running`, `needs_approval`, `completed`, `failed`, `cancelled`, and `blocked`.

Verification results must distinguish:
- `PASS`
- `FAIL`
- `SKIPPED`
- `NOT RUN`
- `BLOCKED`
- `INCONCLUSIVE`

A required check that is failing, blocked, inconclusive, skipped, or not run must not be represented as passed. If the product permits completion with unrun checks, the report must explicitly disclose that limitation and the completion policy must be approved.

## 5. Tool gateway contract

Each registered tool should declare:
- Stable name and version.
- Purpose and permitted capabilities.
- Input schema and validation rules.
- Required permissions and approval policy.
- Timeout, retry, and output-size limits.
- Execution environment and filesystem/network access.
- Audit metadata and error mapping.

Unknown tools, invalid arguments, denied permissions, unavailable policy decisions, and missing approvals must fail closed. Tool outputs are untrusted data.

## 6. Context and retrieval contract

- Load project-level instructions before editing.
- Track the source of retrieved context where practical.
- Apply size limits and relevance filters.
- Keep retrieved content separate from trusted policy.
- Do not allow retrieved text to grant permissions, alter tool policy, or override trusted instructions.
- Avoid passing secrets or irrelevant private data to external model providers.

## 7. Observability and reporting

Record state transitions, policy decisions, approval decisions, tool outcomes, retries, timeouts, and verification results. Logs and traces must be sanitized.

The final report should include:
- Task outcome and concise summary.
- Files or artifacts changed when known.
- Checks run and their exact status.
- Approvals requested and decisions.
- Checks not run or blocked.
- Known risks, assumptions, and follow-up work.

## 8. Reliability requirements

- Bound retries and agent iteration counts.
- Apply timeouts to external calls and tool execution.
- Support cancellation where the execution mechanism permits it.
- Make retryable operations idempotent where feasible.
- Preserve failure context and do not silently convert exceptions into success.
- Define behavior for process restart and interrupted approvals before production use.

## 9. Testing requirements

Implement tests for:
- Task validation and state transitions.
- Workflow success and failure paths.
- Tool allowlist and argument validation.
- Approval required, rejected, expired, and mismatched cases.
- Context prompt-injection attempts.
- Timeout, retry, cancellation, and policy-service failure.
- Verification-result aggregation and final-report truthfulness.
- Authorization and secret redaction.

See `docs/TESTING.md` and `docs/SECURITY.md`.

## 10. Open technical decisions

- API and UI/CLI framework.
- Authentication and authorization implementation.
- Persistence and event/audit storage.
- Coding-agent adapters and model providers.
- MCP servers and tool allowlist.
- Sandbox/execution isolation technology.
- Retrieval/indexing/vector-store implementation.
- Deployment, secret management, telemetry, and evaluation stack.

Resolve decisions through explicit owner approval and update this document, `ARCHITECTURE.md`, and relevant tests.

# Testing Strategy

**Status:** Test strategy baseline. Exact commands must be taken from the actual repository and marked verified only after execution.

## 1. Objectives

Verify functional behavior, workflow invariants, tool permissions, failure handling, and truthful reporting. An agent's assertion that work is correct is not a substitute for independent checks.

## 2. Test layers

### Unit tests
Test pure functions, input validation, task-state transitions, policy decisions, serialization, and error classification.

### Integration tests
Test interactions between the workflow engine, persistence, agent adapters, context retrieval, tool gateway, and verification service using controlled fixtures or test doubles where appropriate.

### End-to-end tests
Exercise a representative task from submission through planning, approval pause/resume, verification, and final report.

### Security tests
Cover the cases listed in `docs/SECURITY.md`, including unauthorized access, disallowed tools, prompt injection, approval bypass, path traversal, and secret leakage.

### Agent/workflow evaluations
Use a versioned set of representative tasks with explicit expected properties. Measure correctness, acceptance-criteria coverage, tool-policy compliance, verification quality, cost/latency where available, and failure modes. Keep evaluation criteria separate from model self-reports.

## 3. Workflow invariants

- Only documented state transitions are accepted.
- A task cannot be marked complete when required verification is failing, blocked, or not run.
- A gated action cannot execute before a valid approval.
- Denied tool calls cannot reach the execution layer.
- Retry limits and timeouts are enforced.
- Audit events preserve the sequence of important decisions.
- Final reports distinguish verified facts from assumptions and unresolved risks.

## 4. Test design

- Include success, invalid input, empty state, error, timeout, cancellation, permission denial, and retry cases.
- Prefer deterministic fixtures and isolated temporary workspaces.
- Mock external providers for unit tests; classify live-provider tests as integration tests.
- Keep tests independent of secret credentials.
- Add regression tests for every fixed defect that can be reproduced.
- Avoid asserting only that a model produced plausible text; assert structured outcomes and policy invariants.

## 5. Result classifications

Use these labels in task reports:
- **PASS:** Command completed successfully and evidence supports the check.
- **FAIL:** Check ran and failed.
- **SKIPPED:** Intentionally not run under the current test selection.
- **NOT RUN:** Not executed.
- **BLOCKED:** Could not execute because of a dependency, permission, environment, or external blocker.
- **INCONCLUSIVE:** Ran but did not provide enough evidence to determine the outcome.

Never aggregate skipped, blocked, or inconclusive checks into a passing result.

## 6. Running tests

Before documenting commands:
1. Inspect package/dependency manifests, test configuration, CI workflows, and README.
2. Use the existing supported commands and versions.
3. Run the narrowest relevant test first, then broader checks if feasible.
4. Record the exact command and observed outcome.
5. Document environment prerequisites and any unavailable integration tests.

No commands are specified here because the actual repository stack and configured scripts must be inspected before declaring them valid.

## 7. Continuous integration

Where CI is configured, run deterministic unit and policy tests on each change. Add integration and security checks according to their runtime and environment needs. Keep secrets out of pull-request logs and use least-privilege CI credentials.

## 8. Definition of done

- Relevant tests added or updated.
- Relevant checks run, with exact results recorded.
- Failures fixed or explicitly reported.
- Skipped or blocked checks clearly identified.
- Security-sensitive paths and negative cases considered.
- Documentation and acceptance criteria updated when behavior changes.

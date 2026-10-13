# Security Baseline

This is a design baseline, not a claim that controls are already implemented or independently audited.

**Scope of this document vs [`THREAT_MODEL.md`](THREAT_MODEL.md):** this file is the concise baseline and review checklist. [`THREAT_MODEL.md`](THREAT_MODEL.md) is authoritative for the full analysis — assets, trust boundaries, STRIDE and AI-specific threats, the 25 testable security requirements (`SR-01`…`SR-25`), and the threat-to-test plan. Where this checklist is terse, the threat model carries the reasoning and the verification method. Neither document may weaken the other.

## Identity and authorization
- Authenticate every non-public API endpoint.
- Authorize every task read, event stream, cancellation, approval, and result access against the caller and tenant/project boundary.
- Do not rely on opaque task IDs as authorization.
- Rate-limit task submission and sensitive actions.

## Secrets and data handling
- Keep provider keys, database credentials, and tokens outside source control.
- Use environment variables for local development and a secret manager for deployed environments.
- Provide `.env.example` with placeholders only; never copy real values.
- Redact secrets and sensitive payloads from logs.
- Define retention and deletion behavior for prompts, repository content, checkpoints, results, and audit events before production.

## Agent and tool boundaries
- Treat model output, user prompts, repository files, retrieved documents, and tool output as untrusted.
- Deny tool access by default; use explicit allowlists and least privilege.
- Validate tool names and arguments against schemas.
- Enforce timeouts, output limits, concurrency limits, and filesystem/network restrictions.
- Run shell or repository-modifying operations in a restricted sandbox, not with unrestricted host privileges.
- MCP servers are privileged integrations: review their identity, permissions, transport, credentials, and allowed methods.
- Require human approval for configured consequential actions; record actor, decision, timestamp, and scope.
- Retrieved content can inform a decision but cannot grant permissions or override system policy.

## API and worker safety
- Validate request size, content type, parameters, and payload shape.
- Apply task ownership checks to SSE connections and reconnects.
- Use explicit cancellation semantics; do not imply that a cancellation request means execution has already stopped.
- Design retries and duplicate delivery for idempotency.
- Bound worker concurrency, execution duration, model/tool spend where possible, and result sizes.
- Protect health and operational endpoints appropriately.

## Audit and incident readiness
- Record security-relevant decisions and tool invocations with correlation IDs.
- Avoid storing raw sensitive content in audit records unless justified and governed.
- Keep enough event history to investigate failures and approvals.
- Define incident response, credential rotation, and data deletion procedures before production use.

## Security review checklist

Each item maps to a testable requirement in [`THREAT_MODEL.md`](THREAT_MODEL.md). All items remain **unchecked** because each checklist item covers broader product controls than this initial API foundation. Local tests provide limited evidence for secret-safe configuration errors and generic health/readiness responses; authentication, authorization, tool restrictions, sandboxing, approval gates, and product resource limits remain unimplemented or unverified. See [`REQUIREMENTS_TRACEABILITY.md`](REQUIREMENTS_TRACEABILITY.md) for partial evidence status.

- [ ] Authentication and authorization tests cover task and SSE access. → `SR-01`, `SR-02`, `SR-03`
- [ ] Secrets are absent from tracked files and logs. → `SR-15`
- [ ] Tools are deny-by-default and permission-scoped. → `SR-05`, `SR-06`, `SR-07`
- [ ] Sandbox restrictions are tested. → `SR-10`, `SR-24`
- [ ] Approval gates cannot be bypassed through alternate API/CLI paths. → `SR-11`, `SR-25`
- [ ] Request, execution, concurrency, and output limits are enforced. → `SR-08`, `SR-12`, `SR-13`, `SR-18`
- [ ] Retention and deletion policy is documented. → `SR-23`

For every item, the corresponding row in [`REQUIREMENTS_TRACEABILITY.md`](REQUIREMENTS_TRACEABILITY.md) must link to real evidence before it is checked.

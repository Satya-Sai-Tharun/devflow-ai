# Security Baseline

This is a design baseline, not a claim that controls are already implemented or independently audited.

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
- [ ] Authentication and authorization tests cover task and SSE access.
- [ ] Secrets are absent from tracked files and logs.
- [ ] Tools are deny-by-default and permission-scoped.
- [ ] Sandbox restrictions are tested.
- [ ] Approval gates cannot be bypassed through alternate API/CLI paths.
- [ ] Request, execution, concurrency, and output limits are enforced.
- [ ] Retention and deletion policy is documented.

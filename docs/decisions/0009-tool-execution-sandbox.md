# 0009. Tool execution sandbox and permission model

- **Status:** **Proposed** — required before any real tool or MCP integration (Milestone 7)
- **Date:** 2026-10-12
- **Deciders:** project owner (decision required); agent recommendation
- **Related requirements:** PR-010, PR-007, PR-009
- **Related documents:** `docs/SECURITY.md` § Agent and tool boundaries, `docs/THREAT_MODEL.md`, `docs/AGENT_RUNTIME.md` § Tool invocation, `ARCHITECTURE.md` § Tool gateway and MCP

## Context

DevFlow AI's purpose requires agents to read repositories, run tests, and modify code. That is precisely the capability that makes the platform dangerous: agent-proposed shell commands may be malformed or adversarially influenced by prompt injection in repository files; tool arguments may be crafted to escape an intended scope; and an agent with network access can exfiltrate proprietary source.

`ARCHITECTURE.md` requires the tool gateway to be "the policy boundary" with "explicit tool allowlist, schemas, authorization, timeouts, output-size limits, and audit events", and to "never expose arbitrary host shell access to an agent by default". `docs/SECURITY.md` adds deny-by-default, least privilege, and sandboxed execution for shell and repository-modifying operations.

This is the highest-severity area of the system: it is where untrusted model output meets real-world side effects. It is deferred to Milestone 7 but must be decided before that milestone starts, because retrofitting isolation onto host-privileged execution is extremely difficult.

## Decision (recommended)

1. **Deny by default.** A tool that is not explicitly registered, allowlisted, and enabled for the requesting tenant/context is unavailable. Absence of a rule is denial, never permission.
2. **Authorization is server-side and independent of the model.** The effective permission decision is computed by the gateway from policy and the authenticated principal. **Model output, tool output, retrieved documents, and repository content can never grant, widen, or satisfy a permission** — they may only request. A tool call naming a capability is a request, not an entitlement.
3. **Sandbox every operation with side effects or untrusted input.** Recommended posture for the MVP: run agent-initiated commands and code modification inside a container with a read-only base, a single mounted project workspace, no host socket, dropped Linux capabilities, a non-root user, and a **default-deny egress policy** with an explicit allowlist for any required endpoint.
4. **Bound everything:** per-call timeout, total wall-clock budget, maximum output bytes captured, maximum process count, maximum memory, maximum concurrent tool calls, and read/write scope limited to the mounted workspace.
5. **Validate arguments against an explicit schema** before execution, and treat tool *results* as untrusted data on return — delimited clearly so they cannot be mistaken for instructions by a subsequent model step.
6. **Approval gates for consequential operations** are enforced by the gateway, not requested politely of the model. A gated action cannot execute on model intent alone; it requires an authorized human decision recorded with actor, timestamp, and scope.
7. **Audit every invocation** with tool name, arguments digest, decision, actor/principal, duration, outcome, and correlation ID — without persisting raw sensitive content by default.
8. **MCP servers are privileged integrations.** Each requires review of identity, permissions, transport, credentials, allowed methods, and trust level; MCP-provided tool descriptions are untrusted input, not policy.

## Alternatives considered

- **Direct host shell execution with an allowlist of commands.** Simplest to build, and the most common shortcut. Rejected: command allowlists are notoriously bypassable, and a single parsing or quoting defect yields full host compromise. Host privilege must not be the blast radius.
- **Subprocess with `cwd` restriction only (no container).** Rejected: filesystem and network isolation cannot be enforced this way on a shared host.
- **MicroVM-based isolation (Firecracker-class).** Stronger isolation than containers. Deferred as disproportionate operational cost for the MVP; a reasonable upgrade path if the threat model warrants it or if untrusted third-party code must run.
- **Kernel-level sandboxing (seccomp/AppArmor profiles) without containers.** Adds real value as defense-in-depth and is worth layering, but alone it is harder to reason about and to port across hosts than a container boundary.
- **Full network egress with URL allowlisting only.** Rejected as the primary control: allowlists over HTTP are bypassable via redirects, DNS, and alternate endpoints. Default-deny egress is the safer baseline.
- **Approval prompt to the model ("ask the model to confirm").** Rejected outright: a model cannot authorize its own action. This is the precise failure the design must prevent.
- **No sandbox for local development.** Acceptable only as an explicitly labeled, opt-in developer mode with a clear warning — never the default, and never in CI.

## Consequences

**Positive:** contains the blast radius of prompt injection and malformed commands; makes egress exfiltration materially harder; produces a defensible audit trail for every consequential action; keeps the human approval gate meaningful.

**Negative / accepted costs:** significant implementation and operational effort; container runtime required in development and CI; legitimate workflows may need explicit network allowlist entries, which is friction by design; some tooling may behave differently inside the sandbox and require documented workarounds.

**Residual risks (must be documented honestly, not claimed solved):** a container escape is catastrophic if it occurs; side-channel leakage may persist despite egress control; and a workload with legitimate network permission can still exfiltrate within that permission. Approval fatigue may cause users to rubber-stamp prompts — mitigation is calibrated approval scope, not more prompts.

## Verification

- **Security/integration:** an unregistered tool is refused even when the model explicitly requests it.
- **Security/integration:** a tool call attempting to write outside the mounted workspace fails and is recorded.
- **Security/integration:** default-deny egress blocks an outbound connection to an unlisted host; an allowlisted host succeeds. Both outcomes are asserted.
- **Security/integration:** a resource-limit violation (output size, timeout, memory) terminates the call and surfaces a bounded, honest error.
- **Adversarial:** a prompt-injection payload embedded in a repository file (README, comment, fixture) that instructs the agent to run a destructive or exfiltrating command does not result in that action, or results in a blocked/denied audited attempt.
- **Adversarial:** model output asserting elevated permission changes no authorization decision.
- **Integration:** a gated operation cannot proceed without a recorded authorized human approval, verified through both API and CLI paths.
- **Review:** every enabled tool has a documented schema, scope, timeout, output limit, and approval classification.

## Open questions for the owner

1. Approve container-based sandboxing for the MVP, or accept a weaker interim posture with an explicit, documented risk?
2. What is the permitted network egress policy — fully offline, specific endpoints (e.g. local model only), or an allowlist?
3. Which operations require human approval by default? A default list is needed before Milestone 7.
4. Is running untrusted third-party code (e.g. an arbitrary repo's test suite) in scope? This raises the isolation bar substantially.
5. What is the acceptable maximum task runtime and resource envelope per task?

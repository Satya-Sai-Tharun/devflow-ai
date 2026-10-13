# 0003. Authentication and tenancy model

- **Status:** **Proposed** — requires owner decision before any non-public endpoint is exposed
- **Date:** 2026-10-12
- **Deciders:** project owner (decision required); agent recommendation
- **Related requirements:** PR-001, PR-002, PR-004, PR-006, PR-007, PR-010
- **Related documents:** `docs/SECURITY.md`, `docs/THREAT_MODEL.md`, `docs/API_CONTRACTS.md` § Authentication, `docs/DATABASE.md`

## Context

Every task read, event stream, cancellation, approval, and result access must be authorized against the caller and its tenant/project boundary. `docs/SECURITY.md` states the invariant plainly: **an opaque task ID is not authorization.** Guessing or leaking an ID must never grant access.

Two questions are currently unresolved and block safe API and dashboard work:

1. **How callers authenticate** (session cookie, bearer token, API key, OIDC).
2. **Whether the system is single-tenant or multi-tenant**, and if multi-tenant, where the isolation boundary sits.

This matters early because tenancy affects the schema (an owner/tenant column on `tasks`), the authorization check on every query, the SSE connection path, and whether PostgreSQL row-level security is worth adopting.

## Decision (recommended)

**Authentication — start with a single, explicit mechanism and keep it replaceable.** Recommendation for the local/MVP stage: bearer credentials for the CLI and a secure, `HttpOnly`, `Secure`, `SameSite`-restricted session cookie for the dashboard, both resolving to one server-side principal object. Keep resolution behind a single dependency so the mechanism can be swapped without touching domain code.

**Tenancy — assume multi-tenant-capable from the first commit, even if only one tenant exists initially.** Concretely: every `tasks` row carries an owner/tenant identifier; every query is scoped by it; and the authorization function takes `(principal, resource)` and denies by default. Retrofitting tenancy later is far more expensive and error-prone than carrying a column that is constant in the MVP.

Recommended invariants, to be treated as security requirements:

1. Deny by default; authorize on every read, stream, cancel, approve, and result access.
2. Authorization is evaluated **server-side only**. No client-supplied claim, and **no model or tool output**, may grant or elevate access.
3. A resource belonging to another tenant must not be distinguishable from a nonexistent resource — return the same error for "not found" and "not yours" to prevent enumeration. (Deliberate `404`-over-`403` choice; document and test it.)
4. SSE authorization is enforced at connect **and** re-connect, with the same check as the snapshot endpoint.
5. Administrative/operator capability, if added, is a separate explicitly-authorized role, never an implicit consequence of authentication.

## Alternatives considered

- **No authentication for the MVP (open local endpoints).** Rejected. `AGENTS.md` and `docs/SECURITY.md` forbid shipping unprotected endpoints, and `PLAN.md` permits auth *stubs* only when clearly marked — not removal of the control. A local-only exception would also tend to leak into later work.
- **Opaque task ID as a capability URL (unguessable link grants access).** Rejected: this is precisely the anti-pattern `docs/SECURITY.md` names. It also makes revocation, audit, and per-tenant policy impossible.
- **Full OIDC/OAuth provider integration now.** Deferred, not rejected: it is the right answer for team deployment but adds a dependency and configuration burden before the task lifecycle is proven. The recommended design keeps this swap cheap.
- **Static single shared API key.** Acceptable only as an explicitly labeled local development bootstrap. Rejected as a shipped mechanism: no per-user identity, no per-tenant isolation, no meaningful audit attribution.
- **Strict single-tenant (no owner column).** Rejected: `PRD.md` targets small engineering teams, and the owner column is cheap now and expensive later.
- **PostgreSQL row-level security as the primary isolation mechanism.** Attractive as defense-in-depth, but RLS depends on correct session-variable propagation and a connection-pooling strategy that does not leak tenant context across pooled connections. Recommendation: treat RLS as an optional later layer, and enforce authorization in domain code now.

## Consequences

**Positive:** one authorization choke point; no ID-guessing exposure; audit records carry a real actor; multi-tenant support does not require a schema migration later.

**Negative / accepted costs:** every query must carry the scope predicate, and forgetting it is a silent vulnerability — this needs a test that asserts cross-tenant access fails. Session/cookie handling introduces CSRF obligations for the dashboard, which must be addressed explicitly (see `docs/THREAT_MODEL.md`). Auth adds a small latency cost to every request that must stay inside the read budget.

**Not decided here:** password/credential storage, MFA, invitation and user-provisioning flows, token lifetime and rotation, and whether self-hosted deployments may disable authentication. These follow once the mechanism is chosen.

## Verification

- **Integration:** an unauthenticated request to every non-public endpoint returns `401`.
- **Integration:** principal A requesting principal B's task returns the same response as a nonexistent task.
- **Integration:** the SSE stream rejects an unauthorized subscriber at connect and at reconnect.
- **Integration:** an approval submitted by an unauthorized principal is rejected and recorded.
- **Adversarial:** an agent/tool/model output that claims elevated permission changes nothing about the effective authorization decision.
- **Integration:** cancellation and result access are each authorized independently — authorization on one path never implies another.

## Open questions for the owner

1. Which authentication mechanism for the MVP: local session + bearer, or integrate an identity provider immediately?
2. Single-tenant or multi-tenant? If multi-tenant, is the isolation boundary a user, a team, or a project?
3. Must a self-hosted deployment be able to run fully offline with no external identity provider?
4. Is operator/admin capability in scope for the MVP, and who may hold it?

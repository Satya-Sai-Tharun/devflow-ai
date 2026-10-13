# 0003. Authentication and tenancy model

- **Status:** **Accepted** — approved by the project owner on 2026-10-13
- **Date:** 2026-10-12 (proposed); 2026-10-13 (accepted)
- **Deciders:** project owner
- **Related requirements:** PR-001, PR-002, PR-004, PR-006, PR-007, PR-010
- **Related documents:** `docs/SECURITY.md`, `docs/THREAT_MODEL.md`, `docs/API_CONTRACTS.md` § Authentication, `docs/DATABASE.md`

> **Owner decision (2026-10-13):** Dashboard authentication uses **Argon2id** password hashes and **revocable opaque server-side sessions**. CLI authentication uses **scoped, revocable personal access tokens**. Authorization is enforced **server-side and denies by default**. The **isolation boundary is a workspace, with an owning user**; workspace scope is preserved in the schema and in every relevant authorization and data-access path. Workspace membership and access-control requirements must be documented before they are implemented.

## Context

Every task read, event stream, cancellation, approval, and result access must be authorized against the caller and its workspace boundary. `docs/SECURITY.md` states the invariant plainly: **an opaque task ID is not authorization.** Guessing or leaking an ID must never grant access.

The two questions this record resolves:

1. **How callers authenticate** — answered: Argon2id + opaque server-side sessions for the dashboard; scoped personal access tokens for the CLI.
2. **Where the isolation boundary sits** — answered: a **workspace**, owned by a user.

This matters early because tenancy affects the schema (workspace and owner columns on `tasks`), the authorization check on every query, the SSE connection path, and whether PostgreSQL row-level security is worth adopting.

## Decision (accepted)

**Authentication.** Dashboard: username + password verified against an **Argon2id** hash, exchanged for an **opaque, high-entropy session token** whose **hash** is stored server-side in PostgreSQL and delivered as an `HttpOnly`, `Secure`, `SameSite` cookie, with absolute and idle TTLs and instant server-side revocation. CLI: **scoped personal access tokens** — opaque, high-entropy, displayed once, stored as a hash, individually revocable, with explicit scopes and expiry. Both resolve to one **principal object** behind a single dependency, so the mechanism can be replaced (for example by OIDC for team deployment) without touching domain code.

**Tenancy — a workspace is the isolation boundary, with an owning user.** Every owned row carries a **workspace identifier**; every query is scoped by it; the authorization function takes `(principal, resource)` and denies by default. Retrofitting tenancy later is far more expensive and error-prone than carrying a column that is constant in the MVP.

Accepted invariants, to be treated as security requirements:

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

## Owner decision and remaining items

Resolved by the owner on 2026-10-13:

1. **Which authentication mechanism for the MVP?** → **Argon2id + revocable opaque server-side sessions** for the dashboard; **scoped, revocable personal access tokens** for the CLI. No identity provider in the MVP.
2. **Single-tenant or multi-tenant, and what is the boundary?** → **A workspace is the isolation boundary, with an owning user.** Workspace scope is carried in the schema and enforced in every authorization and data-access path.
3. **Authorization model?** → **Server-side, deny by default.**

Still open — **must be documented before workspace access control is implemented** (required by the owner decision above):

- **Workspace membership model and roles.** Who may be a member, what roles exist (for example owner / member / viewer), and what each role may do. This is a prerequisite for the Milestone 2 schema's membership table and for the authorization matrix.
- **Offline self-hosting.** Whether a self-hosted deployment must run fully offline with no external identity provider. The accepted mechanism supports this today; confirm it is a requirement so it is not accidentally foreclosed.
- **Operator/admin capability.** Whether it is in MVP scope and who may hold it. If added, it must be a separate explicitly-authorized role, never an implicit consequence of authentication.
- **Credential lifecycle policy.** Password strength/complexity rules, Argon2id parameter targets, session absolute and idle TTL values, PAT maximum lifetime, and lockout thresholds after repeated failures.
- **Workspace invitation/provisioning flow.** How a new user joins a workspace, and whether self-service workspace creation is permitted.

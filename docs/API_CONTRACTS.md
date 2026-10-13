# DevFlow AI — API Contracts and Conventions

## Status and scope

**This document specifies the product API and transport conventions; most contracts below remain planned.** The initial API foundation exists under `services/api/`; `/healthz` and `/readyz` are implemented and have reported local verification. It does not implement the task, authentication, authorization, workflow, or SSE contracts below.

The repository has a Python 3.12 FastAPI application, typed Pydantic Settings configuration, asynchronous SQLAlchemy PostgreSQL connectivity, and an explicit Alembic `0001_initial` baseline. `/healthz` is database-independent; `/readyz` checks database connectivity and migration state and returns a generic degraded 503 when readiness fails. Startup does not apply migrations. Local unit, PostgreSQL integration/acceptance, Pyright, Ruff, documentation-validator, and diff checks have been reported passing; these are local results, not CI results. See [`../.agent-state/ACTIVE-TASK.md`](../.agent-state/ACTIVE-TASK.md) and [`REQUIREMENTS_TRACEABILITY.md`](REQUIREMENTS_TRACEABILITY.md) for evidence scope.

Where a choice is not owner-approved, it is labelled **Proposed** or **Unresolved decision**. A
proposal recorded here is not a decision; it must not be quoted elsewhere as one.

### Ownership boundaries

| Subject | Authoritative document |
|---|---|
| Task lifecycle states, allowed transitions, externally observable task behavior, error-semantics baseline | [`../SPEC.md`](../SPEC.md) |
| HTTP conventions, error envelope, auth/authorization *model*, endpoint shapes, SSE protocol, versioning, caching | This document |
| Components, boundaries, dispatch, reliability architecture | [`../ARCHITECTURE.md`](../ARCHITECTURE.md) |
| Security requirements, trust boundaries, secrets, audit | [`SECURITY.md`](SECURITY.md), [`THREAT_MODEL.md`](THREAT_MODEL.md) |
| Product requirements `PR-001`..`PR-015` | [`../PRD.md`](../PRD.md) |
| Test levels and required coverage of these contracts | [`TESTING.md`](TESTING.md) |
| Performance budgets | [`PERFORMANCE.md`](PERFORMANCE.md) |

**This document does not redefine task semantics.** State names, terminality, and the allowed
transition set are owned by `SPEC.md` and are reproduced here only to make the endpoint and event
contracts concrete. If this document and `SPEC.md` disagree about the task lifecycle, `SPEC.md`
wins and this document is the defect.

### Where this document extends SPEC.md

The following are **additions** this document introduces beyond `SPEC.md`. They are flagged at each
point and must not be read as already-agreed behavior:

- A **task list endpoint** (`GET /api/v1/tasks`) needed by the dashboard and CLI list views — **Proposed**.
- The **concrete error envelope and `code` enum** — `SPEC.md` requires a stable machine-readable code, human-readable message, correlation ID, and field details, but does not fix the shape.
- The **SSE event type table**, event ID design, `Last-Event-ID` handling, heartbeat interval, and backpressure rules — `SPEC.md` requires that these be defined.
- **Pagination, idempotency-key, request-ID, and size-limit conventions.**
- **Cancellation request vs. confirmation** field naming in the task snapshot — `SPEC.md` requires the distinction; the field representation is specified here.
- **Caching and conditional-request guidance.**

---

## 1. Conventions

### 1.1 Base path and versioning prefix

- All public routes live under **`/api/v1`**. The version segment is part of the path.
- Relative links inside JSON payloads (`status_url`, `events_url`) are **path-only**, matching the
  `SPEC.md` example (`/api/v1/tasks/opaque-stable-id`). Clients resolve them against the same origin
  and base URL they used for the request. Do not emit absolute URLs unless an owner decision requires
  them; they leak deployment topology and break behind proxies.
- Health and readiness endpoints are operational and are **not** part of the versioned product API;
  they are protected separately (see [`SECURITY.md`](SECURITY.md)).

### 1.2 Content types

| Direction | Media type | Rule |
|---|---|---|
| JSON request body | `application/json` | Required for `POST` bodies. A body with any other media type → `415`. |
| JSON response body | `application/json` | All non-stream responses, including errors. |
| SSE response | `text/event-stream` | Only `GET /api/v1/tasks/{task_id}/events`. |
| JSON error body | `application/json` | Errors on the SSE route that occur **before** the stream is established are ordinary JSON errors. |

- Responses **must** include `Content-Type` with an explicit charset for JSON (`application/json`).
- Clients **must** ignore unknown JSON fields rather than failing. Servers **must not** remove
  documented fields within a major version (see §8).
- The API does not currently accept `multipart/form-data`. Repository content is referenced by
  identifier, not uploaded through these endpoints — **Proposed**.

### 1.3 JSON field naming: `snake_case`

**Proposed (but strongly recommended), consistent with `SPEC.md`.**

`SPEC.md` already fixes the submission response as `task_id`, `status`, `created_at`, `status_url`,
`events_url`. Those are `snake_case`, so `snake_case` is the convention for all API JSON, including
nested objects, event payloads, and error details.

Justification:

1. **Consistency with the one already-published example.** Mixing `camelCase` and `snake_case`
   across endpoints forces every client to carry two naming rules, and guarantees at least one
   mapping bug.
2. **Python-first server.** FastAPI/Pydantic models are `snake_case` by default. Using `snake_case`
   on the wire removes an alias/serialization layer that would otherwise be an easy place to
   silently drop or rename a field.
3. **Two first-class clients.** The Python CLI maps directly; the TypeScript dashboard maps once,
   in one generated-contract boundary (see §8.4), rather than per-component.

Consequences to accept explicitly:

- The TypeScript client must not hand-write interfaces that guess casing; it consumes generated types.
- Any future query parameter naming follows the same rule (`created_after`, `page_size`).

### 1.4 Timestamps

- All timestamps are **RFC 3339 / ISO-8601**, normalized to **UTC with an explicit offset**, not a
  bare local time and not a naive string.

```text
2026-01-31T14:05:09.123Z          # accepted form (preferred)
2026-01-31T14:05:09.123456+00:00  # accepted form (equivalent offset)
2026-01-31T14:05:09               # REJECTED: no offset
```

- Format: `YYYY-MM-DDTHH:MM:SS[.fff…]Z`. Fractional seconds are permitted; microsecond precision is
  the maximum. Servers emit millisecond or microsecond precision consistently within a response.
- **Every** timestamp field name ends in `_at` (`created_at`, `updated_at`, `started_at`, …) or is
  explicitly a duration, which uses integer **milliseconds** with a `_ms` suffix (`duration_ms`).
  Durations are never emitted as floating-point seconds.
- Clients must parse offsets rather than assume `Z`, and must not depend on lexicographic ordering of
  timestamps for correctness.
- Clock source: the API server or database records timestamps; worker and client clocks are not
  authoritative.

### 1.5 Identifiers

- Identifiers are **opaque strings**. Clients must not parse, order, or infer meaning from them.
- **Non-sequential and unguessable.** Sequential integers leak volume, creation rate, and
  enumeration targets. Recommended shape — **Proposed**: a URL-safe random token (for example a
  128-bit random value rendered base32/hex, optionally prefixed for debuggability such as
  `task_...`) or a UUIDv7 rendered as text where time-sortable internal ordering is useful. An
  implementation may choose differently, but it must remain opaque to clients.
- **An identifier is NOT authorization.** Possessing a `task_id` never grants access. Every read,
  stream, cancellation, approval, and result access is authorized against the caller and the
  tenant/project boundary on every request, with no exceptions for "hard to guess" IDs. This restates
  `SECURITY.md` and cannot be weakened.
- Route parameters are validated as strings with an explicit maximum length and an allowed character
  class before any lookup, so malformed IDs fail as `400` or `404` and never reach the database as
  raw input.

### 1.6 Pagination convention for list endpoints

**Proposed.** List endpoints return a page envelope; they never return a bare array, because a bare
array cannot carry a next-page cursor or total.

```json
{
  "items": [ { "task_id": "task_01J...", "status": "running" } ],
  "page": {
    "next_cursor": "eyJjcmVhdGVkX2F0IjoiMjAyNi0wMS0zMVQxNDowNTowOVoiLCJpZCI6InRhc2tfMDFKLi4uIn0",
    "has_more": true
  }
}
```

- **Cursor-based pagination is Proposed** and preferred over offset pagination: the task list is
  ordered newest-first and is mutated continuously by workers, so offsets skip and duplicate rows.
- The cursor is an **opaque continuation token** the client echoes back verbatim as `cursor`. It must
  be treated as untrusted input server-side and must never encode authorization decisions — a cursor
  from one tenant must not be able to select another tenant's rows, because the tenant filter is
  applied independently of the cursor.
- `page_size` is bounded by a server maximum. Requests above the maximum are clamped, not rejected;
  non-integer or non-positive values are `400`.
- Response ordering must be **total and stable** (for example `created_at DESC, task_id DESC`) so a
  cursor cannot loop.
- SSE is not paginated. The event stream is bounded by replay-window and rate rules (§7), not by pages.

### 1.7 Request and correlation IDs

- Clients **may** send `X-Request-ID` on any request. Servers **must** send `X-Request-ID` on every
  response, including errors and including a failed SSE handshake.
- If the client supplies a syntactically acceptable value, the server echoes it. Otherwise the server
  generates one. The accepted character class and maximum length must be enforced; rejected values
  are replaced, not reflected unsanitized.
- The value must be treated as untrusted metadata: no header injection, no log injection, no use in a
  response body without escaping.
- The same identifier appears in the JSON error envelope as `request_id` (§4), in structured logs, and
  in traces, so a user-reported error can be located (supports `PR-012`).
- `X-Request-ID` is **not** a correlation ID for asynchronous work. The durable correlation key for a
  task is the `task_id`; per-attempt work additionally carries an `attempt` number.

### 1.8 Idempotency for task submission

Submitting work is the one place a network retry can plausibly create duplicate tasks, so it carries
explicit idempotency semantics. **Proposed** in full:

- `POST /api/v1/tasks` **accepts** an `Idempotency-Key` header. Policy on whether it is *required*
  is an owner decision (§11) — the recommended default is **required**, because optional idempotency
  is the option that fails silently.
- The key is an opaque client-generated string with an enforced maximum length.
- Scope: the key is scoped to the **authenticated principal and tenant**, so one caller cannot replay
  or collide with another caller's key.
- Behaviour:
  - First request with a key: create the task, persist the key with the resulting `task_id`, respond `202`.
  - Repeat request, same key, same request body: return the **same** `task_id` with `202` and a
    header indicating a replay (for example `Idempotent-Replay: true`) — **Proposed** header name.
    No second task is created and no second dispatch is enqueued.
  - Repeat request, same key, **different** request body: `409` with code `conflict_idempotency_key_reuse`.
    The server must not silently return the first task's result for a different request.
  - Repeat request while the first is still in flight: the server must not create a second task. It
    either waits briefly or returns `409` with code `conflict_request_in_progress` — **Unresolved decision**.
- The key record must be durable, with a documented retention window. It must not live only in Redis,
  since Redis is never the only durable store (`ARCHITECTURE.md` §Redis).
- Idempotency guarantees task *creation* only. It does not make execution exactly-once; worker
  delivery may be at-least-once and job handlers must be idempotent.

### 1.9 Size and rate limits

Values are **Unresolved decisions**; the *existence* of enforced limits is required.

| Limit | Applies to | Behaviour on breach |
|---|---|---|
| JSON request body size | All `POST` bodies | `413 payload_too_large` |
| SSE replay window | `Last-Event-ID` older than retention | Stream starts fresh; a `snapshot_required` event is emitted (§7) |
| Events per second per connection | SSE progress events | Coalesce/drop progress events, never lifecycle events (§7.8) |
| `page_size` maximum | List endpoints | Clamped |
| Rate limit | Submission, cancellation, approval, and stream connect | `429 rate_limited` with `Retry-After` |
| Result payload size | Task result metadata | Result truncated with an explicit marker, never silently |

Limits that exist but are undocumented are a support problem: every enforced limit must be reported
in the error payload where it caused the rejection (§4.5).

---

## 2. Authentication and authorization model

This section defines **what must be true**. It deliberately does **not** select a mechanism, because
no authentication mechanism has been owner-approved (`PRD.md` "Constraints and open decisions";
`ARCHITECTURE.md` §12).

### 2.1 Authentication requirement

- Every endpoint in this document except explicitly designated public routes requires an
  authenticated principal. There are currently **no public product endpoints**; anonymity is not an
  accepted state for task access.
- Unauthenticated requests receive `401 unauthenticated` with a `WWW-Authenticate` challenge
  consistent with the chosen mechanism.
- Credentials must be transmitted only over TLS in any non-local environment, must never appear in
  URLs or query strings, and must never be logged or echoed in errors.
- The CLI and the dashboard authenticate through the **same** mechanism and authorization rules
  (`PR-004`, `PR-014`); the CLI must not hold a bypass or a privileged service identity.

### 2.2 Authorization requirements (mechanism-independent)

For **every** request, the service must decide and record:

1. **Who** the caller is (principal).
2. **Which task** is targeted.
3. **Whether the caller may perform this operation on this task** — read snapshot, read result
   metadata, open the event stream, cancel, approve/reject.
4. **Whether the caller is inside the task's tenant/project boundary.** Cross-tenant access is denied
   even for a correct task ID. This is the boundary that an opaque ID must never be able to cross.

Operation-specific notes:

- **Reads** (`GET` snapshot, result metadata): authorize the task before touching the result store.
- **Streams**: authorizing only the initial connect is insufficient. Authorization must be
  **re-evaluated on every connect and every reconnect**, and a long-lived stream must not outlive a
  revoked grant indefinitely — the stream must be revalidated periodically and terminated on
  revocation. See §7.9.
- **Cancellation and approval**: authorize as **write** operations with their own permission, not
  merely "can read the task". A principal who may observe a task is not automatically permitted to
  cancel it or to satisfy an approval gate.
- **Approval**: must additionally verify the approver is an eligible human principal for that scope,
  and that the requester is not self-approving where policy forbids it (§6.1).
- **Result access**: distinct from snapshot access. A snapshot may include result *metadata*
  (status, verification outcome, counts) while the result *content* requires a stronger grant or a
  separate policy decision.

### 2.3 Candidate authentication mechanisms (Unresolved decision)

Presented as options with trade-offs. **None is approved.**

| Option | Strengths | Trade-offs / risks |
|---|---|---|
| Opaque bearer API tokens issued per principal | Simple for the CLI; easy to revoke and rotate; no browser redirect flow needed | Long-lived secrets in CLI config files; needs careful storage and rotation; no interactive login story for humans |
| Session cookie for the dashboard + bearer token for the CLI | Cookie can be `HttpOnly`/`SameSite`; browser story is natural; CLI keeps tokens | Two mechanisms to secure and test; CSRF handling required for cookie-authenticated state-changing calls; must keep authorization logic identical |
| OIDC / OAuth 2.0 with an external identity provider | Standard; MFA and offboarding come from the IdP; group claims can map to roles | External dependency and configuration; token validation, audience, clock-skew, and JWKS-caching work; overkill for a local-first MVP |
| Signed short-lived JWT issued by this service | Stateless verification; short expiry limits exposure | Revocation before expiry is awkward; claim validation is easy to get wrong; still needs an issuance path |

Additional requirements regardless of choice:

- **CSRF**: if cookie-based authentication is selected, every state-changing endpoint
  (`POST /tasks`, `/cancel`, `/approval`) must be protected (origin check and/or anti-CSRF token).
- **SSE and auth**: browser `EventSource` cannot set arbitrary headers, so a header-only bearer scheme
  forces either a cookie-based stream route or a non-`EventSource` client — this is a real constraint
  on the design, not a detail.
- **Machine-to-machine**: any service identity must be separately scoped and auditable; it must not
  inherit a human's broad grants.

### 2.4 Candidate tenancy models (Unresolved decision)

| Option | Strengths | Trade-offs / risks |
|---|---|---|
| Single-tenant, per-principal ownership only | Simplest; fastest to implement correctly; fits local/self-hosted MVP | Any future multi-tenant need is a migration; sharing a task requires an explicit grant model anyway |
| Tenant → project → task hierarchy, enforced in every query | Matches "teams" and "repositories" as natural boundaries; supports sharing within a project | Requires the tenant filter to be present in every query path (a missing `WHERE` is a cross-tenant leak); needs membership and role management; invites the `403` vs `404` enumeration question (§4.6) |
| Per-task ACL list | Precise sharing with specific principals | Most complex; list-growth and query-cost problems; easy to introduce an authorization bypass |

The selected model must be recorded as an ADR before the endpoints are implemented, and the
authorization rule must be enforced **centrally** (domain/policy layer) rather than repeated per
handler, so it can be tested once (see [`TESTING.md`](TESTING.md)).

---

## 3. Error model

### 3.1 Canonical error envelope

There is exactly **one** error shape for every non-2xx JSON response from this API. No endpoint
invents its own.

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Request validation failed.",
    "request_id": "b7f0c3d2-6a1e-4c8f-9a55-2f0d8e41c7aa",
    "retryable": false,
    "details": [
      {
        "field": "prompt",
        "reason": "too_short",
        "message": "Must be at least 1 character."
      }
    ],
    "meta": {
      "field_count": 1
    }
  }
}
```

Rules:

- **One top-level key**, `error`. Success responses are not wrapped in a second envelope beyond what
  each endpoint specifies; a response is either a documented success shape or this error shape.
- `code` is a **stable, machine-readable** snake_case string from the enum in §3.3. Clients branch on
  `code`; they must never branch on `message` text or on HTTP status alone where a code exists.
- `message` is a short, human-readable sentence safe to display. It must not contain stack traces,
  SQL, file paths, host names, tokens, or provider payloads.
- `request_id` is always present and equals the `X-Request-ID` response header.
- `retryable` tells a client whether an immediate retry of the **same** request could succeed.
  It is a hint for backoff decisions, not a guarantee.
- `details` is optional and appears where field- or item-level problems exist. It is an array so a
  single request can report several problems.
- `meta` is optional, endpoint-specific, and additive. It must contain only non-sensitive context
  (limits, counts, current state) that helps the client react.
- Errors must be **stable across equivalent inputs**: the same invalid request produces the same
  `code`, not a different one depending on execution order.

### 3.2 What must never appear in an error

Never include, in any error response or in logs correlated by `request_id`:

- Stack traces, exception class names, or tracebacks.
- Filesystem paths, internal host names, ports, container names, or connection strings.
- Database errors, SQL text, constraint names, or schema details.
- Secret values, tokens, keys, cookies, or credential fragments.
- Raw model prompts, raw provider responses, raw tool output, or repository content.
- Provider credentials, internal provider error payloads, or vendor request IDs that enable abuse.

Validation and policy errors may describe the *shape* of the problem and the offending field name.
They must not echo the offending value back when the field is sensitive (for example a credential
field echoes only that it was present and invalid, never its content).

### 3.3 Error code enum

**Proposed** — this table is the fixed set for `/api/v1`. Adding a code is an additive change (§8);
renaming or removing one is breaking.

| `code` | HTTP | Meaning | `retryable` | Notes |
|---|---:|---|---|---|
| `validation_failed` | 400 | Request body, query, or path failed schema validation | false | `details` lists field-level reasons |
| `malformed_request` | 400 | Body is not valid JSON or is truncated | false | No field details available |
| `unauthenticated` | 401 | Missing, malformed, or expired credentials | false | Sends `WWW-Authenticate` |
| `not_found` | 404 | Task does not exist **or** caller is not permitted to see it | false | Deliberate anti-enumeration collapse (§4.6) |
| `method_not_allowed` | 405 | Method not supported on this path | false | `Allow` header set |
| `conflict_invalid_transition` | 409 | Requested operation is not legal from the current state | false | `meta.current_state` included |
| `conflict_approval_not_pending` | 409 | Approval/rejection submitted when no decision is pending | false | Includes pending-approval identifier when expired/stale (§6.3) |
| `conflict_task_terminal` | 409 | Task is terminal; operation cannot apply | false | `meta.current_state` is terminal |
| `conflict_idempotency_key_reuse` | 409 | Same `Idempotency-Key`, different request body | false | Never silently reuses the first task |
| `conflict_request_in_progress` | 409 | Same `Idempotency-Key`, original still in flight | true | Only if the in-flight policy chooses to reject |
| `payload_too_large` | 413 | Request body exceeds the configured maximum | false | `meta.max_bytes` included |
| `unsupported_media_type` | 415 | Request `Content-Type` is not `application/json` | false | |
| `rate_limited` | 429 | Caller exceeded a limit for this operation | true | `Retry-After` header set |
| `upstream_model_error` | 502 | Model provider failed or returned an unusable response | true | Typically surfaces on the task, not a synchronous read |
| `upstream_tool_error` | 502 | Tool/MCP invocation failed or violated its contract | true | Sanitized; no vendor payload |
| `upstream_timeout` | 504 | Upstream dependency exceeded its deadline | true | Task outcome is governed by `SPEC.md` timeout rules |
| `dispatch_unavailable` | 503 | Durable acceptance succeeded but the work could not be durably dispatched | true | Must never be reported as success (`SPEC.md`, `PR-001`) |
| `service_unavailable` | 503 | Temporary dependency outage (database, queue, stream backend) | true | `Retry-After` when known |
| `internal_error` | 500 | Unclassified server fault | true | Correlation ID only; no internal detail |

Related distinctions that matter in practice:

- **`conflict_invalid_transition` vs `conflict_task_terminal`.** Terminal is a special case of
  invalid transition, but it is split out because clients handle it differently: a terminal task is a
  final answer (">this can never happen now"), while an invalid transition from a live state may be a
  race the client should re-read the snapshot for.
- **`upstream_timeout` vs `upstream_model_error`.** A timeout is retryable with backoff; a provider
  rejection may need a different model or a budget change. Both are sanitized.
- **`dispatch_unavailable` is not `conflict_*`.** It signals that a *submission* request could not
  complete its durable acceptance/dispatch step. The API must not return `202` for it.

### 3.4 Validation error shape

Field-level validation errors populate `details` with a consistent item shape:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Request validation failed.",
    "request_id": "9c1a6f2b-3d47-4c19-8f0b-77b1a0d5e2c4",
    "retryable": false,
    "details": [
      { "field": "prompt", "reason": "required", "message": "Field is required." },
      { "field": "priority", "reason": "not_in_enum", "message": "Must be one of: low, normal, high." },
      { "field": "metadata.repo", "reason": "too_long", "message": "Must be at most 200 characters." }
    ]
  }
}
```

- `field` uses a **dotted path** into the request body (`metadata.repo`, `items.0.name`), relative to
  the request body root. Path parameters and query parameters that fail use their own name.
- `reason` is a stable machine-readable token (`required`, `too_short`, `too_long`, `not_in_enum`,
  `invalid_format`, `out_of_range`, `unknown_field_rejected`, …). It is **not** the same enum as
  `code` and is deliberately finer-grained. Reason tokens are **Proposed**.
- `message` is human-readable guidance for that field.
- Field paths and reason tokens must never disclose internal schemas beyond the documented request
  contract.

### 3.5 Correlation ID echo

- The `X-Request-ID` response header is echoed on every response, including `4xx`, `5xx`, and the
  failed handshake of an SSE stream.
- The body's `error.request_id` always equals that header value. Clients should surface the header
  value in UI error states and CLI output so a report can be traced (`PR-012`, `PR-015`).
- If the client sent `X-Request-ID`, the echoed value is the accepted sanitized form of it. The
  server never reflects a rejected value.

---

## 4. Endpoint specifications

All five `SPEC.md` endpoints plus one proposed list endpoint. Each entry states its `SPEC.md`
lineage so an extension is never mistaken for existing agreement.

Legend: **Auth** — authorization class required (§2.2). **Idem** — idempotency semantics.

### 4.0 `GET /api/v1/tasks` — list tasks

**Proposed.** Not present in `SPEC.md`. Needed for the dashboard list view and CLI `task list`
(`PR-001`, `PR-002`, `PR-014`).

| Aspect | Value |
|---|---|
| Method / path | `GET /api/v1/tasks` |
| Auth | Authenticated; results are filtered to the caller's tenant/project boundary |
| Success | `200 OK` |
| Query params | `status` (repeatable or comma-separated, values from the `SPEC.md` state set), `created_after`, `created_before` (RFC 3339), `cursor`, `page_size`, `order` (`asc`/`desc`, default `desc`) |
| Response | `{ "items": [TaskSummary], "page": { "next_cursor": string \| null, "has_more": boolean } }` |
| Idem | Safe, no side effects |
| Rate limit | Reads are rate limited; pagination is not a bypass |

Constraints: unknown `status` values → `400 validation_failed`; the list is **not** an authorization
boundary relaxation — filtering and authorization are applied together in one query so a cursor
cannot widen scope.

```json
{
  "items": [
    {
      "task_id": "task_01JQ8Z2K7V9M4C3T6B0R5N8H2X",
      "status": "running",
      "created_at": "2026-01-31T14:05:09.123Z",
      "updated_at": "2026-01-31T14:05:41.870Z",
      "status_url": "/api/v1/tasks/task_01JQ8Z2K7V9M4C3T6B0R5N8H2X",
      "events_url": "/api/v1/tasks/task_01JQ8Z2K7V9M4C3T6B0R5N8H2X/events"
    }
  ],
  "page": { "next_cursor": "eyJpZCI6InRhc2tfMDFKUT..", "has_more": true }
}
```

| Error | When |
|---|---|
| `400 validation_failed` | Invalid `status`, unparseable timestamp, bad `page_size` |
| `401 unauthenticated` | No/invalid credentials |
| `429 rate_limited` | Too many list requests |
| `500 internal_error` / `503 service_unavailable` | Persistence unavailable |

### 4.1 `POST /api/v1/tasks` — create a task

Authoritative semantics: `SPEC.md` "Initial API contract" and `PR-001`. This document adds the
request schema, idempotency, and error table.

| Aspect | Value |
|---|---|
| Method / path | `POST /api/v1/tasks` |
| Auth | Authenticated; the caller becomes the task owner within their tenant/project |
| Request `Content-Type` | `application/json` |
| Headers | `Idempotency-Key` (see §1.8), `X-Request-ID` (optional) |
| Success | `202 Accepted` |
| Side effects | Validate → authorize → persist task **and** durable dispatch intent in one transaction → return. **Must not** run the LangGraph workflow or wait for a model (see `ARCHITECTURE.md` §6, `PR-005`) |
| Idem | `Idempotency-Key` required per §1.8 recommendation; replay returns the same `task_id` |

Request body — **Proposed** fields; the implementation must publish the final schema before clients
are generated:

```json
{
  "prompt": "Add password reset to this repository and test it.",
  "priority": "normal",
  "metadata": {
    "repo": "example/service",
    "labels": ["auth"]
  },
  "requested_timeout_ms": 900000
}
```

> **`project_id` removed — owner decision 2026-10-13.** No project entity, table, or endpoint is part of the MVP. **Workspace tenancy** (see `docs/decisions/0003-auth-and-tenancy.md`) supplies the isolation boundary; it is derived from the authenticated principal, not supplied by the client. Do not add a client-supplied scoping field. If a project concept is introduced later it is an **additive** change (a `projects` table, a nullable `tasks.project_id`, an endpoint, and a backfill), not a field to carry speculatively now.

| Field | Type | Required | Constraints |
|---|---|---|---|
| `prompt` | string | yes | 1..N characters; `N` is an **Unresolved decision**; must be stored with its own retention policy |
| `priority` | enum | no | One of `low`, `normal`, `high`; default `normal` |
| `metadata` | object | no | Bounded key count and value size; **untrusted data**, never interpreted as instructions or authorization |
| `requested_timeout_ms` | integer | no | Bounded by server maximum; exceeding the max → `400`, not silent clamping |

**No client-supplied scoping field.** The workspace is derived from the authenticated principal (see `docs/decisions/0003-auth-and-tenancy.md`), never from the request body. A caller cannot select the workspace it writes into.

Success body — **exactly the `SPEC.md` shape** (`task_id`, `status`, `created_at`, `status_url`,
`events_url`):

```json
{
  "task_id": "task_01JQ8Z2K7V9M4C3T6B0R5N8H2X",
  "status": "queued",
  "created_at": "2026-01-31T14:05:09.123Z",
  "status_url": "/api/v1/tasks/task_01JQ8Z2K7V9M4C3T6B0R5N8H2X",
  "events_url": "/api/v1/tasks/task_01JQ8Z2K7V9M4C3T6B0R5N8H2X/events"
}
```

The response is intentionally minimal: the client has a stable identifier and two follow-up URLs and
does not need a second round trip. `status` is `queued` at creation because durable acceptance is the
only thing `202` asserts.

| Error | When |
|---|---|
| `400 malformed_request` | Body is not valid JSON |
| `400 validation_failed` | Schema violations, unknown enum value, out-of-range timeout |
| `401 unauthenticated` | No/invalid credentials |
| `404` `not_found` | The resource does not exist **or** lies outside the caller's workspace (§4.6 policy — deliberately indistinguishable, to prevent enumeration) |
| `409 conflict_idempotency_key_reuse` | Same key, different body |
| `409 conflict_request_in_progress` | Same key, first request still in flight (if that policy is chosen) |
| `413 payload_too_large` | Body over the maximum |
| `415 unsupported_media_type` | Wrong or missing `Content-Type` |
| `429 rate_limited` | Submission limit exceeded |
| `503 dispatch_unavailable` | Task persisted but dispatch could not be durably recorded — **never** return `202` here |
| `503 service_unavailable` / `500 internal_error` | Dependency failure or unclassified fault |

### 4.2 `GET /api/v1/tasks/{task_id}` — authoritative snapshot

Authoritative semantics: `SPEC.md`; also `PR-002` and the reconciliation rule in `PR-006`.

| Aspect | Value |
|---|---|
| Method / path | `GET /api/v1/tasks/{task_id}` |
| Auth | Authenticated **and** authorized for this task, on every request |
| Success | `200 OK` |
| Side effects | None. Must be safe to call repeatedly, including as a polling fallback |
| Idem | Safe |

Response — the snapshot is the **authoritative record**; the SSE stream is not (§7.7):

```json
{
  "task_id": "task_01JQ8Z2K7V9M4C3T6B0R5N8H2X",
  "status": "needs_approval",
  "created_at": "2026-01-31T14:05:09.123Z",
  "updated_at": "2026-01-31T14:07:22.004Z",
  "started_at": "2026-01-31T14:05:11.900Z",
  "finished_at": null,
  "attempt": 1,
  "allowed_transitions": ["running", "cancelled", "blocked"],
  "cancellation": {
    "requested": false,
    "requested_at": null,
    "confirmed": false,
    "confirmed_at": null
  },
  "pending_approval": {
    "approval_id": "appr_01JQ8ZB3QK7Y2M6P4T9V1W5D8N",
    "requested_at": "2026-01-31T14:07:22.004Z",
    "expires_at": "2026-01-31T14:37:22.004Z",
    "scope": "tool:repository.write",
    "summary": "Apply patch to 3 files and run the test suite."
  },
  "progress": {
    "stage": "awaiting_approval",
    "percent": 40,
    "message": "Waiting for approval to modify repository files."
  },
  "result": null,
  "status_url": "/api/v1/tasks/task_01JQ8Z2K7V9M4C3T6B0R5N8H2X",
  "events_url": "/api/v1/tasks/task_01JQ8Z2K7V9M4C3T6B0R5N8H2X/events"
}
```

Field rules:

- `status` values are exactly the `SPEC.md` set. This document does not add states.
- `allowed_transitions` — **Proposed**: derived from the `SPEC.md` transition table for the current
  state, so the dashboard can disable illegal actions rather than guess (`PR-003`, `PR-015`). It is a
  convenience projection, **not** an authorization: the server re-validates every transition.
- `attempt` is an explicit counter; retries are never represented by silently reopening a task.
- `cancellation` carries the request/confirm distinction required by `SPEC.md` (§5).
- `pending_approval` is non-null only while a decision is genuinely pending, and mirrors `status ==
  "needs_approval"`. If it is non-null while `status` is not `needs_approval`, that is a bug.
- `progress` is advisory and may be slightly stale. It is never the source of truth for state.
- `result` — **Proposed** shape; may be `null` for non-terminal tasks or when the caller lacks result
  access. When present for a terminal task:

```json
{
  "result": {
    "summary": "Password reset implemented for email and token flows.",
    "verification": {
      "status": "passed",
      "checks_run": 12,
      "checks_failed": 0,
      "evidence_url": null
    },
    "artifacts": [
      { "kind": "patch", "name": "password-reset.patch", "size_bytes": 4211 }
    ],
    "truncated": false
  }
}
```

`verification.status` must be honest (`PR-009`): a task is not reported as passed because of a
timeout, a skipped test, or a missing adapter. `truncated: true` means the result exceeded a bound
and was cut — clients must show that, never present a truncated result as complete.

`finished_at` is set only for terminal states. `updated_at` must change on every persisted transition
so clients can detect staleness without diffing whole bodies.

| Error | When |
|---|---|
| `400 validation_failed` | `task_id` fails the accepted character/length class |
| `401 unauthenticated` | No/invalid credentials |
| `404 not_found` | Absent **or** not permitted (§4.6) |
| `429 rate_limited` | Polling abuse / reconnect storm |
| `500 internal_error` / `503 service_unavailable` | Unclassified fault or persistence outage |

### 4.3 `GET /api/v1/tasks/{task_id}/events` — SSE stream

Authoritative requirements: `SPEC.md` requires event IDs, heartbeat behavior, reconnect semantics,
authorization, and a replay/snapshot strategy. The full contract is §7.

| Aspect | Value |
|---|---|
| Method / path | `GET /api/v1/tasks/{task_id}/events` |
| Auth | Authenticated **and** authorized on connect **and** on every reconnect; revalidated during long streams |
| Response | `200 OK`, `Content-Type: text/event-stream` |
| Headers | `Cache-Control: no-store`, `X-Accel-Buffering: no`, `X-Request-ID` |
| Reconnect | Client sends `Last-Event-ID`; server replays retained events after that ID, or signals a required snapshot |
| Side effects | Emits an initial snapshot event; may record stream connect/disconnect for observability |
| Idem | Safe to reconnect; replay is additive and idempotent by event `id` |

Errors **before** the stream is established are ordinary JSON errors (`401`, `404`, `409` for a
terminal task if the client asked for live-only — see §11, `429`, `503`). Errors after the stream is
established are delivered **as stream events**, not as a mid-stream HTTP status change (§7.6).

### 4.4 `POST /api/v1/tasks/{task_id}/cancel` — request cancellation

Authoritative semantics: `SPEC.md` ("must distinguish accepted cancellation request from
worker-confirmed cancellation"). Behavior detail: §5.

| Aspect | Value |
|---|---|
| Method / path | `POST /api/v1/tasks/{task_id}/cancel` |
| Auth | Authenticated and authorized as a **write** operation on this task |
| Request body | None required. Optional `{ "reason": string }` — **Proposed**, bounded length, sanitized |
| Success | `202 Accepted` — the **request** was recorded |
| Side effects | Persist the cancellation request durably, mark intent, and signal the worker. Does **not** stop execution synchronously |
| Idem | Idempotent: repeated cancel on a non-terminal task with a pending request re-returns `202` with the same semantics and does not create duplicate intent |

```json
{
  "task_id": "task_01JQ8Z2K7V9M4C3T6B0R5N8H2X",
  "status": "running",
  "cancellation": {
    "requested": true,
    "requested_at": "2026-01-31T14:09:03.512Z",
    "confirmed": false,
    "confirmed_at": null
  }
}
```

`status` here is the task's current state, **not** a promise of `cancelled`. A client that wants
"the task has stopped" must wait for `status == "cancelled"` with `cancellation.confirmed == true`,
via the snapshot or a `task.cancelled` event.

| Error | When |
|---|---|
| `400 validation_failed` | Malformed `task_id` or reason |
| `401 unauthenticated` | No/invalid credentials |
| `404 not_found` | Absent or not permitted |
| `409 conflict_task_terminal` | Already `completed`, `failed`, or `cancelled` — see §5.3 |
| `429 rate_limited` | Cancel spam |
| `500 internal_error` / `503 service_unavailable` | Fault or persistence outage |

### 4.5 `POST /api/v1/tasks/{task_id}/approval` — record a decision

Authoritative semantics: `SPEC.md` ("records an authorized approval/rejection decision ... validate
that the task is actually awaiting that decision"). Behavior detail: §6.

| Aspect | Value |
|---|---|
| Method / path | `POST /api/v1/tasks/{task_id}/approval` |
| Auth | Authenticated; authorized as a decision-maker for the pending scope |
| Request body | `{ "approval_id": string, "decision": "approve" \| "reject", "reason": string? }` — **Proposed** field names |
| Success | `200 OK` with the updated snapshot projection |
| Side effects | Persist decision with actor, decision, timestamp, and scope; resume (`approve`) or fail/cancel per policy (`reject`); emit an event; write an audit record |
| Idem | Repeated identical decision for the same `approval_id` returns the same recorded outcome; a **different** decision for an already-decided `approval_id` → `409 conflict_approval_not_pending`. Approvals are never editable |

```json
{
  "task_id": "task_01JQ8Z2K7V9M4C3T6B0R5N8H2X",
  "status": "running",
  "approval": {
    "approval_id": "appr_01JQ8ZB3QK7Y2M6P4T9V1W5D8N",
    "decision": "approve",
    "decided_at": "2026-01-31T14:10:44.007Z",
    "decided_by": "principal_01JQ8V2M4N6P8R0T2V4X6Z8B0D",
    "scope": "tool:repository.write"
  }
}
```

`approval_id` is included so a stale UI cannot approve a *newer* gate than the one the user saw — the
classic race where a client holds an old page open while the worker pauses again.

| Error | When |
|---|---|
| `400 validation_failed` | Unknown `decision`, missing `approval_id`, malformed body |
| `401 unauthenticated` | No/invalid credentials |
| `404 not_found` | Absent or not permitted |
| `409 conflict_approval_not_pending` | No decision pending, gate expired, or already decided differently (§6.3) |
| `409 conflict_task_terminal` | Task already terminal |
| `422`-class misuse | **Not used** — semantic misuse is `409`, not `422`, to keep one meaning per status |
| `429 rate_limited` | Decision spam |
| `500 internal_error` / `503 service_unavailable` | Fault or persistence outage |

### 4.6 Disclosure policy: `403` vs `404` — **Proposed, deliberate**

For all task-scoped routes, a caller who is authenticated but **not authorized** for a task receives
**`404 not_found`**, byte-for-byte indistinguishable from a non-existent task. Rationale:

- Distinguishing `403` from `404` turns the API into a resource-enumeration oracle: a caller with any
  valid account can probe which task IDs and project IDs exist.
- Collapsing both into `404` removes that signal at trivial cost: an authorized caller never
  encounters the ambiguous case, because their own tasks always resolve.
- The trade-off is real and must be accepted knowingly: operators lose a fast "you lack permission"
  signal, debugging a permissions mistake becomes slightly harder, and support must read correlated
  logs rather than the response body. If that cost is judged too high, the alternative is `403` with a
  strict rate limit on authorization failures — an owner decision (§10, row 6).
- The policy must be **uniform**: the same behaviour for snapshot reads, stream connect and reconnect,
  cancellation, approval, and result access. A single route that leaks `403` while others return `404`
  defeats the measure.
- Errors must not leak existence indirectly either: response timing, `message` text, and `meta` fields
  must be equivalent between "missing" and "forbidden". This is explicitly **not** a reason to weaken
  authorization — the denial still happens; only its *depiction* is collapsed.

---

## 5. Cancellation semantics

Cancellation is the contract most likely to be misread as instantaneous. `SPEC.md` and
`SECURITY.md` both require that it is **not**.

### 5.1 Cancellation requested (accepted)

- Triggered by a successful `POST /api/v1/tasks/{task_id}/cancel`.
- Meaning: a durable, authorized intent to cancel has been recorded and the worker has been signalled.
  It says **nothing** about whether execution has stopped.
- Representation: `cancellation.requested == true`, `cancellation.requested_at` set,
  `cancellation.confirmed == false`.
- The task's `status` is **unchanged** by the request in most cases. It stays `running` (or
  `queued`/`needs_approval`) until a legal transition occurs.
- The request must be persisted, not held only in a queue message or cache: an API restart must not
  lose cancellation intent. Signals to the worker are best-effort hints; the durable record is the
  contract, and the worker re-checks it at its cancellation checkpoints.

### 5.2 Cancellation confirmed by the worker

- The worker has observed the request, stopped or abandoned execution, and persisted the transition
  to `cancelled`.
- Representation: `status == "cancelled"`, `cancellation.confirmed == true`,
  `cancellation.confirmed_at` set, `finished_at` set.
- `cancelled` is terminal (`SPEC.md`). A confirmed cancellation is never reopened.
- Only the worker (or a controlled domain operation acting for it) may set `confirmed`. The API
  handler for `/cancel` must never fabricate confirmation.
- Progress must be honest in the window between request and confirmation: the UI shows "cancelling",
  not "cancelled" (`PR-015`).

### 5.3 Already terminal

| Situation | Response |
|---|---|
| Task already `cancelled` | `409 conflict_task_terminal`. `meta.current_state = "cancelled"`; the client should read the snapshot. No state change. |
| Task already `completed` or `failed` | `409 conflict_task_terminal`. The task is not cancelled and will not be; a completed task is not retroactively cancelled. |
| Task missing or not permitted | `404 not_found` (§4.6) |

Rationale for `409` rather than a silent `202`: a client that believes it cancelled a completed task
has a wrong mental model of the outcome, and that must be visible. Alternatively a convenience mode
could return `200` with the terminal snapshot — **Unresolved decision** (§11); if chosen, it must be
documented and consistent with the CLI and dashboard.

### 5.4 Idempotency of repeated cancellation

- Repeated `POST /cancel` while `cancellation.requested == true` and the task is non-terminal:
  **`202` again**, no duplicate intent record, no error. `cancellation.requested_at` retains the
  **first** request's timestamp, so retries do not rewrite history.
- Repeated cancel after confirmation: `409 conflict_task_terminal` (§5.3).
- `Idempotency-Key` is **not required** for cancel, because the operation is naturally idempotent by
  task and state. It may still be sent; it must not change the outcome.
- Cancellation interacts with retries: a cancellation request must not be silently discarded when a
  retry begins. Either the retry honors the cancellation at its next checkpoint, or the task records a
  deliberate, auditable decision not to. A cancelled task must never be resurrected into `running`
  without an explicit new task or a documented retry transition (`SPEC.md`).

---

## 6. Approval semantics

### 6.1 Who may approve

- Only an **authenticated human principal** authorized for the task's tenant/project **and** for the
  pending approval's scope may approve or reject. Scope is explicit (`tool:repository.write`,
  `deploy:staging`, …) — a grant for one scope must not satisfy another.
- **Approval cannot be granted by model output, by a tool call, by retrieved content, by a repository
  file, or by the agent that requested it.** Those are untrusted data (`ARCHITECTURE.md` §4,
  `SECURITY.md`). No API surface accepts a model-supplied token as a decision, and no tool is granted
  a permission that lets it self-approve.
- Policy may forbid self-approval (requester == approver) for certain scopes. Whether that is enforced
  and for which scopes is an **Unresolved decision** (§11), but the audit record must always identify
  the requester and the approver separately so the check is possible.
- The CLI approves through the same endpoint with the same authorization; there is no privileged CLI
  path (`SECURITY.md` review checklist: "Approval gates cannot be bypassed through alternate
  API/CLI paths").

### 6.2 No decision pending

- If `status != "needs_approval"`, or `pending_approval` is null, or the supplied `approval_id` does
  not match the currently pending gate, the request is rejected with
  `409 conflict_approval_not_pending` and `meta.current_state`.
- The API must **not** queue a decision for a future gate. A decision is about a specific, already-
  pending gate identified by `approval_id`; speculative approvals would let a client pre-authorize an
  operation it has not seen.
- If the task is simultaneously terminal, `409 conflict_task_terminal` takes precedence, since it is
  the more specific truth about the task.

### 6.3 Approve and reject

**Owner-approved 2026-10-13** (`docs/decisions/0010-approval-outcome-transitions.md`). The outcomes below are settled, not proposals.

- **Approve**: records the decision, transitions `needs_approval → running`, resumes the workflow at the gated step, and emits `approval.granted`. The approval is **single-use** and bound to the recorded action scope and state version.
- **Reject**: records the decision and transitions `needs_approval → failed` with `terminal_reason = approval_rejected`. The gated action is **permanently refused for that attempt** — the model cannot re-request it and have it execute. It is *not* mapped to `cancelled` (which would misattribute the cause) and *not* to `blocked` (which would imply a resolvable external dependency).
- Either way the decision is **immutable** once recorded. Changing a decision requires a new gate, not an edit. A later re-attempt is a **new attempt or a new task** with a new approval requirement.

### 6.4 Expiry of a pending approval

- Pending approvals have an `expires_at`. **Accepted default: 24 hours**, configurable by task type.
- **On expiry the task transitions `needs_approval → failed` with `terminal_reason = approval_expired`.** Expiry is recorded distinctly from rejection so that timeout is observable as its own outcome.
- **Expiry is never approval and never authorizes execution.** A silent expiry that leaves the task in `needs_approval` forever is unacceptable; a fall-through to `running` is a security defect.
- `blocked` is **not** the expiry outcome. It remains reserved for a non-approval policy condition that prevented the gate from being evaluated at all.
- After expiry, a late approval attempt returns `409 conflict_approval_not_pending`, and if the gate was replaced by a newer one, the stale `approval_id` is rejected explicitly rather than being applied to the new gate.

### 6.5 Recorded data

Every approval record must persist, at minimum:

| Field | Meaning |
|---|---|
| `approval_id` | Opaque identifier of the specific gate |
| `task_id`, `attempt` | Which task and attempt the gate belongs to |
| `scope` | Exactly what was being authorized |
| `requested_at` | When the gate opened |
| `requested_by` | The workflow/stage that requested it (never a human approver) |
| `expires_at` | Expiry bound |
| `decision` | `approve` / `reject` / `expired` / `superseded` |
| `decided_at` | When the decision was recorded |
| `decided_by` | The authenticated principal |
| `reason` | Optional, sanitized, bounded |

Approval records are audit data: retention applies, and the record must not contain secrets, raw
prompts, or unrestricted tool output (`SECURITY.md`). `approval.granted` / `approval.rejected` /
`approval.expired` events must be emitted and persisted, not only streamed (§7.6).

---

## 7. SSE event contract

The event stream is a **transport for change notification**, not the authoritative record. This
distinction drives most of the rules below.

### 7.1 Framing

- Response: `200 OK`, `Content-Type: text/event-stream`, and `Cache-Control: no-store`.
- Each event is a block of `field: value` lines terminated by a blank line, per the SSE specification.
- Fields used: `id`, `event`, `data`. `retry:` is not used by the server; reconnect delay is the
  client's decision. `data` is **always** a single-line compact JSON object.
- Because `data` must not contain raw newlines, all payload strings are JSON-escaped (`\n`). Never
  emit multi-line `data`; it makes client parsing and non-browser proxies fragile.
- No comment lines except as heartbeats (§7.5).

```text
id: 41
event: task.status_changed
data: {"schema_version":1,"task_id":"task_01JQ8Z2K7V9M4C3T6B0R5N8H2X","event_id":41,"seq":41,"occurred_at":"2026-01-31T14:07:22.004Z","from_status":"running","to_status":"needs_approval","actor":"worker","attempt":1,"reason":"awaiting_write_approval"}
```

- `schema_version` — **Proposed**: an integer identifying the event payload schema, allowing additive
  evolution (§8) without breaking deployed clients.
- `event_id` and `seq` are duplicated deliberately: `event_id` is the resumable stream cursor echoed
  in `id`, while `seq` is the task-scoped monotonic sequence useful for ordering and gap detection.
  **Proposed**: they are equal in the MVP; splitting them later is additive.

### 7.2 Event ID design (monotonic and replayable)

- Event IDs are **monotonically increasing integers per task**, persisted with the event row, assigned
  inside the same transaction that persists the state change. IDs are never reused and never
  renumbered, including after a worker restart, a redeploy, or a crash.
- Consequences that must be accepted:
  - A gap in IDs means an event was not delivered to this client (or is not retained) — not that an
    ID was "skipped by design". Clients detect gaps via `seq` and reconcile with a snapshot.
  - IDs are **not** globally unique and not meaningful outside their task. They must not be used as
    authorization or as a database key shared across tasks.
- Retention is bounded, so replay is bounded. An ID older than the retained window cannot be replayed.
- The ID must be assigned at **persist** time, not at **emit** time, so multiple API replicas streaming
  the same task cannot disagree about ordering.

### 7.3 Event type table

**Proposed** set. `task.status_changed` and the terminal events are the minimum required for `PR-006`
and `PR-008`; the rest are additive convenience.

| `event` | Payload (in addition to the common envelope) | Emitted when |
|---|---|---|
| `task.snapshot` | `status`, `created_at`, `updated_at`, `attempt`, `cancellation`, `pending_approval`, `progress` | On every successful stream connect, before any other event; on reconnect after replay as a reconciliation anchor |
| `task.status_changed` | `from_status`, `to_status`, `actor`, `attempt`, `reason` | On every persisted state transition (`SPEC.md`) |
| `task.progress` | `stage`, `percent`, `message`, `coalesced_count` | Worker reports stage progress; rate-limited and coalesced (§7.8) |
| `task.stage_changed` | `from_stage`, `to_stage`, `attempt` | Plan/execute/verify/report stage boundaries |
| `task.attempt_changed` | `attempt`, `reason` | A retry is deliberately recorded as a new attempt |
| `task.log` | `level` (`info`/`warn`/`error`), `message` | Selected sanitized worker milestones. **Never** raw model or tool output, secrets, or repository contents |
| `approval.requested` | `approval_id`, `scope`, `requested_at`, `expires_at`, `summary` | A gate opens (`approval.requested` accompanies `to_status: needs_approval`) |
| `approval.granted` | `approval_id`, `decided_at`, `decided_by`, `scope` | An authorized human approved |
| `approval.rejected` | `approval_id`, `decided_at`, `decided_by`, `scope`, `reason` | An authorized human rejected |
| `approval.expired` | `approval_id`, `expired_at`, `scope` | The gate expired without a decision (§6.4) |
| `task.cancellation_requested` | `requested_at`, `requested_by` | A cancel request was durably recorded (§5.1) |
| `task.cancelled` | `confirmed_at`, `actor` | Worker confirmed cancellation; `status == cancelled` (§5.2) |
| `task.completed` | `finished_at`, `result_summary`, `verification_status` | Terminal success. Summary only — full results come from the snapshot |
| `task.failed` | `finished_at`, `code`, `message`, `attempt` | Terminal failure, with a stable `code` from §3.3 where applicable |
| `task.blocked` | `reason`, `requires` | Task cannot proceed pending a dependency or policy condition |
| `task.stream_error` | `code`, `message`, `retryable` | Server cannot continue the stream but the task is unaffected (for example an internal stream fault). The client must reconnect and reconcile |
| `snapshot_required` | `reason` (`replay_window_exceeded`, `truncated`, `server_restart`) | The server cannot guarantee contiguity; the client **must** fetch `GET /api/v1/tasks/{task_id}` now (§7.7) |
| `stream.keepalive` | `server_time` | Heartbeat; carries no state |

Rules:

- Every event carries the common envelope: `schema_version`, `task_id`, `event_id`, `seq`,
  `occurred_at`, and `event`. Payload fields are added alongside, not nested in a second wrapper —
  **Proposed** for simpler client typing.
- `occurred_at` is the time the fact occurred and was persisted, not the time it was written to the
  socket. Replayed events keep their original `occurred_at`.
- Terminal events (`task.completed`, `task.failed`, `task.cancelled`) are always emitted for the
  transition; a client that sees one should still reconcile with a snapshot, because events can be missed.
- Event payloads must never contain provider credentials, raw prompts, raw tool output, or repository
  file contents (`PR-012`, `SECURITY.md`).

### 7.4 Ordering guarantees

- Events for a single task are delivered in **strictly increasing `seq`** order on a single
  connection. No two events for the same task share a `seq`.
- Ordering across different tasks is **not** guaranteed, and clients must not rely on it.
- A client that receives `seq` values out of order or with gaps on a live connection must treat the
  stream as suspect: reconnect and reconcile with the snapshot.
- Replay is contiguous: a successful `Last-Event-ID` replay starts at `id + 1` and continues without gaps up to the live edge.

### 7.5 Heartbeat and keepalive

- **Proposed interval: every 15 seconds of idle time.** Configurable, but the value must be documented
  and shorter than common intermediary idle timeouts (proxies and load balancers frequently cut
  connections at 30–60 s).
- Framing: a **comment** line, which is valid SSE and ignored by conforming clients.

```text
: keepalive 2026-01-31T14:12:00Z

```

- A heartbeat must **not** consume a task `seq` and must **not** be persisted as task history. If a
  `stream.keepalive` event is used instead of a comment (some clients want observable liveness), it
  carries its own transport-level counter, not the task sequence — **Unresolved decision** (§11).
- If the server fails to write a keepalive or event within a bounded write deadline, it must close the
  connection rather than hold it open silently.

### 7.6 Reconnect and `Last-Event-ID`

- Clients reconnect by re-issuing `GET /api/v1/tasks/{task_id}/events` with the header
  `Last-Event-ID: <last successfully processed id>`, or with a `last_event_id` query parameter where
  headers are unavailable — **Proposed** fallback.
- Server behaviour on `Last-Event-ID`:
  1. Authorize the request **again** (§2.2). A reconnect is a new request; a previously authorized
     connection grants nothing.
  2. If the ID is within the retained window: replay events with `id > Last-Event-ID` in `seq` order,
     then continue live. Emit a `task.snapshot` only if the client asked for one or if replay could
     not be guaranteed contiguous.
  3. If the ID is older than retention, unknown, malformed, or belongs to another task: **do not**
     guess. Emit `snapshot_required` with `reason`, then continue live from the present. Do not create
     duplicate or renumbered IDs to "fill" the gap.
  4. If the task is terminal and the client is already past the terminal event, close the stream after
     emitting the final snapshot — with a bounded grace period — rather than holding a dead connection
     open.
- Duplicate delivery on reconnect is expected and must be harmless: clients dedupe by `id`.
- Clients must apply **exponential backoff with jitter** on repeated reconnect failure, and must not
  treat reconnection as an error state in the UI. `PR-015` requires an explicit "reconnecting" state,
  distinct from "error".
- Sending `Last-Event-ID` is a **hint**, not an authorization or a guarantee. The server may always
  answer with `snapshot_required`.

### 7.7 Snapshot reconciliation rule

**The stream is not the authoritative record.** After **every** reconnect — and on receipt of
`snapshot_required`, `task.stream_error`, or any detected `seq` gap — the client **must** fetch
`GET /api/v1/tasks/{task_id}` and treat that response as the truth. Consequences:

- The client must never compute a final answer purely from streamed events, and must never leave a
  task displayed as `running` because no terminal event arrived. The snapshot is how a missed terminal
  event is discovered.
- `GET` is also the **polling fallback** for environments where SSE is blocked by a proxy; whether
  that fallback is required (and at what interval) is an **Unresolved decision** (§11).
- Replay and snapshot are complementary: replay fills in *what happened*, the snapshot states
  *where things are now*. If they disagree, the snapshot wins.
- The dashboard must render the reconciled state, not merge the two heuristically.

### 7.8 Backpressure and noisy progress

- Task state transitions and approval events are **never** dropped or coalesced. Missing one is a
  correctness problem.
- `task.progress` is advisory and **may** be coalesced, throttled, or dropped under load. **Proposed**:
  at most ~4 progress events per second per connection, coalescing to the latest values and setting
  `coalesced_count` so the client can tell that intermediate updates were summarized.
- When a client is slow, apply backpressure to its own connection only: never block a worker, never
  block other connections, and never stall the event writer for the whole task. A bounded per-connection
  buffer must exist; on overflow the server drops progress events first, then emits `snapshot_required`
  if the drop affected non-progress events.
- The client must batch/throttle progress-driven UI updates (`ARCHITECTURE.md` §7, `PR-015`) rather
  than rerendering per event.
- Server-side, emitting an event must not be on the critical path of the worker's state transition:
  persist first, then notify. If notification fails, the persisted state and the snapshot are still correct.

### 7.9 Authorization on connect and reconnect

- Connect and reconnect are independently authorized. Both must check principal, task, operation
  (`stream`), and tenant/project boundary.
- Long-lived streams must be revalidated periodically so a revoked or expired grant does not keep
  streaming indefinitely. On revalidation failure the server emits a final
  `task.stream_error` with `code` from §3.3 (for example `unauthenticated`) and closes the stream.
- A stream must never be used to observe a task the caller could not fetch via
  `GET /api/v1/tasks/{task_id}`. The two routes must share one authorization decision path so they
  cannot drift (`SECURITY.md` review checklist).
- `task_id` in the URL is not authorization; neither is a previously working connection.

### 7.10 Worker death and API restart

| Event | Required behaviour |
|---|---|
| Worker crashes mid-task | Persisted state remains at the last transition. The task does not silently become `completed` or `failed`. Recovery is governed by the dispatch/retry design (`ARCHITECTURE.md` §Worker, `PR-011`). The stream may go quiet; heartbeats continue. Clients reconcile from the snapshot and see the true state. |
| Worker restarts and resumes | Event IDs continue **monotonically** from the persisted maximum; no renumbering, no reuse. Checkpoint recovery may replay work but must not re-emit an event with an already-used `id`. |
| API instance restarts | Streams drop. Clients reconnect with `Last-Event-ID`. If in-memory fan-out was lost, the server answers `snapshot_required` (`server_restart`) rather than pretending continuity. Persisted events remain replayable. |
| Redis unavailable | Because Redis is never the only durable store, event history and task state remain readable from PostgreSQL. Loss of Redis may degrade fan-out latency, not correctness. |
| Database unavailable | Streams cannot be authorized or replayed reliably: fail closed. Do not stream unverified state. |
| Task terminal while a client is connected | Emit the terminal event, then close after a bounded grace period; a reconnect to a terminal task yields a final `task.snapshot` and a clean close. |

### 7.11 Annotated example stream

```http
GET /api/v1/tasks/task_01JQ8Z2K7V9M4C3T6B0R5N8H2X/events HTTP/1.1
Accept: text/event-stream
Last-Event-ID: 39
X-Request-ID: 3f6d1c88-2a4b-4d20-9f57-0c1b7e5a9d33
```

```text
: keepalive 2026-01-31T14:07:00Z
                                  <- heartbeat comment; ignored by client, keeps proxies open

id: 40
event: task.snapshot
data: {"schema_version":1,"event":"task.snapshot","task_id":"task_01JQ8Z2K7V9M4C3T6B0R5N8H2X","event_id":40,"seq":40,"occurred_at":"2026-01-31T14:07:21.870Z","status":"running","updated_at":"2026-01-31T14:07:21.870Z","attempt":1}
                                  <- reconciliation anchor for this reconnect

id: 41
event: task.status_changed
data: {"schema_version":1,"event":"task.status_changed","task_id":"task_01JQ8Z2K7V9M4C3T6B0R5N8H2X","event_id":41,"seq":41,"occurred_at":"2026-01-31T14:07:22.004Z","from_status":"running","to_status":"needs_approval","actor":"worker","attempt":1,"reason":"awaiting_write_approval"}
                                  <- worker paused; UI must offer an approval decision

id: 42
event: approval.requested
data: {"schema_version":1,"event":"approval.requested","task_id":"task_01JQ8Z2K7V9M4C3T6B0R5N8H2X","event_id":42,"seq":42,"occurred_at":"2026-01-31T14:07:22.010Z","approval_id":"appr_01JQ8ZB3QK7Y2M6P4T9V1W5D8N","scope":"tool:repository.write","requested_at":"2026-01-31T14:07:22.004Z","expires_at":"2026-01-31T14:37:22.004Z","summary":"Apply patch to 3 files and run the test suite."}
                                  <- gate identity; the client must send this approval_id back

: keepalive 2026-01-31T14:07:37Z
                                  <- 15s idle; no timeouts

id: 43
event: task.status_changed
data: {"schema_version":1,"event":"task.status_changed","task_id":"task_01JQ8Z2K7V9M4C3T6B0R5N8H2X","event_id":43,"seq":43,"occurred_at":"2026-01-31T14:10:44.007Z","from_status":"needs_approval","to_status":"running","actor":"principal_01JQ8V2M4N6P8R0T2V4X6Z8B0D","attempt":1,"reason":"approval_granted"}
id: 44
event: approval.granted
data: {"schema_version":1,"event":"approval.granted","task_id":"task_01JQ8Z2K7V9M4C3T6B0R5N8H2X","event_id":44,"seq":44,"occurred_at":"2026-01-31T14:10:44.010Z","approval_id":"appr_01JQ8ZB3QK7Y2M6P4T9V1W5D8N","decided_at":"2026-01-31T14:10:44.007Z","decided_by":"principal_01JQ8V2M4N6P8R0T2V4X6Z8B0D","scope":"tool:repository.write"}

id: 45
event: task.progress
data: {"schema_version":1,"event":"task.progress","task_id":"task_01JQ8Z2K7V9M4C3T6B0R5N8H2X","event_id":45,"seq":45,"occurred_at":"2026-01-31T14:10:51.220Z","stage":"verify","percent":85,"message":"Running verification checks.","coalesced_count":6}
                                  <- 6 intermediate progress updates were summarized; advisory only

id: 46
event: task.log
data: {"schema_version":1,"event":"task.log","task_id":"task_01JQ8Z2K7V9M4C3T6B0R5N8H2X","event_id":46,"seq":46,"occurred_at":"2026-01-31T14:10:58.004Z","level":"info","message":"Verification suite finished."}
                                  <- sanitized milestone; no raw tool output

id: 47
event: task.completed
data: {"schema_version":1,"event":"task.completed","task_id":"task_01JQ8Z2K7V9M4C3T6B0R5N8H2X","event_id":47,"seq":47,"occurred_at":"2026-01-31T14:11:02.900Z","finished_at":"2026-01-31T14:11:02.900Z","result_summary":"Password reset implemented.","verification_status":"passed"}
                                  <- client MUST still fetch GET /api/v1/tasks/{task_id} before
                                     rendering the final result; the summary is not the record
```

Failure-path fragment, showing the non-contiguous case:

```text
id: 48
event: snapshot_required
data: {"schema_version":1,"event":"snapshot_required","task_id":"task_01JQ8Z2K7V9M4C3T6B0R5N8H2X","event_id":48,"seq":48,"occurred_at":"2026-01-31T14:12:30.000Z","reason":"replay_window_exceeded"}
                                  <- replay cannot be guaranteed; fetch the snapshot now, then keep reading

id: 49
event: task.stream_error
data: {"schema_version":1,"event":"task.stream_error","task_id":"task_01JQ8Z2K7V9M4C3T6B0R5N8H2X","event_id":49,"seq":49,"occurred_at":"2026-01-31T14:12:31.400Z","code":"service_unavailable","message":"Stream backend unavailable.","retryable":true}
                                  <- server closes the connection after this; the task itself is unaffected
```

---

## 8. Versioning and compatibility

### 8.1 Additive changes (allowed within `/api/v1`)

- Adding a **new optional request field** with a documented default.
- Adding a **new response field** to an existing object.
- Adding a **new endpoint** under `/api/v1`.
- Adding a **new error `code`** or a new `details.reason` token.
- Adding a **new SSE `event` type**, or adding optional fields to an existing event payload, with
  `schema_version` unchanged for optional additions and incremented for shape changes.
- Relaxing a constraint (larger maximum, wider accepted format).

Clients must ignore unknown fields and unknown event types. A client that breaks on an unknown event
type is a client bug, not an API break.

### 8.2 Breaking changes (require `/api/v2` or an owner decision)

- Removing or renaming a field, endpoint, error `code`, or event type.
- Changing a field's type, nullability, units, or timestamp format.
- Tightening a documented constraint so previously valid requests fail.
- Changing the meaning of an existing `code` or status.
- Changing default pagination behaviour such that existing cursors break.

### 8.3 Deprecation policy — **Proposed**

1. Mark the field/endpoint/event as deprecated in the contract and in generated clients (OpenAPI
   `deprecated: true` where applicable).
2. Emit machine-readable deprecation signals: `Deprecation` and `Sunset` response headers on the
   affected endpoint.
3. Document the replacement and the removal milestone in `docs/decisions/` and in this file.
4. Maintain the deprecated item for **at least one minor release cycle** after the replacement ships,
   and never remove it in the same release that introduces the replacement.
5. Remove only in a major version, with the changelog entry and the migration note published together.

No deprecation timeline has been agreed; the above is a proposal, not policy.

### 8.4 How the CLI and dashboard consume contracts

- **OpenAPI is the single machine-readable contract** — **Proposed**. FastAPI generates it from
  Pydantic schemas; the generated document is the source for both generated clients and contract tests.
- **Python must not be imported by TypeScript** (`ARCHITECTURE.md` §3): the dashboard must never reach
  into the Python package. Contracts cross the boundary as schema, not as code.
- TypeScript types are **generated from the OpenAPI document** into `packages/shared-types/`
  (**Proposed layout**; the directory does not exist yet). Hand-written duplicate interfaces are
  prohibited because they drift silently.
- The Python CLI consumes the same HTTP API and the same generated/shared schema; it must not
  re-implement business logic or maintain a private contract (`PR-004`, `PR-014`).
- Generated artifacts must not be silently hand-edited. Either fix the schema or record the divergence.
- Contract tests should assert the error envelope, status codes, and SSE framing
  (see [`TESTING.md`](TESTING.md) "API integration tests").
- The OpenAPI document cannot fully describe SSE. The SSE contract in §7 is normative text and must be
  kept in sync with the implementation manually; that gap is a known limitation, not a solved problem.

---

## 9. Caching and performance headers

### 9.1 What may be cached

| Response | Cacheable | Guidance |
|---|---|---|
| `POST /api/v1/tasks` | Never | State-changing; also carries idempotency semantics |
| `POST .../cancel`, `POST .../approval` | Never | State-changing |
| `GET /api/v1/tasks/{task_id}` | Not by intermediaries while live | `Cache-Control: no-store` for non-terminal tasks. A private, short-lived cache may be acceptable for terminal tasks with explicit validation — **Proposed**. |
| `GET /api/v1/tasks/{task_id}` (terminal) | Conditionally | **Proposed**: `Cache-Control: private, max-age=0, must-revalidate` plus `ETag` |
| `GET /api/v1/tasks/{task_id}/events` | Never | `Cache-Control: no-store`; SSE must not be buffered by intermediaries (`X-Accel-Buffering: no`) |
| `GET /api/v1/tasks` (list) | No | Highly mutable; `no-store` |
| Any error response | Never | `no-store` |

Rules:

- **Any response containing task data is `private` at most, never `public`.** A shared cache must not
  be able to serve one tenant's task to another. Authorization is per request regardless of caching.
- `Vary` must include the request's authorization-relevant headers (for example `Authorization`) so a
  cache cannot confuse two principals. Get this wrong and caching becomes a security defect.
- Never cache a response that depended on a time-sensitive authorization decision without
  revalidating.

### 9.2 `ETag` and conditional requests — **Proposed optimization**

- `GET /api/v1/tasks/{task_id}` may return a strong `ETag` derived from the task's version/`updated_at`
  and the caller-visible field set. It must change on every persisted transition and must not be
  guessable across tenants.
- Clients may send `If-None-Match` and receive `304 Not Modified` with no body. This is valuable for
  polling fallback and for long-idle task views, not for a live SSE stream.
- `304` responses must still include `X-Request-ID` and must not be used to convey state changes.
- Do **not** use `ETag` for optimistic concurrency on writes in the MVP (`If-Match` on cancel/approval)
  — the state machine and `approval_id` already prevent the important races. Adding `If-Match` to
  cancellation is an **Unresolved decision** (§11).

### 9.3 Latency

No latency target stated anywhere in this document is met, measured, or implied. Budgets
(API reads p95 < 100/200 ms, submission p95 < 200 ms, INP ≤ 200 ms, LCP ≤ 2.5 s) are **unverified
targets** owned by [`PERFORMANCE.md`](PERFORMANCE.md). Any claim about this API's performance requires
recorded evidence: environment, runtime versions, workload, concurrency, warm/cold state, duration,
percentiles, and the exact command. Because no implementation exists, there is currently **no
measurement to report**.

### 9.4 Operational endpoints — health, readiness, and metrics

**Owner-approved 2026-10-13.** These endpoints are **unversioned and outside `/api/v1`**. They are not part of the product contract and must not appear in the generated client. `ARCHITECTURE.md` §8 and `docs/decisions/0004-deployment-topology.md` require them; `SR-21` constrains their content.

| Endpoint | Process | Purpose | `200` when | `503` when | Access |
|---|---|---|---|---|---|
| `GET /healthz` | API | Liveness: the process is up and the event loop is responsive | Always, if the process is serving | Never — if it answers, it is live | **Public** |
| `GET /readyz` | API | Readiness: can serve real traffic | Database reachable **and** migrations at head | Database unreachable or schema behind | **Public** |
| `GET /healthz` | Worker | Liveness | Always, if the process is serving | Never | **Public** |
| `GET /readyz` | Worker | Readiness: can claim work | Database reachable **and** a claim can be acquired (or the dispatcher is reachable) | Cannot claim work | **Public** |
| `GET /metrics` | API, Worker | Metrics scrape | — | — | **Internal-only or token-gated.** Never public without authentication or a network restriction |

Rules:

- **Readiness must report dependency failures honestly.** If the database is unreachable, `/readyz` returns `503` — it must not return `200` and let a load balancer route traffic to a process that cannot serve it. A readiness check that always returns `200` is worse than no check, because it hides outages.
- **`SR-21` — no information disclosure.** The body carries no version, commit SHA, hostname, connection string, driver error text, or configuration detail. Return `{"status":"ok"}` or `{"status":"degraded"}`. Log the detail server-side; never return it. `/metrics` is protected precisely because metric names and labels can leak topology and traffic shape.
- **Readiness must be cheap.** A pooled `SELECT 1` with a short timeout — not a deep diagnostic. It runs frequently and must not become load.
- **Distinct API and worker readiness.** An operator must be able to distinguish "the API is up" from "work is actually progressing". A single shared endpoint cannot express that, and that distinction is exactly what `ARCHITECTURE.md` requires.
- **Unauthenticated by design.** A load balancer or orchestrator cannot supply credentials, so health and readiness cannot sit behind the product auth. Their safety comes from leaking nothing (`SR-21`) and from being non-mutating.
- **No state changes, no side effects.** A readiness probe must never mutate data, claim work, or advance anything.

---

## 10. Open decisions requiring the owner

Each of the following is unresolved and must be recorded as an ADR with alternatives and consequences
before the affected endpoints are implemented. Nothing here is approved by being written down.

| # | Decision | Why it cannot be defaulted silently |
|---|---|---|
| 1 | **Authentication mechanism** (§2.3) | Determines the CLI credential store, the browser/SSE flow, CSRF obligations, and revocation. Security-relevant; `ARCHITECTURE.md` §12 lists it as open. |
| 2 | **Tenancy model** (§2.4) | Determines every authorization query and whether cross-tenant leakage is structurally possible. A wrong default here is a data-disclosure defect. |
| 3 | **Pagination strategy** (§1.6) | Cursor vs offset changes the list contract and what clients must persist; changing later is breaking. |
| 4 | **Event-history retention** (§7.2) | Bounds replay, incident investigation, storage cost, and the privacy/retention policy for prompts, logs, and checkpoints. |
| 5 | **Long-poll / polling fallback for SSE** (§7.7) | Required if proxies block SSE. Changes client architecture and adds load; must be decided deliberately, not discovered in production. |
| 6 | **`403` vs `404` disclosure policy** (§4.6) | A deliberate, documented anti-enumeration choice; changing it later changes observable API behaviour. |
| 7 | **`Idempotency-Key` required or optional** (§1.8) | Optional idempotency fails silently on retry; required idempotency shifts work to clients. |
| ~~8~~ | **Approval rejection and expiry outcomes — RESOLVED 2026-10-13** | **`needs_approval → failed`**, with `terminal_reason` of `approval_rejected` or `approval_expired`. Default expiry 24 h, configurable by task type. Expiry never authorizes execution. See §6.3, §6.4 and `docs/decisions/0010-approval-outcome-transitions.md`. |
| 9 | **Self-approval policy** per scope (§6.1) | A separation-of-duties control with real audit consequences. |
| 10 | **Cancel-on-terminal response** (`409` vs `200` snapshot) (§5.3) | Changes client error handling and must match CLI/dashboard behaviour. |
| 11 | **Concrete size, rate, and retention numbers** (§1.9, §7.8) | Bounds must be chosen with cost and abuse tolerance in mind; undocumented limits become support incidents. |
| 12 | **`stream.keepalive` event vs comment-only heartbeat** (§7.5) | Affects client liveness detection and whether heartbeat traffic touches the task sequence. |
| 13 | **`If-Match`/optimistic concurrency on writes** (§9.2) | Decides whether write races are resolved by state machine alone or additionally by precondition checks. |
| ~~14~~ | **Project scoping — RESOLVED 2026-10-13** | **No project entity or project-scoped endpoint in the MVP.** `project_id` is removed from the create-task contract; **workspace tenancy** (`docs/decisions/0003`) is the isolation boundary and is derived from the authenticated principal, never supplied by the client. Adding a project concept later is an additive change, not a reason to carry the field now. |
| 15 | **Terminal-state retry path** (`Design-system.md` describes `failed` as "retryable") | `SPEC.md` makes `failed` terminal and no retry endpoint exists, so a retry affordance in the UI is unusable and would return `conflict_task_terminal`. Either a retry endpoint/new-attempt flow is specified, or the UI must present `failed` as terminal. |

## 11. Related documents

- [`../SPEC.md`](../SPEC.md) — authoritative task lifecycle, transitions, and externally observable behavior; this document must never contradict it.
- [`../PRD.md`](../PRD.md) — product requirements `PR-001`..`PR-015` and MVP acceptance criteria.
- [`../ARCHITECTURE.md`](../ARCHITECTURE.md) — components, dispatch reliability, worker, Redis, and performance strategy.
- [`../PROJECT_CONTEXT.md`](../PROJECT_CONTEXT.md) — source-of-truth map, verified repository state, conflict resolution order.
- [`../CODE_STYLE.md`](../CODE_STYLE.md) — engineering conventions; this document follows its API/domain rules.
- [`SECURITY.md`](SECURITY.md) — security baseline, authorization requirements, secret handling, audit.
- [`THREAT_MODEL.md`](THREAT_MODEL.md) — assets, trust boundaries, STRIDE analysis, and mitigations this API contract must serve.
- [`TESTING.md`](TESTING.md) — required API integration, SSE reconnect, error-contract, and lifecycle tests for the contracts above.
- [`PERFORMANCE.md`](PERFORMANCE.md) — authoritative performance budgets and benchmark protocol; §9.3 defers to it.
- [`DATABASE.md`](DATABASE.md) — persistence, indexing, retention, and ownership for tasks, events, approvals, and audit records.
- [`AGENT_RUNTIME.md`](AGENT_RUNTIME.md) — adapter interfaces, workflow stages, execution bounds, and failure handling that produce these events.
- [`decisions/0010-approval-outcome-transitions.md`](decisions/0010-approval-outcome-transitions.md) — the **accepted** decision on rejection/expiry outcomes referenced in §6.3, §6.4, and §10.

# 0008. Database identity strategy and migration tooling

- **Status:** **Proposed** — required before the first migration
- **Date:** 2026-10-12
- **Deciders:** project owner (decision required); agent recommendation
- **Related requirements:** PR-001, PR-002, PR-003, PR-011
- **Related documents:** `docs/DATABASE.md`, `SPEC.md` § Task lifecycle, `docs/API_CONTRACTS.md`, `docs/SECURITY.md`

## Context

`SPEC.md` shows `task_id` as an "opaque-stable-id" and states the format is an implementation decision, while `docs/SECURITY.md` insists an opaque ID is not authorization. `docs/DATABASE.md` flags primary-key strategy and migration tooling as unresolved.

Two distinct concerns are often conflated and should be separated:

- **Storage identity** — the internal primary key used for joins and foreign keys. Optimizing for index locality and insert performance favors sequential keys.
- **Public identity** — the identifier exposed in URLs, events, and API responses. Optimizing for unguessability and non-enumerability favors random, non-sequential values.

Additionally, the schema will evolve through the MVP, and `ARCHITECTURE.md` requires migrations. The tool choice affects how safely schema changes can ship.

## Decision (recommended)

1. **Separate storage identity from public identity.**
   - Internal primary key: a sequential/ordered type such as `bigint GENERATED ALWAYS AS IDENTITY` for index locality and compact foreign keys. Alternatively a time-ordered UUID (UUIDv7) if distributed ID generation is ever needed.
   - Public identifier: a separate `public_id` column, **UUIDv7 or ULID** — random enough to resist enumeration, time-ordered enough to index well — exposed in all API responses, event payloads, and URLs. Never expose the internal sequential key.
   - Enforcement: a unique constraint and index on `public_id`; API serializers expose only `public_id`; a test asserts the internal key never appears in a response.
2. **Migration tooling: Alembic**, if SQLAlchemy is the chosen data layer (see below), because it is the mature, well-understood default with autogeneration and explicit revision history. Alternative: plain versioned SQL migrations applied by a small runner if the project avoids an ORM.
3. **Migrations are code and are reviewed.** Versioned, forward-only in practice, applied in CI against a disposable database, and never edited after being applied to a shared environment.
4. **Use the expand/contract pattern for any breaking schema change:** add the new column/table, backfill, dual-write or dual-read as needed, switch readers, then remove the old structure in a later migration. Destructive changes are separate, later, and deliberate.
5. **Migrations are not run by documentation or by application startup implicitly.** They are an explicit, observable deployment step with a recorded outcome.

## Alternatives considered

- **Expose the sequential primary key as the public ID.** Simplest; fewer columns and no lookup by a second key. Rejected: sequential IDs are trivially enumerable, invite resource-probing, and leak task volume and creation order. Even with correct authorization this is unnecessary information disclosure.
- **UUIDv4 (fully random) as the primary key.** Good unguessability. Rejected as the *storage* key: random inserts fragment B-tree locality and enlarge indexes at scale. Acceptable as the public ID, though UUIDv7/ULID is preferred for index locality.
- **Composite or natural keys (e.g. `tenant:slug`).** Rejected: brittle under rename, couples identity to mutable user data, and complicates foreign keys.
- **A slug or human-readable public ID.** Rejected as the primary public identifier: enumerable and prone to collisions; usability benefit does not outweigh the exposure. A separate optional display name is a different concern.
- **`created_at`-plus-random composite public token.** Workable, but UUIDv7/ULID achieves the same properties with standard tooling and no custom parsing.
- **Hand-rolled SQL migration files with no tool.** Viable and dependency-light, with full control and transparency. Rejected only because it requires building drift detection and ordering guarantees that mature tools already provide. Reasonable if the owner prefers minimal dependencies.
- **Auto-migrate on application startup.** Rejected: it makes schema state depend on which process starts first, races between API and worker, and removes the deliberate review step.

## Consequences

**Positive:** non-enumerable public identifiers; good index locality on writes; a clear audit trail of schema evolution; safe, reversible-in-practice schema changes; no ambiguity about which ID is safe to expose.

**Negative / accepted costs:** two identity columns and one extra unique index; a lookup by `public_id` on every API path (cheap, indexed); migration discipline and CI migration testing to maintain; the dual-identity mapping must be consistently applied by every serializer, which needs a test to prevent regression.

**Note:** the choice of ORM versus query builder versus raw SQL is adjacent but separate. It affects whether Alembic is the natural migration tool and should be decided alongside this ADR.

## Verification

- **Unit:** the public-ID generator produces unique, non-sequential, time-ordered values.
- **Integration:** API responses and SSE event payloads expose `public_id` only; an assertion fails if the internal key appears anywhere in a response body.
- **Integration:** a task created with a sequential internal key is fetched by its `public_id` and authorized correctly.
- **CI:** migrations apply cleanly from an empty database to head, and the resulting schema matches the documented model.
- **CI:** a second migration run on an up-to-date database is a no-op (idempotent application).
- **Review:** no migration edits an already-applied revision; breaking changes use expand/contract.

## Open questions for the owner

1. Approve the split storage/public identity, or expose a single opaque ID as both?
2. ORM (SQLAlchemy) versus raw SQL with a query layer — which shapes the migration tool choice?
3. Approve Alembic, or prefer hand-rolled versioned SQL migrations?
4. Any requirement for distributed/offline ID generation that would force UUIDs everywhere?

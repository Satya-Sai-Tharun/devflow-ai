# 0004. Deployment topology and environments

- **Status:** **Proposed** — requires owner decision before any deployment work
- **Date:** 2026-10-12
- **Deciders:** project owner (decision required); agent recommendation
- **Related requirements:** PR-005, PR-011, PR-012, PR-013
- **Related documents:** `ARCHITECTURE.md` §8, `docs/SECURITY.md`, `docs/AGENT_RUNTIME.md`, `docs/DATABASE.md`

## Context

The MVP has four independently deployable concerns — dashboard, API, worker, and datastores — and two very different execution profiles: the API must answer in milliseconds, while the worker runs untrusted, repository-modifying agent operations that may execute for minutes and must be sandboxed.

`ARCHITECTURE.md` requires health/readiness checks that "distinguish API health from worker/queue readiness", and `PROJECT_CONTEXT.md` records deployment topology as an unresolved decision. The worker's sandbox requirements make the deployment choice a security decision, not just a convenience one.

## Decision (recommended)

**Local development and CI first, with a container-based production target.**

1. **Local development:** a single `docker compose` (or equivalent) definition bringing up PostgreSQL, the API, the worker, the dashboard, and Redis only if justified. This is the reproducibility baseline that `PRD.md` success metrics call for.
2. **Topology:** run the dashboard, API, and worker as **separate processes/containers** from one image family with different entrypoints. Do not co-locate the worker with the API in the same process or container.
3. **Worker isolation:** the worker container is treated as a **semi-trusted** environment. Agent-executed code and tool invocations run in a further-restricted sandbox (see ADR 0009), not with the worker's full privileges.
4. **Health/readiness:** distinct endpoints — API liveness/readiness (including database reachability) and worker readiness (can claim work, queue reachable) — plus dispatcher/queue-depth visibility.
5. **Environments:** at minimum `local` and `ci`. A `production` environment is defined only when the owner confirms a deployment target; do not build deployment automation speculatively.
6. **Graceful shutdown:** both API and worker must handle termination signals — the worker stops claiming, checkpoints or completes in-flight work, and releases leases.

## Alternatives considered

- **Single process serving API and worker.** Simplest to run. Rejected: it violates the ADR 0001 boundary, lets long-running graph work contend with request handling, and makes the untrusted-execution boundary impossible to enforce.
- **Serverless functions for the API and worker.** Rejected for the MVP: long-running agent work exceeds typical execution limits, durable leases need stable identity, and per-invocation cold starts conflict with the latency budgets. Reconsider only for the API layer if measured load demands it.
- **Kubernetes from the start.** Rejected as premature: `PRD.md` explicitly lists premature distributed infrastructure as a non-goal. Revisit when multiple workers, rolling deploys, or measured scaling needs exist.
- **Bare-metal/systemd deployment.** Viable and simple for a single self-hosted instance, but weaker on reproducibility and environment parity than containers. Acceptable as a documented self-hosted path if the owner prefers it.
- **Remote/managed PostgreSQL from day one.** Deferred; a local container is the right default until backup and retention policy are decided (ADR 0006).

## Consequences

**Positive:** API latency is protected from agent workload; the untrusted execution boundary is enforceable at the process/container level; environment parity improves reproducibility; health signals distinguish "API up" from "work actually progressing".

**Negative / accepted costs:** more processes to operate; container tooling and image build maintenance; a local compose stack to keep working; sandbox implementation effort is now a deployment prerequisite for Milestone 7 rather than an afterthought.

**Risk if deferred:** implementing the worker without a defined isolation boundary tends to produce host-privileged agent execution that is difficult to retrofit into a sandbox.

## Verification

- **Local:** the documented compose command brings up a working stack from a clean checkout (verify and record the actual command before documenting it as working).
- **Integration:** a worker killed with `SIGTERM` stops claiming, releases/lets expire its lease, and the job is reclaimed (ties to ADR 0002).
- **Integration:** API readiness reports unhealthy when the database is unreachable; worker readiness reports unhealthy when it cannot claim work.
- **Security:** an agent-executed process cannot reach the host filesystem outside its sandbox or make unauthorized network egress (ties to ADR 0009 and `docs/THREAT_MODEL.md`).

## Open questions for the owner

1. What is the intended deployment target — single self-hosted host, a PaaS, or a container platform?
2. Must DevFlow AI run fully offline/air-gapped, or may the worker reach external model providers?
3. Is a `production` environment in scope for the MVP, or is local-only acceptable for the first milestone?
4. Acceptable container runtime and orchestration constraints on the target host?

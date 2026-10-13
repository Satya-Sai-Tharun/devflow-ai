# Deployment Readiness Notes

**Status:** Planning guidance only. The repository does not include a production deployment configuration, reverse proxy, secret manager integration, or production security review. The current Compose setup is intended for local development.

The accepted deployment topology decision is recorded in [`decisions/0004-deployment-topology.md`](decisions/0004-deployment-topology.md); this guide covers operational requirements and does not select or configure a production target.

## Build and run

The backend image is built from the repository root with `backend/Dockerfile`; local Compose configuration is in the root `compose.yaml`. A future server deployment can build and run the same backend image, but must provide separate production configuration and reviewed infrastructure. Do not publish the local development Compose settings as a production deployment.

## Production configuration and exposure

- Supply production database credentials and application secrets from a secret manager or deployment platform. Do not use `.env.example` or the development-only values copied by `start-dev.bat`.
- Require HTTPS at a maintained reverse proxy or managed ingress, and configure trusted proxy headers deliberately.
- Keep PostgreSQL and the backend on a private container network. Expose only the reverse proxy's required public ports; do not publish the database port publicly.
- Select production hostnames, CORS policy, authentication, authorization, tenant isolation, and secret rotation before exposing the API. These controls are not implemented by this structural refactor.

## Database and operations

- Persist PostgreSQL data on durable storage and define encrypted, off-host backups plus a tested restore procedure before production use.
- Apply Alembic migrations as a controlled one-shot release step, not from each backend replica's startup. Confirm the target environment and backup/rollback plan before migration.
- Use `/healthz` for process liveness and `/readyz` for database and migration readiness. Restrict operational access as appropriate for the chosen ingress.
- Collect container logs centrally, redact credentials and sensitive payloads, and define retention and alerting.
- Set restart policies and resource bounds to match the server platform; do not treat container restart as database backup or recovery.

## Current limits

The backend does not implement authentication or workspace authorization, and no production secret handling, reverse proxy, TLS, backup, restore, monitoring, or deployment verification is provided here. A security and operations review is required before any public deployment. No cloud resources or production credentials are configured by this repository change.

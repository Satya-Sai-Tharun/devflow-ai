FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim@sha256:e5b65587bce7de595f299855d7385fe7fca39b8a74baa261ba1b7147afa78e58

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON=3.12 \
    PATH="/app/.venv/bin:$PATH"

COPY backend/pyproject.toml backend/uv.lock backend/.python-version ./
RUN uv sync --locked --no-dev --no-install-project

COPY --chown=10001:10001 backend/devflow_api ./devflow_api
COPY --chown=10001:10001 backend/migrations ./migrations
COPY --chown=10001:10001 backend/alembic.ini ./alembic.ini
RUN uv sync --locked --no-dev && groupadd --gid 10001 app && useradd --no-create-home --uid 10001 --gid 10001 app

USER 10001:10001

EXPOSE 8000
CMD ["devflow-api"]

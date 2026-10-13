from collections.abc import Awaitable
from typing import cast

import httpx
import pytest
from fastapi import FastAPI
from pydantic import PostgresDsn
from sqlalchemy.ext.asyncio import AsyncEngine

from devflow_api import health, main


class FakeEngine:
    def __init__(self) -> None:
        self.disposed = False

    async def dispose(self) -> None:
        self.disposed = True


def configure_test_app(monkeypatch: pytest.MonkeyPatch) -> tuple[FastAPI, FakeEngine]:
    monkeypatch.setenv(
        "DEVFLOW_DATABASE_URL",
        "postgresql+asyncpg://devflow:local_only@localhost/devflow",
    )
    engine = FakeEngine()

    def create_engine(_: PostgresDsn) -> AsyncEngine:
        return cast(AsyncEngine, engine)

    monkeypatch.setattr(main, "create_database_engine", create_engine)
    return main.create_app(), engine


async def get(app: FastAPI, path: str) -> httpx.Response:
    async with app.router.lifespan_context(app):
        async with httpx.AsyncClient(
            transport=httpx.ASGITransport(app=app), base_url="http://test"
        ) as client:
            return await client.get(path)


@pytest.mark.asyncio
async def test_health_is_live_without_connecting_to_database(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    app, engine = configure_test_app(monkeypatch)
    monkeypatch.setattr(health, "database_is_ready", _unexpected_database_access)

    response = await get(app, "/healthz")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
    assert engine.disposed


async def _unexpected_database_access(_: AsyncEngine) -> bool:
    raise AssertionError("liveness must not access PostgreSQL")


@pytest.mark.asyncio
async def test_readiness_succeeds_when_database_is_at_migration_head(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    app, _ = configure_test_app(monkeypatch)

    def check(_: AsyncEngine) -> Awaitable[bool]:
        return _ready()

    monkeypatch.setattr(health, "database_is_ready", check)

    response = await get(app, "/readyz")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


@pytest.mark.asyncio
async def test_readiness_degrades_without_disclosing_database_errors(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    app, _ = configure_test_app(monkeypatch)
    monkeypatch.setattr(health, "database_is_ready", _database_error)

    response = await get(app, "/readyz")

    assert response.status_code == 503
    assert response.json() == {"status": "degraded"}
    assert "private-dsn" not in response.text


@pytest.mark.asyncio
async def test_readiness_degrades_when_migrations_are_behind(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    app, _ = configure_test_app(monkeypatch)
    monkeypatch.setattr(health, "database_is_ready", _not_ready)

    response = await get(app, "/readyz")

    assert response.status_code == 503
    assert response.json() == {"status": "degraded"}


async def _ready() -> bool:
    return True


async def _not_ready(_: AsyncEngine) -> bool:
    return False


async def _database_error(_: AsyncEngine) -> bool:
    raise RuntimeError("private-dsn")

import asyncio
import re
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit

import pytest
from alembic import command
from alembic.config import Config
from pytest import MonkeyPatch
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine

from devflow_api.config import load_settings
from devflow_api.database import database_is_ready

pytestmark = pytest.mark.integration


def test_fresh_postgres_migration_and_readiness(monkeypatch: MonkeyPatch) -> None:
    source = load_settings()
    source_url = urlsplit(str(source.database_url))
    database_name = source_url.path.lstrip("/") + "_test"
    is_disposable_name = re.fullmatch(r"[A-Za-z0-9_-]+_test", database_name)
    is_local_database = source_url.hostname in {"localhost", "127.0.0.1", "::1"}
    if source.environment == "production" or not is_disposable_name or not is_local_database:
        pytest.fail("integration tests require a local, non-production disposable database")
    database_url = urlunsplit(source_url._replace(path=f"/{database_name}"))
    monkeypatch.setenv("DEVFLOW_DATABASE_URL", database_url)
    engine = create_async_engine(database_url)

    async def require_empty_test_database() -> bool:
        try:
            async with engine.begin() as connection:
                relations = await connection.scalar(
                    text(
                        "SELECT count(*) FROM pg_class AS relation "
                        "JOIN pg_namespace AS namespace "
                        "ON namespace.oid = relation.relnamespace "
                        "WHERE namespace.nspname NOT IN "
                        "('pg_catalog', 'information_schema') "
                        "AND namespace.nspname NOT LIKE 'pg_toast%' "
                        "AND relation.relkind IN ('r', 'p', 'v', 'm', 'S', 'f')"
                    )
                )
                if relations:
                    pytest.fail("integration database must be empty before the test")
            return await database_is_ready(engine)
        finally:
            await engine.dispose()

    try:
        assert not asyncio.run(require_empty_test_database())

        config = Config(str(Path(__file__).resolve().parents[2] / "alembic.ini"))
        command.upgrade(config, "head")
        assert asyncio.run(database_is_ready_and_dispose(engine))
        command.upgrade(config, "head")
        assert asyncio.run(database_is_ready_and_dispose(engine))
    finally:
        asyncio.run(engine.dispose())


async def database_is_ready_and_dispose(engine: AsyncEngine) -> bool:
    try:
        return await database_is_ready(engine)
    finally:
        await engine.dispose()

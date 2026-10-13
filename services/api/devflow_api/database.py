from __future__ import annotations

import asyncio
import logging
from collections.abc import AsyncGenerator, Sequence
from pathlib import Path

from alembic.config import Config
from alembic.migration import MigrationContext
from alembic.script import ScriptDirectory
from fastapi import Request
from pydantic import PostgresDsn
from sqlalchemy import text
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

LOGGER = logging.getLogger(__name__)
ALEMBIC_CONFIG = Config(str(Path(__file__).resolve().parents[3] / "alembic.ini"))


def create_database_engine(database_url: PostgresDsn) -> AsyncEngine:
    return create_async_engine(
        str(database_url),
        pool_pre_ping=True,
        pool_timeout=1,
        connect_args={"timeout": 1, "command_timeout": 1},
    )


def migration_heads_are_current(current: Sequence[str], expected: Sequence[str]) -> bool:
    return len(expected) == 1 and tuple(current) == tuple(expected)


async def database_is_ready(engine: AsyncEngine) -> bool:
    expected = ScriptDirectory.from_config(ALEMBIC_CONFIG).get_heads()
    if len(expected) != 1:
        return False

    try:
        async with asyncio.timeout(2):
            async with engine.connect() as connection:
                await connection.execute(text("SELECT 1"))
                current = await connection.run_sync(
                    lambda sync_connection: MigrationContext.configure(
                        sync_connection
                    ).get_current_heads()
                )
        return migration_heads_are_current(current, expected)
    except Exception as error:
        LOGGER.warning("database readiness probe failed (%s)", type(error).__name__)
        return False


async def get_session(request: Request) -> AsyncGenerator[AsyncSession, None]:
    session_factory: async_sessionmaker[AsyncSession] = request.app.state.session_factory
    async with session_factory() as session:
        yield session

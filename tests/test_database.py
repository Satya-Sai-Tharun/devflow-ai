from types import SimpleNamespace

import pytest
from sqlalchemy.ext.asyncio import create_async_engine
from starlette.applications import Starlette
from starlette.requests import Request

from devflow_api.database import database_is_ready, get_session, migration_heads_are_current


@pytest.mark.parametrize(
    ("current", "expected", "is_current"),
    [
        (["0001_initial"], ["0001_initial"], True),
        ([], ["0001_initial"], False),
        (["0001_initial"], ["0002_next"], False),
        (["unknown"], ["0001_initial"], False),
        (["0001_initial", "0002_next"], ["0001_initial", "0002_next"], False),
    ],
)
def test_migration_state_requires_one_known_head(
    current: list[str], expected: list[str], is_current: bool
) -> None:
    assert migration_heads_are_current(current, expected) is is_current


@pytest.mark.asyncio
async def test_readiness_fails_closed_when_postgres_is_unavailable() -> None:
    engine = create_async_engine(
        "postgresql+asyncpg://devflow:local_only@127.0.0.1:1/devflow",
        connect_args={"timeout": 0.5, "command_timeout": 0.5},
    )
    try:
        assert not await database_is_ready(engine)
    finally:
        await engine.dispose()


@pytest.mark.asyncio
async def test_session_dependency_closes_session_after_request() -> None:
    fake_context = FakeSessionContext()
    app = Starlette()
    app.state.session_factory = lambda: fake_context
    request = Request(
        {
            "type": "http",
            "asgi": {"version": "3.0"},
            "http_version": "1.1",
            "method": "GET",
            "scheme": "http",
            "path": "/",
            "raw_path": b"/",
            "query_string": b"",
            "headers": [],
            "client": ("test", 1234),
            "server": ("test", 80),
            "app": app,
        }
    )

    request_session = get_session(request)
    session = await anext(request_session)

    assert session is fake_context.session
    assert not fake_context.closed
    await request_session.aclose()
    assert fake_context.closed


class FakeSessionContext:
    def __init__(self) -> None:
        self.session = SimpleNamespace()
        self.closed = False

    async def __aenter__(self) -> SimpleNamespace:
        return self.session

    async def __aexit__(self, *_: object) -> None:
        self.closed = True

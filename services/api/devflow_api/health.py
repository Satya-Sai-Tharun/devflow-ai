from __future__ import annotations

import logging

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncEngine

from devflow_api.database import database_is_ready

LOGGER = logging.getLogger(__name__)
router = APIRouter()


@router.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/readyz")
async def readyz(request: Request) -> JSONResponse:
    engine: AsyncEngine = request.app.state.engine
    try:
        ready = await database_is_ready(engine)
    except Exception as error:
        LOGGER.warning("readiness check failed (%s)", type(error).__name__)
        ready = False
    if not ready:
        return JSONResponse(status_code=503, content={"status": "degraded"})
    return JSONResponse(status_code=200, content={"status": "ok"})

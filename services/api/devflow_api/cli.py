from __future__ import annotations

import json
import logging
from datetime import UTC, datetime

import uvicorn

from devflow_api.config import Settings, load_settings
from devflow_api.main import create_app


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        return json.dumps(
            {
                "timestamp": datetime.fromtimestamp(record.created, UTC).isoformat(),
                "level": record.levelname,
                "logger": record.name,
                "message": record.getMessage(),
            }
        )


def configure_logging(settings: Settings) -> None:
    handler = logging.StreamHandler()
    handler.setFormatter(
        JsonFormatter()
        if settings.log_format == "json"
        else logging.Formatter("%(asctime)s %(levelname)s %(name)s %(message)s")
    )
    logging.basicConfig(level=settings.log_level, handlers=[handler], force=True)


def main() -> None:
    settings = load_settings()
    configure_logging(settings)
    uvicorn.run(
        create_app(),
        host=settings.api_host,
        port=settings.api_port,
        log_config=None,
    )

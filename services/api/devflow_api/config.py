from __future__ import annotations

from typing import Literal, cast

from pydantic import Field, PostgresDsn, ValidationError, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class SettingsError(ValueError):
    """Configuration error with secret-free details."""


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="DEVFLOW_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    environment: Literal["local", "ci", "production"] = Field(
        default="local", validation_alias="DEVFLOW_ENV"
    )
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = "INFO"
    log_format: Literal["text", "json"] = "text"
    api_host: str = "127.0.0.1"
    api_port: int = Field(default=8000, ge=1, le=65535)
    database_url: PostgresDsn

    @field_validator("database_url")
    @classmethod
    def require_asyncpg(cls, value: PostgresDsn) -> PostgresDsn:
        if value.scheme != "postgresql+asyncpg":
            raise ValueError("must use postgresql+asyncpg")
        return value

    @model_validator(mode="after")
    def require_json_logs_in_production(self) -> Settings:
        if self.environment == "production" and self.log_format != "json":
            raise ValueError("DEVFLOW_LOG_FORMAT must be json in production")
        return self


def load_settings(*, env_file: str | None = ".env") -> Settings:
    try:
        return Settings(_env_file=env_file)  # pyright: ignore[reportCallIssue]
    except ValidationError as error:
        details: list[str] = []
        aliases = {"environment": "DEVFLOW_ENV"}
        for item in cast(
            list[dict[str, object]], error.errors(include_input=False, include_url=False)
        ):
            location = item.get("loc")
            message = str(item.get("msg", "invalid value"))
            if isinstance(location, tuple) and not location:
                details.append(message.removeprefix("Value error, "))
                continue
            typed_location = cast(tuple[object, ...], location)
            field = str(typed_location[0]) if typed_location else "configuration"
            name = aliases.get(field, f"DEVFLOW_{field.upper()}")
            details.append(f"{name}: {message}")
        raise SettingsError("Invalid configuration: " + "; ".join(details)) from None

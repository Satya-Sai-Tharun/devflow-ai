import pytest

from devflow_api.config import SettingsError, load_settings


def clear_settings_env(monkeypatch: pytest.MonkeyPatch) -> None:
    for name in (
        "DEVFLOW_ENV",
        "DEVFLOW_LOG_LEVEL",
        "DEVFLOW_LOG_FORMAT",
        "DEVFLOW_API_HOST",
        "DEVFLOW_API_PORT",
        "DEVFLOW_DATABASE_URL",
    ):
        monkeypatch.delenv(name, raising=False)


def test_database_url_is_required(monkeypatch: pytest.MonkeyPatch) -> None:
    clear_settings_env(monkeypatch)

    with pytest.raises(SettingsError, match="DEVFLOW_DATABASE_URL"):
        load_settings(env_file=None)


def test_database_url_must_use_async_postgresql_and_error_hides_credentials(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    clear_settings_env(monkeypatch)
    monkeypatch.setenv(
        "DEVFLOW_DATABASE_URL",
        "postgresql://devflow:do_not_leak_this@localhost/devflow",
    )

    with pytest.raises(SettingsError) as error:
        load_settings(env_file=None)

    assert "DEVFLOW_DATABASE_URL" in str(error.value)
    assert "do_not_leak_this" not in str(error.value)


def test_local_defaults_and_explicit_settings(monkeypatch: pytest.MonkeyPatch) -> None:
    clear_settings_env(monkeypatch)
    monkeypatch.setenv(
        "DEVFLOW_DATABASE_URL",
        "postgresql+asyncpg://devflow:local_only@localhost/devflow",
    )
    monkeypatch.setenv("DEVFLOW_ENV", "ci")
    monkeypatch.setenv("DEVFLOW_API_PORT", "8123")

    settings = load_settings(env_file=None)

    assert settings.environment == "ci"
    assert settings.api_host == "127.0.0.1"
    assert settings.api_port == 8123
    assert settings.database_url.scheme == "postgresql+asyncpg"


def test_production_requires_json_logs(monkeypatch: pytest.MonkeyPatch) -> None:
    clear_settings_env(monkeypatch)
    monkeypatch.setenv(
        "DEVFLOW_DATABASE_URL",
        "postgresql+asyncpg://devflow:local_only@localhost/devflow",
    )
    monkeypatch.setenv("DEVFLOW_ENV", "production")
    monkeypatch.setenv("DEVFLOW_LOG_FORMAT", "text")

    with pytest.raises(SettingsError, match="DEVFLOW_LOG_FORMAT"):
        load_settings(env_file=None)

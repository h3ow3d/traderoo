from __future__ import annotations

import pytest

from traderoo.config import ConfigError, load_settings


def test_config_defaults(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("APP_NAME", raising=False)
    monkeypatch.delenv("APP_ENV", raising=False)
    monkeypatch.delenv("EXECUTION_MODE", raising=False)
    monkeypatch.delenv("REVIEW_PROVIDER", raising=False)

    settings = load_settings()

    assert settings.app_name == "traderoo"
    assert settings.app_env == "poc"
    assert settings.execution_mode == "PAPER_ONLY"
    assert settings.review_provider == "mock"


def test_invalid_execution_mode_fails(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("EXECUTION_MODE", "LIVE")

    with pytest.raises(ConfigError):
        load_settings()

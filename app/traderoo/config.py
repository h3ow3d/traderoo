from __future__ import annotations

import os
from dataclasses import dataclass


_ALLOWED_EXECUTION_MODES = {"PAPER_ONLY"}


@dataclass(frozen=True)
class Settings:
    app_name: str = "traderoo"
    app_env: str = "poc"
    execution_mode: str = "PAPER_ONLY"
    review_provider: str = "mock"


class ConfigError(ValueError):
    """Raised when runtime configuration violates safety constraints."""


def load_settings() -> Settings:
    settings = Settings(
        app_name=os.getenv("APP_NAME", "traderoo"),
        app_env=os.getenv("APP_ENV", "poc"),
        execution_mode=os.getenv("EXECUTION_MODE", "PAPER_ONLY"),
        review_provider=os.getenv("REVIEW_PROVIDER", "mock"),
    )

    if settings.execution_mode not in _ALLOWED_EXECUTION_MODES:
        raise ConfigError(
            "Invalid EXECUTION_MODE. Traderoo MVP only permits EXECUTION_MODE=PAPER_ONLY."
        )

    return settings

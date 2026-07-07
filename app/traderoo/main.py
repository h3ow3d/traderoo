from __future__ import annotations

from fastapi import FastAPI

from traderoo.config import Settings, load_settings


def create_app(settings: Settings | None = None) -> FastAPI:
    runtime = settings or load_settings()

    app = FastAPI(title="Traderoo", version="0.1.0")

    @app.get("/healthz")
    def healthz() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/readyz")
    def readyz() -> dict[str, str]:
        return {
            "status": "ready",
            "execution_mode": runtime.execution_mode,
            "review_provider": runtime.review_provider,
        }

    @app.get("/")
    def root() -> dict[str, str]:
        return {
            "name": runtime.app_name,
            "environment": runtime.app_env,
            "execution_mode": runtime.execution_mode,
            "review_provider": runtime.review_provider,
        }

    return app


app = create_app()

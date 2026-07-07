from __future__ import annotations

from fastapi.testclient import TestClient

from traderoo.main import create_app


client = TestClient(create_app())


def test_healthz() -> None:
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readyz() -> None:
    response = client.get("/readyz")
    assert response.status_code == 200
    assert response.json()["status"] == "ready"
    assert response.json()["execution_mode"] == "PAPER_ONLY"
    assert response.json()["review_provider"] == "mock"


def test_root() -> None:
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {
        "name": "traderoo",
        "environment": "poc",
        "execution_mode": "PAPER_ONLY",
        "review_provider": "mock",
    }

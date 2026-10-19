"""Smoke-test setup.

Tests never touch the app's own data: they run against a separate database
(<POSTGRES_DB>_test, on the same Postgres server) that is rebuilt on every run.
"""

from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, text
from sqlmodel import Session, SQLModel, create_engine

from app import seed
from app.api.deps import get_db
from app.core.config import settings
from app.main import app

TEST_DB_NAME = f"{settings.POSTGRES_DB}_test"


def _create_test_database() -> None:
    server = create_engine(
        settings.SQLALCHEMY_DATABASE_URI, isolation_level="AUTOCOMMIT"
    )
    with server.connect() as conn:
        exists = conn.execute(
            text("SELECT 1 FROM pg_database WHERE datname = :name"),
            {"name": TEST_DB_NAME},
        ).scalar()
        if not exists:
            conn.execute(text(f'CREATE DATABASE "{TEST_DB_NAME}"'))
    server.dispose()


@pytest.fixture(scope="session")
def engine() -> Generator[Engine]:
    _create_test_database()
    test_engine = create_engine(
        settings.SQLALCHEMY_DATABASE_URI.set(database=TEST_DB_NAME)
    )
    SQLModel.metadata.drop_all(test_engine)
    SQLModel.metadata.create_all(test_engine)
    with Session(test_engine) as session:
        seed.run_all(session)
    yield test_engine
    SQLModel.metadata.drop_all(test_engine)
    test_engine.dispose()


@pytest.fixture(scope="session")
def client(engine: Engine) -> Generator[TestClient]:
    def get_test_db() -> Generator[Session]:
        with Session(engine) as session:
            yield session

    app.dependency_overrides[get_db] = get_test_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


def login(client: TestClient, login: str, password: str) -> dict[str, str]:
    r = client.post(
        f"{settings.API_V1_STR}/login/access-token",
        data={"username": login, "password": password},
    )
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture
def admin_headers(client: TestClient) -> dict[str, str]:
    return login(client, settings.FIRST_ADMIN_EMAIL, settings.FIRST_ADMIN_PASSWORD)

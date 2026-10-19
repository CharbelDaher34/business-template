from fastapi.testclient import TestClient

from app.core.config import settings
from app.tests.conftest import login

TOKEN_URL = f"{settings.API_V1_STR}/login/access-token"


def test_login_with_email(client: TestClient) -> None:
    headers = login(client, settings.FIRST_ADMIN_EMAIL, settings.FIRST_ADMIN_PASSWORD)
    r = client.get(f"{settings.API_V1_STR}/users/me", headers=headers)
    assert r.status_code == 200
    assert r.json()["email"] == settings.FIRST_ADMIN_EMAIL


def test_login_with_username(client: TestClient) -> None:
    headers = login(
        client, settings.FIRST_ADMIN_USERNAME.upper(), settings.FIRST_ADMIN_PASSWORD
    )
    r = client.get(f"{settings.API_V1_STR}/users/me", headers=headers)
    assert r.status_code == 200
    assert r.json()["username"] == settings.FIRST_ADMIN_USERNAME.lower()


def test_login_wrong_password_is_rejected(client: TestClient) -> None:
    r = client.post(
        TOKEN_URL,
        data={"username": settings.FIRST_ADMIN_EMAIL, "password": "wrong-password"},
    )
    assert r.status_code == 400


def test_unauthorized_access_is_rejected(client: TestClient) -> None:
    r = client.get(f"{settings.API_V1_STR}/items/")
    assert r.status_code == 401
    r = client.get(
        f"{settings.API_V1_STR}/items/", headers={"Authorization": "Bearer not-a-token"}
    )
    assert r.status_code == 403

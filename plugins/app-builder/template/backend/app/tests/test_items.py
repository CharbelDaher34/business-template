from fastapi.testclient import TestClient

from app.core.config import settings

ITEMS_URL = f"{settings.API_V1_STR}/items"


def test_items_crud_flow(client: TestClient, admin_headers: dict[str, str]) -> None:
    # Create
    r = client.post(
        f"{ITEMS_URL}/",
        headers=admin_headers,
        json={"title": "Smoke test item", "description": "created by a test"},
    )
    assert r.status_code == 200, r.text
    item = r.json()
    assert item["title"] == "Smoke test item"

    # Read one, and find it in the list
    r = client.get(f"{ITEMS_URL}/{item['id']}", headers=admin_headers)
    assert r.status_code == 200
    r = client.get(f"{ITEMS_URL}/", headers=admin_headers)
    assert r.status_code == 200
    assert item["id"] in [i["id"] for i in r.json()["data"]]

    # Update
    r = client.put(
        f"{ITEMS_URL}/{item['id']}", headers=admin_headers, json={"title": "Renamed"}
    )
    assert r.status_code == 200
    assert r.json()["title"] == "Renamed"
    assert r.json()["description"] == "created by a test"

    # Delete
    r = client.delete(f"{ITEMS_URL}/{item['id']}", headers=admin_headers)
    assert r.status_code == 200
    r = client.get(f"{ITEMS_URL}/{item['id']}", headers=admin_headers)
    assert r.status_code == 404

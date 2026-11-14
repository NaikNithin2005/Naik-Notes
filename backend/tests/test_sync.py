import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

@pytest.fixture(autouse=True)
def reset_store():
    client.post("/v1/sync/reset")
    yield

def test_sync_status():
    response = client.get("/v1/sync/status")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "latest_watermark" in data
    assert data["total_stored_entities"] == 0

def test_sync_push_and_pull():
    # 1. Push a notebook operation and a stroke operation
    push_payload = {
        "client_id": "test_client_win",
        "owner_id": "local_user",
        "operations": [
            {
                "id": "op-nb-1",
                "entity_type": "notebook",
                "entity_id": "nb-sync-101",
                "operation_type": "insert",
                "payload": {
                    "id": "nb-sync-101",
                    "title": "Cloud Synced Physics Notebook",
                    "cover_id": "astronomy",
                },
                "revision": 1,
                "created_at": 1700000000000,
            },
            {
                "id": "op-stroke-1",
                "entity_type": "stroke",
                "entity_id": "stroke-sync-202",
                "operation_type": "insert",
                "payload": {
                    "id": "stroke-sync-202",
                    "tool": "fountain_pen",
                    "color": 4278190080,
                },
                "revision": 1,
                "created_at": 1700000001000,
            },
        ],
    }

    push_res = client.post("/v1/sync/push", json=push_payload)
    assert push_res.status_code == 200
    push_data = push_res.json()
    assert len(push_data["synced_ids"]) == 2
    assert "op-nb-1" in push_data["synced_ids"]
    assert "op-stroke-1" in push_data["synced_ids"]
    assert len(push_data["conflicts"]) == 0
    watermark_after_push = push_data["latest_watermark"]
    assert watermark_after_push > 100

    # 2. Pull with since_revision = 0
    pull_res = client.get("/v1/sync/pull?since_revision=0&owner_id=local_user")
    assert pull_res.status_code == 200
    pull_data = pull_res.json()
    assert len(pull_data["operations"]) == 2
    assert pull_data["latest_watermark"] == watermark_after_push

    # 3. Pull with since_revision = watermark_after_push -> should return 0 operations
    pull_up_to_date = client.get(f"/v1/sync/pull?since_revision={watermark_after_push}&owner_id=local_user")
    assert pull_up_to_date.status_code == 200
    assert len(pull_up_to_date.json()["operations"]) == 0

def test_sync_conflict_resolution():
    # Push revision 2
    client.post("/v1/sync/push", json={
        "operations": [{
            "id": "op-1",
            "entity_type": "notebook",
            "entity_id": "nb-conflict-1",
            "operation_type": "update",
            "payload": {"title": "Updated Title v2"},
            "revision": 2,
            "created_at": 1700000000000,
        }]
    })

    # Try pushing older revision 1 for same entity
    res_conflict = client.post("/v1/sync/push", json={
        "operations": [{
            "id": "op-older",
            "entity_type": "notebook",
            "entity_id": "nb-conflict-1",
            "operation_type": "update",
            "payload": {"title": "Stale Title v1"},
            "revision": 1,
            "created_at": 1700000000000,
        }]
    })

    assert res_conflict.status_code == 200
    data = res_conflict.json()
    assert len(data["conflicts"]) == 1
    conflict = data["conflicts"][0]
    assert conflict["entity_id"] == "nb-conflict-1"
    assert conflict["client_revision"] == 1
    assert conflict["server_revision"] == 2
    assert conflict["server_payload"]["title"] == "Updated Title v2"


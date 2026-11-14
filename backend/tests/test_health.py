import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "iPadOS" in data["platforms_supported"]
    assert "Android" in data["platforms_supported"]
    assert "Windows" in data["platforms_supported"]

def test_list_notebooks():
    response = client.get("/v1/notebooks")
    assert response.status_code == 200
    data = response.json()
    assert "notebooks" in data
    assert len(data["notebooks"]) >= 2


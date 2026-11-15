import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_get_template_categories():
    response = client.get("/v1/templates/categories")
    assert response.status_code == 200
    categories = response.json()
    assert isinstance(categories, list)
    assert "Engineering" in categories
    assert "Math & Science" in categories
    assert "Planning" in categories


def test_list_templates_and_filter():
    # 1. List all
    response = client.get("/v1/templates")
    assert response.status_code == 200
    data = response.json()
    assert "templates" in data
    assert data["total"] >= 6
    assert len(data["templates"]) >= 6

    # 2. Filter by category
    resp_filtered = client.get("/v1/templates?category=Engineering")
    assert resp_filtered.status_code == 200
    eng_data = resp_filtered.json()
    for tpl in eng_data["templates"]:
        assert tpl["category"] == "Engineering"

    # 3. Search query
    resp_search = client.get("/v1/templates?search=Biochemistry")
    assert resp_search.status_code == 200
    search_data = resp_search.json()
    assert search_data["total"] >= 1
    assert "Biochemistry" in search_data["templates"][0]["title"]


def test_get_template_detail_and_404():
    # Valid ID
    resp = client.get("/v1/templates/tpl-dark-engineering-grid")
    assert resp.status_code == 200
    tpl = resp.json()
    assert tpl["id"] == "tpl-dark-engineering-grid"
    assert tpl["author"] == "Prof. Naik"
    assert "paper_properties" in tpl
    assert tpl["paper_properties"]["backgroundColorHex"] == "#1E2022"

    # Invalid ID
    resp_404 = client.get("/v1/templates/nonexistent-id")
    assert resp_404.status_code == 404


def test_publish_and_download_template():
    payload = {
        "title": "Quantum Physics Dirac Notation Grid",
        "description": "Subtle 4mm dot grid with dual Dirac bra-ket margin lines.",
        "category": "Math & Science",
        "author": "Dr. Subrahmanyan",
        "paper_properties": {
            "backgroundColorHex": "#FDFBF7",
            "lineColorHex": "#E2E8F0",
            "accentColorHex": "#3B82F6",
            "gridSize": 11.34,
            "lineSpacing": 18.0,
            "marginTop": 40.0,
            "marginBottom": 40.0,
            "marginLeft": 40.0,
            "marginRight": 40.0,
            "hasHeaderArea": True,
            "headerHeight": 44.0,
            "pageSize": "A4",
            "orientation": "portrait",
            "showPageNumber": True,
        },
    }

    # Create
    create_resp = client.post("/v1/templates", json=payload)
    assert create_resp.status_code == 201
    created = create_resp.json()
    new_id = created["id"]
    assert created["title"] == payload["title"]
    assert created["download_count"] == 1

    # Download / Increment count
    download_resp = client.post(f"/v1/templates/{new_id}/download")
    assert download_resp.status_code == 200
    updated = download_resp.json()
    assert updated["download_count"] == 2


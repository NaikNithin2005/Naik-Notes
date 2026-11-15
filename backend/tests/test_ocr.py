import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_ocr_status():
    response = client.get("/v1/ai/ocr/status")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "active"
    assert "NaikNotes-VectorCluster-OCR" in data["engine"]
    assert "en" in data["supported_languages"]


def test_recognize_empty_strokes():
    payload = {
        "page_id": "page-101",
        "notebook_id": "nb-101",
        "strokes": [],
        "language": "en",
    }
    response = client.post("/v1/ai/ocr/recognize-strokes", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["page_id"] == "page-101"
    assert data["words"] == []
    assert data["full_text"] == ""
    assert data["stroke_count"] == 0


def test_recognize_clustered_strokes():
    # Cluster 1: two strokes close together horizontally on the same baseline
    # Cluster 2: one stroke far to the right
    payload = {
        "page_id": "page-phys-1",
        "notebook_id": "nb-phys-1",
        "language": "en",
        "strokes": [
            {
                "id": "s1",
                "color": "#000000",
                "width": 2.0,
                "points": [
                    {"x": 20.0, "y": 50.0, "pressure": 1.0, "tilt": 0.0, "timestamp_ms": 100},
                    {"x": 35.0, "y": 70.0, "pressure": 1.0, "tilt": 0.0, "timestamp_ms": 150},
                ],
            },
            {
                "id": "s2",
                "color": "#000000",
                "width": 2.0,
                "points": [
                    {"x": 42.0, "y": 52.0, "pressure": 1.0, "tilt": 0.0, "timestamp_ms": 200},
                    {"x": 60.0, "y": 68.0, "pressure": 1.0, "tilt": 0.0, "timestamp_ms": 250},
                ],
            },
            {
                "id": "s3",
                "color": "#000000",
                "width": 2.0,
                "points": [
                    {"x": 160.0, "y": 50.0, "pressure": 1.0, "tilt": 0.0, "timestamp_ms": 300},
                    {"x": 190.0, "y": 70.0, "pressure": 1.0, "tilt": 0.0, "timestamp_ms": 350},
                ],
            },
        ],
    }

    response = client.post("/v1/ai/ocr/recognize-strokes", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["page_id"] == "page-phys-1"
    assert data["stroke_count"] == 3
    assert len(data["words"]) == 2  # s1+s2 clustered together, s3 separate cluster

    first_word = data["words"][0]
    assert first_word["x"] == 20.0
    assert first_word["width"] == 40.0  # 60 - 20
    assert first_word["confidence"] >= 0.9

    second_word = data["words"][1]
    assert second_word["x"] == 160.0
    assert second_word["width"] == 30.0  # 190 - 160

    assert len(data["full_text"]) > 0


def test_recognize_image_endpoint():
    payload = {
        "page_id": "page-img-1",
        "notebook_id": "nb-img-1",
        "image_base64": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
        "language": "en",
    }
    response = client.post("/v1/ai/ocr/recognize-image", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["page_id"] == "page-img-1"

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_ai_study_status():
    response = client.get("/v1/ai/study/status")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "active"
    assert "NaikNotes-AI-StudyEngine" in data["provider"]
    assert "flashcard_generation" in data["capabilities"]
    assert "quiz_generation" in data["capabilities"]


def test_ai_summarize():
    payload = {
        "notebook_id": "nb-phys-101",
        "context_text": (
            "Gauss's Law relates electric flux through a surface to the enclosed charge. "
            "The differential form is div E equals rho over epsilon. "
            "This principle allows rapid calculation of electric fields around symmetrical charge distributions."
        ),
        "format": "structured",
    }
    response = client.post("/v1/ai/study/summarize", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["notebook_id"] == "nb-phys-101"
    assert "Lecture & Reading Overview" in data["summary_markdown"]
    assert len(data["key_concepts"]) > 0
    assert len(data["study_recommendations"]) > 0


def test_ai_flashcards():
    payload = {
        "notebook_id": "nb-calc-201",
        "context_text": "Integration by parts is based on the product rule for differentiation.",
        "count": 3,
    }
    response = client.post("/v1/ai/study/flashcards", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["notebook_id"] == "nb-calc-201"
    assert len(data["flashcards"]) == 3
    card = data["flashcards"][0]
    assert len(card["question"]) > 5
    assert len(card["answer"]) > 5
    assert card["difficulty"] in ["easy", "medium", "hard"]


def test_ai_quiz():
    payload = {
        "notebook_id": "nb-ai-301",
        "context_text": "Gradient descent minimizes the objective function by stepping in the direction of negative gradient.",
        "count": 4,
    }
    response = client.post("/v1/ai/study/quiz", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["notebook_id"] == "nb-ai-301"
    assert len(data["questions"]) == 4
    q = data["questions"][0]
    assert len(q["options"]) == 4
    assert 0 <= q["correct_answer_index"] < 4
    assert len(q["explanation"]) > 10


def test_ai_explain_formula():
    payload = {
        "formula_text": "E = mc^2",
        "context": "Special relativity",
    }
    response = client.post("/v1/ai/study/explain-formula", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "$$E = mc^2$$" in data["formula_latex"]
    assert len(data["explanation"]) > 10
    assert "E" in data["variable_definitions"]
    assert len(data["practical_application"]) > 10


def test_ai_chat():
    payload = {
        "notebook_id": "nb-chat-1",
        "message": "Can you explain the main formula in this chapter?",
        "conversation_history": [],
    }
    response = client.post("/v1/ai/study/chat", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert len(data["reply"]) > 20
    assert len(data["suggested_followups"]) > 0


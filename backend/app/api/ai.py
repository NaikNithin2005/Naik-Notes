from fastapi import APIRouter, HTTPException, status
from app.schemas.ai import (
    AiSummarizeRequest,
    AiSummaryResponse,
    AiGenerateFlashcardsRequest,
    AiFlashcardsResponse,
    AiGenerateQuizRequest,
    AiQuizResponse,
    AiExplainFormulaRequest,
    AiExplainFormulaResponse,
    AiChatRequest,
    AiChatResponse,
    AiStudyStatusResponse,
)
from app.services.ai_service import ai_study_service

router = APIRouter(prefix="/v1/ai/study", tags=["AI Study Assistant"])


@router.get("/status", response_model=AiStudyStatusResponse)
def get_study_status():
    """Returns AI Study Assistant availability and supported capabilities."""
    return ai_study_service.get_status()


@router.post("/summarize", response_model=AiSummaryResponse)
def summarize_notes(request: AiSummarizeRequest):
    """Generates structured summaries, core takeaways, and review topics from notebook notes."""
    try:
        return ai_study_service.summarize(request)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI Summarization error: {str(e)}",
        )


@router.post("/flashcards", response_model=AiFlashcardsResponse)
def generate_flashcards(request: AiGenerateFlashcardsRequest):
    """Generates interactive flashcards with hints and difficulty ratings from notes."""
    try:
        return ai_study_service.generate_flashcards(request)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI Flashcard generation error: {str(e)}",
        )


@router.post("/quiz", response_model=AiQuizResponse)
def generate_quiz(request: AiGenerateQuizRequest):
    """Generates multiple-choice quiz questions with pedagogical explanations."""
    try:
        return ai_study_service.generate_quiz(request)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI Quiz generation error: {str(e)}",
        )


@router.post("/explain-formula", response_model=AiExplainFormulaResponse)
def explain_formula(request: AiExplainFormulaRequest):
    """Explains a mathematical formula, renders LaTeX formatting, and explains variables."""
    try:
        return ai_study_service.explain_formula(request)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI Formula explanation error: {str(e)}",
        )


@router.post("/chat", response_model=AiChatResponse)
def notebook_chat(request: AiChatRequest):
    """Interactive notebook Q&A assistant with context-aware responses and follow-up prompts."""
    try:
        return ai_study_service.chat(request)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"AI Chat error: {str(e)}",
        )

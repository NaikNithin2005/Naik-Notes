from typing import List, Optional, Dict
from pydantic import BaseModel, Field


class AiSummarizeRequest(BaseModel):
    notebook_id: str
    context_text: str
    format: str = "structured"  # structured, executive, detailed


class AiSummaryResponse(BaseModel):
    notebook_id: str
    title: str
    summary_markdown: str
    key_concepts: List[str]
    study_recommendations: List[str]


class AiGenerateFlashcardsRequest(BaseModel):
    notebook_id: str
    context_text: str
    count: int = 5


class AiFlashcardSchema(BaseModel):
    id: str
    question: str
    answer: str
    hint: Optional[str] = None
    difficulty: str = "medium"  # easy, medium, hard


class AiFlashcardsResponse(BaseModel):
    notebook_id: str
    flashcards: List[AiFlashcardSchema]


class AiGenerateQuizRequest(BaseModel):
    notebook_id: str
    context_text: str
    count: int = 4


class AiQuizQuestionSchema(BaseModel):
    id: str
    question: str
    options: List[str]
    correct_answer_index: int
    explanation: str


class AiQuizResponse(BaseModel):
    notebook_id: str
    questions: List[AiQuizQuestionSchema]


class AiExplainFormulaRequest(BaseModel):
    formula_text: str
    context: Optional[str] = None


class AiExplainFormulaResponse(BaseModel):
    formula_latex: str
    explanation: str
    variable_definitions: Dict[str, str] = Field(default_factory=dict)
    practical_application: str


class ChatMessage(BaseModel):
    role: str  # user, assistant
    content: str


class AiChatRequest(BaseModel):
    notebook_id: str
    message: str
    conversation_history: List[ChatMessage] = Field(default_factory=list)
    context_text: Optional[str] = None


class AiChatResponse(BaseModel):
    reply: str
    suggested_followups: List[str] = Field(default_factory=list)


class AiStudyStatusResponse(BaseModel):
    status: str = "active"
    provider: str = "NaikNotes-AI-StudyEngine"
    version: str = "1.0.0"
    capabilities: List[str] = Field(
        default_factory=lambda: [
            "summarization",
            "flashcard_generation",
            "quiz_generation",
            "formula_explanation",
            "interactive_chat",
        ]
    )


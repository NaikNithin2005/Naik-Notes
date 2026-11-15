from typing import List, Optional
from pydantic import BaseModel, Field


class StrokePointSchema(BaseModel):
    x: float
    y: float
    pressure: float = 1.0
    tilt: float = 0.0
    timestamp_ms: int = 0


class StrokeInputSchema(BaseModel):
    id: str
    points: List[StrokePointSchema]
    color: str = "#000000"
    width: float = 2.0


class WordBoxSchema(BaseModel):
    word: str
    x: float
    y: float
    width: float
    height: float
    confidence: float = 0.95


class RecognizeStrokesRequest(BaseModel):
    page_id: str
    notebook_id: str
    strokes: List[StrokeInputSchema]
    language: str = "en"


class RecognizeStrokesResponse(BaseModel):
    page_id: str
    notebook_id: str
    words: List[WordBoxSchema]
    full_text: str
    stroke_count: int


class RecognizeImageRequest(BaseModel):
    page_id: str
    notebook_id: str
    image_base64: str
    language: str = "en"


class OcrStatusResponse(BaseModel):
    status: str = "active"
    engine: str = "NaikNotes-VectorCluster-OCR"
    version: str = "1.0.0"
    supported_languages: List[str] = Field(default_factory=lambda: ["en", "es", "fr", "de", "hi"])


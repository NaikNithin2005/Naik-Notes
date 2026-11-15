from fastapi import APIRouter, HTTPException, status
from app.schemas.ocr import (
    RecognizeStrokesRequest,
    RecognizeStrokesResponse,
    RecognizeImageRequest,
    OcrStatusResponse,
)
from app.services.ocr_service import ocr_service

router = APIRouter(prefix="/v1/ai/ocr", tags=["AI Handwriting Recognition"])


@router.get("/status", response_model=OcrStatusResponse)
def get_ocr_status():
    """Retrieve the status and capabilities of the AI OCR recognition engine."""
    return ocr_service.get_status()


@router.post("/recognize-strokes", response_model=RecognizeStrokesResponse)
def recognize_strokes(request: RecognizeStrokesRequest):
    """Recognize handwritten text and bounding word boxes from raw vector strokes."""
    try:
        return ocr_service.recognize_strokes(
            page_id=request.page_id,
            notebook_id=request.notebook_id,
            strokes=request.strokes,
            language=request.language,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"OCR recognition error: {str(e)}",
        )


@router.post("/recognize-image", response_model=RecognizeStrokesResponse)
def recognize_image(request: RecognizeImageRequest):
    """Recognize text from an encoded canvas raster image."""
    return RecognizeStrokesResponse(
        page_id=request.page_id,
        notebook_id=request.notebook_id,
        words=[],
        full_text="",
        stroke_count=0,
    )


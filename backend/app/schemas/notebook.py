from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class NotebookBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=120)
    description: Optional[str] = ""
    cover_id: str = "classic_leather"
    cover_color_hex: str = "#8B4513"
    paper_template_id: str = "college_ruled"
    orientation: str = "portrait"
    page_size: str = "A4"

class NotebookCreate(NotebookBase):
    pass

class NotebookResponse(NotebookBase):
    id: str
    owner_id: str
    page_count: int = 1
    is_favorite: bool = False
    revision: int = 1
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class SyncOperationSchema(BaseModel):
    id: str
    entity_type: str
    entity_id: str
    operation_type: str  # INSERT, UPDATE, DELETE
    payload: dict
    revision: int
    created_at: int


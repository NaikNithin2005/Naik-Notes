from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class CommunityTemplateBase(BaseModel):
    title: str = Field(..., min_length=2, max_length=100)
    description: str = Field(..., max_length=500)
    category: str = Field(..., max_length=50)  # e.g., "Engineering", "Math", "Planning", "Music", "Language", "Art"
    author: str = Field("Community", max_length=50)
    paper_properties: Dict[str, Any] = Field(..., description="Paper properties including line spacing, grid, colors")
    thumbnail_base64: Optional[str] = None


class CommunityTemplateCreate(CommunityTemplateBase):
    pass


class CommunityTemplateResponse(CommunityTemplateBase):
    id: str
    download_count: int = 0
    rating: float = 5.0
    created_at: datetime
    updated_at: datetime


class TemplateCatalogResponse(BaseModel):
    templates: List[CommunityTemplateResponse]
    total: int
    categories: List[str]

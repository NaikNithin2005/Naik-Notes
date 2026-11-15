from datetime import datetime, timezone
from typing import Dict, List, Optional
import uuid

from app.schemas.template import (
    CommunityTemplateCreate,
    CommunityTemplateResponse,
    TemplateCatalogResponse,
)

CATEGORIES = [
    "All",
    "Math & Science",
    "Engineering",
    "Planning",
    "Music",
    "Language",
    "Art & Design",
]

_SEED_TEMPLATES: List[Dict] = [
    {
        "id": "tpl-dark-engineering-grid",
        "title": "Dark Mode Precision Quad Grid",
        "description": "5mm quad grid with dark slate paper tone, cyan guide lines, and technical header block for engineering calculations.",
        "category": "Engineering",
        "author": "Prof. Naik",
        "paper_properties": {
            "backgroundColorHex": "#1E2022",
            "lineColorHex": "#334155",
            "accentColorHex": "#06B6D4",
            "gridSize": 14.17,
            "lineSpacing": 20.0,
            "marginTop": 56.0,
            "marginBottom": 40.0,
            "marginLeft": 40.0,
            "marginRight": 40.0,
            "hasHeaderArea": True,
            "headerHeight": 44.0,
            "pageSize": "A4",
            "orientation": "portrait",
            "showPageNumber": True,
        },
        "thumbnail_base64": None,
        "download_count": 342,
        "rating": 4.9,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    },
    {
        "id": "tpl-cornell-biochem",
        "title": "Cornell Medical Biochemistry Cue Sheet",
        "description": "2.5-inch left recall cue column, 7.1mm college rule notes body, and 96pt summary footer optimized for pre-med revision.",
        "category": "Math & Science",
        "author": "BioMed Guild",
        "paper_properties": {
            "backgroundColorHex": "#FDFBF7",
            "lineColorHex": "#CBD5E1",
            "accentColorHex": "#E11D48",
            "gridSize": 14.17,
            "lineSpacing": 20.13,
            "marginTop": 56.0,
            "marginBottom": 40.0,
            "marginLeft": 56.0,
            "marginRight": 40.0,
            "hasHeaderArea": True,
            "headerHeight": 44.0,
            "pageSize": "A4",
            "orientation": "portrait",
            "showPageNumber": True,
        },
        "thumbnail_base64": None,
        "download_count": 528,
        "rating": 5.0,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    },
    {
        "id": "tpl-bullet-habit-tracker",
        "title": "7-Day Habit Matrix & Weekly Planner",
        "description": "Minimalist ivory layout featuring a 7-day habit tracker matrix, top 3 priorities quadrant, and daily time blocks.",
        "category": "Planning",
        "author": "ProductivityHub",
        "paper_properties": {
            "backgroundColorHex": "#FAF0F2",
            "lineColorHex": "#E2E8F0",
            "accentColorHex": "#8B5CF6",
            "gridSize": 14.17,
            "lineSpacing": 22.0,
            "marginTop": 48.0,
            "marginBottom": 40.0,
            "marginLeft": 40.0,
            "marginRight": 40.0,
            "hasHeaderArea": True,
            "headerHeight": 50.0,
            "pageSize": "A4",
            "orientation": "portrait",
            "showPageNumber": False,
        },
        "thumbnail_base64": None,
        "download_count": 819,
        "rating": 4.8,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    },
    {
        "id": "tpl-piano-manuscript",
        "title": "Grand Staff Piano & Vocal Manuscript",
        "description": "Standard 5-line musical staves grouped in piano braces with treble and bass clef margins.",
        "category": "Music",
        "author": "Classical Conservatory",
        "paper_properties": {
            "backgroundColorHex": "#FFFFFF",
            "lineColorHex": "#1E293B",
            "accentColorHex": "#475569",
            "gridSize": 14.17,
            "lineSpacing": 24.0,
            "marginTop": 40.0,
            "marginBottom": 40.0,
            "marginLeft": 40.0,
            "marginRight": 40.0,
            "hasHeaderArea": False,
            "pageSize": "A4",
            "orientation": "landscape",
            "showPageNumber": True,
        },
        "thumbnail_base64": None,
        "download_count": 215,
        "rating": 4.9,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    },
    {
        "id": "tpl-kanji-tianzige",
        "title": "Kanji & Hanzi 20mm Tianzige Grid",
        "description": "Cross-divided quadrant squares (Tianzige) engineered for mastering stroke order and proportion in Asian calligraphy.",
        "category": "Language",
        "author": "Linguistics Guild",
        "paper_properties": {
            "backgroundColorHex": "#F5EFEB",
            "lineColorHex": "#D6D3D1",
            "accentColorHex": "#DC2626",
            "gridSize": 28.35,
            "lineSpacing": 28.35,
            "marginTop": 48.0,
            "marginBottom": 40.0,
            "marginLeft": 48.0,
            "marginRight": 48.0,
            "hasHeaderArea": True,
            "headerHeight": 36.0,
            "pageSize": "A4",
            "orientation": "portrait",
            "showPageNumber": True,
        },
        "thumbnail_base64": None,
        "download_count": 472,
        "rating": 4.9,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    },
    {
        "id": "tpl-isometric-golden-ratio",
        "title": "Golden Ratio 60-Degree Isometric Grid",
        "description": "Equilateral triangular dot grid for architectural perspectives, 3D typography, and structural sketching.",
        "category": "Art & Design",
        "author": "Studio Minimal",
        "paper_properties": {
            "backgroundColorHex": "#F0F5F2",
            "lineColorHex": "#CBD5E1",
            "accentColorHex": "#10B981",
            "gridSize": 18.0,
            "lineSpacing": 18.0,
            "marginTop": 40.0,
            "marginBottom": 40.0,
            "marginLeft": 40.0,
            "marginRight": 40.0,
            "hasHeaderArea": False,
            "pageSize": "A4",
            "orientation": "portrait",
            "showPageNumber": True,
        },
        "thumbnail_base64": None,
        "download_count": 640,
        "rating": 5.0,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    },
]


class TemplateService:
    def __init__(self):
        self._templates: Dict[str, Dict] = {
            t["id"]: dict(t) for t in _SEED_TEMPLATES
        }

    def list_categories(self) -> List[str]:
        return CATEGORIES

    def list_templates(
        self,
        category: Optional[str] = None,
        search: Optional[str] = None,
    ) -> TemplateCatalogResponse:
        results = list(self._templates.values())

        if category and category.lower() != "all":
            results = [
                t for t in results
                if t["category"].lower() == category.lower()
            ]

        if search:
            query = search.strip().lower()
            results = [
                t for t in results
                if query in t["title"].lower() or query in t["description"].lower()
            ]

        # Sort by downloads descending
        results.sort(key=lambda x: x["download_count"], reverse=True)

        return TemplateCatalogResponse(
            templates=[CommunityTemplateResponse(**t) for t in results],
            total=len(results),
            categories=CATEGORIES,
        )

    def get_template(self, template_id: str) -> Optional[CommunityTemplateResponse]:
        item = self._templates.get(template_id)
        if not item:
            return None
        return CommunityTemplateResponse(**item)

    def create_template(
        self,
        data: CommunityTemplateCreate,
    ) -> CommunityTemplateResponse:
        new_id = f"tpl-{uuid.uuid4().hex[:12]}"
        now = datetime.now(timezone.utc)
        record = {
            "id": new_id,
            "title": data.title,
            "description": data.description,
            "category": data.category,
            "author": data.author,
            "paper_properties": data.paper_properties,
            "thumbnail_base64": data.thumbnail_base64,
            "download_count": 1,
            "rating": 5.0,
            "created_at": now,
            "updated_at": now,
        }
        self._templates[new_id] = record
        return CommunityTemplateResponse(**record)

    def increment_download(
        self,
        template_id: str,
    ) -> Optional[CommunityTemplateResponse]:
        item = self._templates.get(template_id)
        if not item:
            return None
        item["download_count"] += 1
        item["updated_at"] = datetime.now(timezone.utc)
        return CommunityTemplateResponse(**item)


template_service = TemplateService()

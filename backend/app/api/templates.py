from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query, status

from app.schemas.template import (
    CommunityTemplateCreate,
    CommunityTemplateResponse,
    TemplateCatalogResponse,
)
from app.services.template_service import template_service

router = APIRouter(prefix="/v1/templates", tags=["templates"])


@router.get("/categories", response_model=List[str])
async def get_categories():
    """Returns all supported template categories."""
    return template_service.list_categories()


@router.get("", response_model=TemplateCatalogResponse)
async def list_templates(
    category: Optional[str] = Query(None, description="Filter by category"),
    search: Optional[str] = Query(None, description="Search term in title or description"),
):
    """Lists community templates matching optional category and query."""
    return template_service.list_templates(category=category, search=search)


@router.get("/{template_id}", response_model=CommunityTemplateResponse)
async def get_template(template_id: str):
    """Retrieves full specification of a single community template."""
    item = template_service.get_template(template_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Template with id '{template_id}' was not found.",
        )
    return item


@router.post("", response_model=CommunityTemplateResponse, status_code=status.HTTP_201_CREATED)
async def create_template(data: CommunityTemplateCreate):
    """Publishes a new community paper template to the catalog."""
    return template_service.create_template(data)


@router.post("/{template_id}/download", response_model=CommunityTemplateResponse)
async def download_template(template_id: str):
    """Increments the download counter and returns the template bundle."""
    item = template_service.increment_download(template_id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Template with id '{template_id}' was not found.",
        )
    return item


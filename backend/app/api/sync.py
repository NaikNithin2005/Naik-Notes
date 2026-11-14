from fastapi import APIRouter, Query
from typing import Optional
from app.schemas.sync import (
    SyncPushRequest,
    SyncPushResponse,
    SyncPullResponse,
    SyncStatusResponse,
)
from app.services.sync_service import sync_store

router = APIRouter(prefix="/v1/sync", tags=["synchronization"])

@router.post("/push", response_model=SyncPushResponse)
def push_changes(request: SyncPushRequest):
    """
    Receives batched sync operations from client, applies LWW conflict resolution,
    and returns synced operation IDs along with any conflicts and the new watermark.
    """
    synced_ids, conflicts, watermark = sync_store.process_push(
        request.operations, owner_id=request.owner_id or "local_user"
    )
    return SyncPushResponse(
        synced_ids=synced_ids,
        conflicts=conflicts,
        latest_watermark=watermark,
    )

@router.get("/pull", response_model=SyncPullResponse)
def pull_changes(
    since_revision: int = Query(0, description="Pull changes occurring strictly after this watermark/revision"),
    owner_id: str = Query("local_user", description="Owner ID for multi-tenant isolation"),
):
    """
    Retrieves all remote changes since the specified watermark.
    """
    operations, watermark = sync_store.process_pull(
        since_revision=since_revision, owner_id=owner_id
    )
    return SyncPullResponse(
        operations=operations,
        latest_watermark=watermark,
    )

@router.get("/status", response_model=SyncStatusResponse)
def sync_status():
    """
    Returns the current sync engine status and server watermark.
    """
    return SyncStatusResponse(
        status="healthy",
        latest_watermark=sync_store.get_watermark(),
        total_stored_entities=sync_store.get_total_entities(),
    )

@router.post("/reset")
def reset_sync():
    """
    Resets the sync store. Used for testing and clean slate migrations.
    """
    sync_store.clear()
    return {"message": "Sync store reset successfully"}


from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class SyncOperationSchema(BaseModel):
    id: str
    entity_type: str
    entity_id: str
    operation_type: str  # insert, update, delete
    payload: Dict[str, Any]
    revision: int = 1
    created_at: int

class SyncPushRequest(BaseModel):
    client_id: Optional[str] = "naik_client_default"
    owner_id: Optional[str] = "local_user"
    operations: List[SyncOperationSchema]

class SyncPushResponse(BaseModel):
    synced_ids: List[str]
    conflicts: List[Dict[str, Any]] = []
    latest_watermark: int

class SyncPullResponse(BaseModel):
    operations: List[SyncOperationSchema]
    latest_watermark: int

class SyncStatusResponse(BaseModel):
    status: str
    latest_watermark: int
    total_stored_entities: int


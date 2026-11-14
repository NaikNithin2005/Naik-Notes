import time
from typing import Dict, Any, List, Tuple
from app.schemas.sync import SyncOperationSchema

class SyncStore:
    def __init__(self):
        # Key: "{entity_type}:{entity_id}" -> dict
        self._entities: Dict[str, Dict[str, Any]] = {}
        # List of operations recorded with their server watermark
        self._changelog: List[Dict[str, Any]] = []
        self._watermark: int = 100

    def get_watermark(self) -> int:
        return self._watermark

    def get_total_entities(self) -> int:
        return len(self._entities)

    def clear(self):
        self._entities.clear()
        self._changelog.clear()
        self._watermark = 100

    def process_push(
        self, operations: List[SyncOperationSchema], owner_id: str = "local_user"
    ) -> Tuple[List[str], List[Dict[str, Any]], int]:
        synced_ids: List[str] = []
        conflicts: List[Dict[str, Any]] = []

        for op in operations:
            key = f"{op.entity_type}:{op.entity_id}"
            existing = self._entities.get(key)

            is_conflict = False
            if existing is not None:
                existing_rev = existing.get("revision", 1)
                # If incoming revision is strictly less than existing revision, conflict!
                if op.revision < existing_rev:
                    is_conflict = True
                    conflicts.append({
                        "operation_id": op.id,
                        "entity_type": op.entity_type,
                        "entity_id": op.entity_id,
                        "client_revision": op.revision,
                        "server_revision": existing_rev,
                        "server_payload": existing.get("payload", {}),
                    })
                    # We still mark as synced to clear the client queue, since client receives conflict payload to reconcile
                    synced_ids.append(op.id)
                    continue

            # Increment watermark for every accepted modification
            self._watermark += 1
            is_deleted = (op.operation_type.lower() == "delete")

            record = {
                "entity_type": op.entity_type,
                "entity_id": op.entity_id,
                "operation_type": op.operation_type.lower(),
                "payload": op.payload,
                "revision": op.revision,
                "watermark": self._watermark,
                "deleted": is_deleted,
                "owner_id": owner_id,
                "updated_at": int(time.time() * 1000),
            }

            self._entities[key] = record
            self._changelog.append(record)
            synced_ids.append(op.id)

        return synced_ids, conflicts, self._watermark

    def process_pull(
        self, since_revision: int = 0, owner_id: str = "local_user"
    ) -> Tuple[List[SyncOperationSchema], int]:
        results: List[SyncOperationSchema] = []

        for entry in self._changelog:
            if entry["watermark"] > since_revision and entry.get("owner_id") == owner_id:
                results.append(
                    SyncOperationSchema(
                        id=f"remote-op-{entry['watermark']}",
                        entity_type=entry["entity_type"],
                        entity_id=entry["entity_id"],
                        operation_type=entry["operation_type"],
                        payload=entry["payload"],
                        revision=entry["revision"],
                        created_at=entry["updated_at"],
                    )
                )

        return results, self._watermark

# Global singleton instance for sync store
sync_store = SyncStore()


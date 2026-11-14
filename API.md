# Naik Notes — Backend API Specification

## 1. Overview

The Naik Notes backend is implemented with **FastAPI (Python)**, utilizing the **Firebase Admin SDK** for credential verification, Firestore updates, and Cloud Storage management. This architecture provides full Windows, Android, and iOS client compatibility without relying on unverified desktop plugins.

- Base URL: `https://api.naiknotes.com/v1` (Production) / `http://localhost:8000/v1` (Development)
- Authentication: Bearer token (`Authorization: Bearer <Firebase_ID_Token>`)

---

## 2. Endpoints

### 2.1 Health & Diagnostics
- `GET /health`: Server health check, uptime, and database connection status.
- `GET /version`: Current API contract version.

### 2.2 Devices
- `POST /devices/register`: Register client device (`deviceId`, `platform`, `deviceName`, `fcmToken`).
- `GET /devices`: List user's active registered devices.

### 2.3 Synchronization
- `POST /sync/push`: Enqueue an array of local sync operations (`SyncOperation[]`).
  - Returns: `{ "processed": [operationIds], "conflicts": [conflictDetails] }`
- `POST /sync/pull`: Retrieve server updates after a given revision or timestamp.
  - Parameters: `{ "lastSyncTimestamp": 1731580000, "deviceId": "..." }`
  - Returns: `{ "changes": [...], "serverTimestamp": 1731580500 }`

### 2.4 Notebooks
- `GET /notebooks`: List user's notebooks with revision metadata.
- `POST /notebooks`: Create notebook.
- `GET /notebooks/{id}`: Fetch notebook detail and section tree.
- `PUT /notebooks/{id}`: Update metadata.
- `DELETE /notebooks/{id}`: Soft delete notebook (marked with `deletedAt`).

### 2.5 Pages & Strokes
- `GET /notebooks/{id}/pages/{pageId}/strokes`: Retrieve all vector strokes for a given page.
- `POST /notebooks/{id}/pages/{pageId}/strokes/batch`: Upload a batch of strokes.

### 2.6 AI Study Assistant
- `POST /ai/summarize`: Provider-agnostic summarization of notebook or PDF text content.
- `POST /ai/generate-flashcards`: Generate study question/answer flashcard pairs.
- `POST /ai/explain`: Explain an extracted handwritten or printed note concept.

### 2.7 Storage & Presigned URLs
- `POST /storage/upload-url`: Request signed upload URL for PDF or audio file.
- `POST /storage/download-url`: Request signed download URL for attachment.


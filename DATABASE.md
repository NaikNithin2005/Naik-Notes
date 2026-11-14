# Naik Notes — Database Schema & Data Modeling

## 1. Local Database (Drift SQLite)

Naik Notes uses SQLite via the Drift ORM for low-latency offline storage.

### 1.1 Tables

#### `users`
- `id` (TEXT, PK): Unique Firebase User UID.
- `email` (TEXT, NOT NULL)
- `display_name` (TEXT)
- `photo_url` (TEXT)
- `created_at` (INTEGER, UNIX timestamp ms)
- `updated_at` (INTEGER, UNIX timestamp ms)

#### `notebooks`
- `id` (TEXT, PK): UUID v4.
- `owner_id` (TEXT, NOT NULL, FK -> users.id)
- `folder_id` (TEXT, NULL, FK -> folders.id)
- `title` (TEXT, NOT NULL)
- `description` (TEXT)
- `cover_id` (TEXT, NOT NULL)
- `paper_template_id` (TEXT, NOT NULL)
- `orientation` (TEXT, DEFAULT 'portrait')
- `page_size` (TEXT, DEFAULT 'A4')
- `is_favorite` (INTEGER, DEFAULT 0)
- `revision` (INTEGER, DEFAULT 1)
- `created_at` (INTEGER, NOT NULL)
- `updated_at` (INTEGER, NOT NULL)
- `deleted_at` (INTEGER, NULL)
- `sync_status` (TEXT, DEFAULT 'synced')

#### `folders`
- `id` (TEXT, PK): UUID v4.
- `owner_id` (TEXT, NOT NULL)
- `parent_id` (TEXT, NULL, Self FK -> folders.id)
- `name` (TEXT, NOT NULL)
- `color_hex` (TEXT)
- `created_at` (INTEGER, NOT NULL)
- `updated_at` (INTEGER, NOT NULL)

#### `pages`
- `id` (TEXT, PK): UUID v4.
- `notebook_id` (TEXT, NOT NULL, FK -> notebooks.id ON DELETE CASCADE)
- `section_id` (TEXT, NULL)
- `page_number` (INTEGER, NOT NULL)
- `template_id` (TEXT, NOT NULL)
- `background_color` (TEXT)
- `width` (REAL, DEFAULT 595.28) -- Standard A4 points
- `height` (REAL, DEFAULT 841.89)
- `revision` (INTEGER, DEFAULT 1)
- `created_at` (INTEGER, NOT NULL)
- `updated_at` (INTEGER, NOT NULL)

#### `strokes`
- `id` (TEXT, PK): UUID v4.
- `page_id` (TEXT, NOT NULL, FK -> pages.id ON DELETE CASCADE)
- `tool_type` (TEXT, NOT NULL): `pen`, `fountain_pen`, `pencil`, `highlighter`, `brush`
- `color_value` (INTEGER, NOT NULL): 32-bit ARGB integer.
- `width` (REAL, NOT NULL)
- `opacity` (REAL, NOT NULL)
- `points_json` (TEXT, NOT NULL): Serialized array `[{x, y, p, t}]` (x, y, pressure, timestamp).
- `bounding_box_json` (TEXT, NOT NULL): `{minX, minY, maxX, maxY}` for fast spatial culling.
- `created_at` (INTEGER, NOT NULL)
- `revision` (INTEGER, DEFAULT 1)

#### `pdf_annotations`
- `id` (TEXT, PK): UUID v4.
- `document_id` (TEXT, NOT NULL): Unique hash/UUID of imported PDF.
- `page_index` (INTEGER, NOT NULL)
- `annotation_type` (TEXT, NOT NULL): `highlight`, `underline`, `strikethrough`, `text_box`, `ink`, `shape`
- `rect_json` (TEXT, NOT NULL): Normalized coordinates `[left, top, right, bottom]`.
- `content` (TEXT): Text content or serialized vector path.
- `color_value` (INTEGER, NOT NULL)
- `created_at` (INTEGER, NOT NULL)
- `updated_at` (INTEGER, NOT NULL)

#### `sync_queue`
- `id` (TEXT, PK): UUID v4.
- `entity_type` (TEXT, NOT NULL): `notebook`, `page`, `stroke`, `folder`, `annotation`
- `entity_id` (TEXT, NOT NULL)
- `operation_type` (TEXT, NOT NULL): `INSERT`, `UPDATE`, `DELETE`
- `payload_json` (TEXT, NOT NULL)
- `status` (TEXT, DEFAULT 'pending'): `pending`, `in_progress`, `failed`, `completed`
- `retry_count` (INTEGER, DEFAULT 0)
- `error_message` (TEXT)
- `created_at` (INTEGER, NOT NULL)
- `updated_at` (INTEGER, NOT NULL)

---

## 2. Remote Database (Cloud Firestore & Storage)

### Collections
- `/users/{userId}`: User profile and device registrations.
- `/users/{userId}/notebooks/{notebookId}`: Notebook documents.
- `/users/{userId}/notebooks/{notebookId}/pages/{pageId}`: Page metadata and lightweight summary.
- `/users/{userId}/notebooks/{notebookId}/pages/{pageId}/strokes/{strokeId}`: Chunked or individual strokes.
- `/users/{userId}/folders/{folderId}`: Folder hierarchy.
- `/users/{userId}/devices/{deviceId}`: Registered client devices for push synchronization.

### Cloud Storage Buckets
- `users/{userId}/notebooks/{notebookId}/pdfs/{documentId}.pdf`: Raw imported PDFs.
- `users/{userId}/notebooks/{notebookId}/audio/{recordingId}.m4a`: Audio recordings.
- `users/{userId}/covers/{coverId}.png`: Custom user cover images.


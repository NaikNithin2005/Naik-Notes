# Naik Notes — Testing Strategy & Verification Suite

## 1. Test Levels

Testing is mandatory and automated across four layers:

1. **Unit Tests (`test/unit/`)**:
   - Vector math & stroke smoothing (Catmull-Rom spline, Douglas-Peucker point reduction).
   - Stroke serialization & deserialization (points, pressure, bounding box).
   - Drift database CRUD operations.
   - Sync queue enqueue/dequeue, retry backoff algorithms.
   - Conflict resolution logic (deterministic last-write / non-destructive fork).

2. **Widget Tests (`test/widget/`)**:
   - App Shell responsive layout navigation (sidebar rail on desktop vs. navigation bar on mobile).
   - Notebook creation dialog with cover selection and template preview.
   - Handwriting canvas touch & stylus event routing.
   - Pen toolbar tool selection, color picker, and stroke width slider.
   - Sync status indicator badge transitions (synced, syncing, offline, error).

3. **Integration Tests (`integration_test/`)**:
   - End-to-end notebook creation -> stroke drawing -> local save -> verification.
   - PDF import -> annotation layering -> export.
   - Offline mutation -> network restore -> sync push.

4. **Backend API Tests (`backend/tests/`)**:
   - JWT authentication verification with Firebase Admin Mock.
   - Sync push and pull consistency.
   - Rate limiting and input sanitization.

---

## 2. Execution Commands

```powershell
# Run all Flutter tests
flutter test

# Run with coverage
flutter test --coverage

# Run analyzer
flutter analyze

# Run backend tests
cd backend
pytest tests/ -v
```


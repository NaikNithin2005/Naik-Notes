# Naik Notes

**Naik Notes** is a production-oriented, cross-platform digital handwritten notebook and PDF annotation suite engineered for **iPadOS**, **Android**, and **Windows 10/11**.

Inspired by premium stationery products, Naik Notes pairs realistic notebook covers and textured paper templates with vector handwriting rendering, low-latency stylus input, non-flattened PDF annotations, and offline-first cloud synchronization.

---

## 🌟 Key Features

- **Realistic Stationery & Aesthetics**: Clean, paper-inspired visual design with hand-crafted leather, dark academia, terracotta, sage, and floral covers.
- **Paper Template Engine**: 19+ built-in paper types including College Ruled, Cornell Notes, 5mm Square Grid, Dotted Matrix, Engineering Paper, Planners, and Blank Canvases.
- **Vector Handwriting**: Resolution-independent vector stroke storage with pressure, tilt, smoothing, lasso manipulation, and undo/redo history.
- **PDF Workspace**: Native PDF rendering, freehand inking, highlighting, text boxes, and non-destructive annotation layers.
- **Offline-First Cloud Sync**: Changes commit instantly to local SQLite (Drift) before syncing to Cloud Firestore and Firebase Storage.
- **Lecture Audio & AI Assistant**: Synchronized audio notes with timestamps, plus server-side AI study assistants for instant flashcard generation and summaries.
- **100% Free**: No mandatory subscriptions, no artificial notebook creation paywalls.

---

## 🏗️ Architecture

Naik Notes is built using a feature-first architectural pattern:

- **State Management**: [Riverpod 3.5](https://riverpod.dev)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Local Persistence**: [Drift ORM (SQLite)](https://drift.simonbinder.eu)
- **Backend & Cloud Bridge**: [FastAPI (Python)](https://fastapi.tiangolo.com) + Firebase Admin SDK + Cloud Firestore + Firebase Storage
- **Design System**: Material 3 with custom paper and ink palettes

For in-depth architectural details, refer to [ARCHITECTURE.md](file:///D:/WORKS/Naik%20Notes/ARCHITECTURE.md).

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.50+ (`D:\WORKS\flutter\bin`)
- Dart SDK 3.14+
- Python 3.11+ (for backend bridge)

### Running the Client

```powershell
# Fetch dependencies
flutter pub get

# Run static analysis
flutter analyze

# Execute test suite
flutter test

# Run on Chrome Web
flutter run -d chrome

# Run on Windows Desktop
flutter run -d windows
```

### Running the Backend

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

---

## 📖 Documentation Index

- [docs/PROGRESS.md](file:///D:/WORKS/Naik%20Notes/docs/PROGRESS.md) — Live milestone progress and execution logs.
- [ARCHITECTURE.md](file:///D:/WORKS/Naik%20Notes/ARCHITECTURE.md) — System architecture, layered boundaries, and data flows.
- [DATABASE.md](file:///D:/WORKS/Naik%20Notes/DATABASE.md) — SQLite (Drift) and Cloud Firestore schema definitions.
- [API.md](file:///D:/WORKS/Naik%20Notes/API.md) — Backend API specification and synchronization contracts.
- [TESTING.md](file:///D:/WORKS/Naik%20Notes/TESTING.md) — Automated testing matrix and verification procedures.
- [DEVELOPMENT.md](file:///D:/WORKS/Naik%20Notes/DEVELOPMENT.md) — Developer setup instructions and conventions.

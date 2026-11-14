# Naik Notes — Development Guide

## 1. Prerequisites

- **Flutter SDK**: 3.50.0 or later (`D:\WORKS\flutter\bin`)
- **Dart SDK**: 3.14.0 or later
- **Python**: 3.11+ (for backend services and Firebase Admin operations)
- **Node.js**: (optional, for Firebase CLI emulators)
- **Platforms Supported**:
  - Android (API 26+)
  - iOS / iPadOS (iOS 15+)
  - Windows Desktop (Windows 10 build 19041+, Windows 11)
  - Web (Chrome / Edge for debugging)

---

## 2. Environment Setup

### 2.1 Flutter Client Setup

```powershell
# Verify environment health
flutter doctor -v

# Fetch dependencies
flutter pub get

# Run tests
flutter test

# Run code analysis
flutter analyze

# Run on available device (Chrome web or Windows)
flutter run -d chrome
flutter run -d windows
```

### 2.2 Backend Setup (FastAPI + Firebase Admin)

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

---

## 3. Directory Structure Standards

- Do not place business logic in UI widgets.
- Every state container must use Riverpod `NotifierProvider` or `StateNotifierProvider`.
- All model transformations must validate nulls and retain backward compatibility.
- Colors must reference `AppColors` or `Theme.of(context).colorScheme` rather than hardcoded hex values.
- Handwriting strokes must always store pressure values and timestamps.

---

## 4. Code Quality Checks

Before committing or completing any milestone:
```powershell
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```


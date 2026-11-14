from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth

app = FastAPI(
    title="Naik Notes Backend API",
    description="Cross-platform sync and storage backend for Naik Notes (iPad, Android, Windows)",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "Naik Notes Backend",
        "version": "1.0.0",
        "platforms_supported": ["iPadOS", "Android", "Windows"],
    }

@app.get("/v1/notebooks")
def list_sample_notebooks():
    return {
        "notebooks": [
            {
                "id": "nb-1-math",
                "title": "Advanced Mathematics & Calculus",
                "page_count": 14,
                "is_favorite": True,
            },
            {
                "id": "nb-2-physics",
                "title": "Quantum Physics Lecture Notes",
                "page_count": 28,
                "is_favorite": True,
            },
        ]
    }

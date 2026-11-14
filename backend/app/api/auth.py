from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime, timezone
import uuid
import hashlib

router = APIRouter(prefix="/v1/auth", tags=["Authentication"])

# In-memory user database for development / tests (backed by Firebase Admin in production)
_users_db = {}

class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)
    displayName: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    email: str
    displayName: str
    photoUrl: Optional[str] = None
    token: str
    isGuest: bool = False
    createdAt: str
    updatedAt: str

def _hash_password(password: str) -> str:
    return hashlib.sha256(password.encode("utf-8")).hexdigest()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(req: RegisterRequest):
    email_clean = req.email.lower().strip()
    if email_clean in _users_db:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists."
        )

    now_iso = datetime.now(timezone.utc).isoformat()
    user_id = f"user_{uuid.uuid4().hex[:12]}"
    display_name = req.displayName.strip() if req.displayName and req.displayName.strip() else email_clean.split("@")[0]
    token = f"firebase_token_{uuid.uuid4().hex}"

    user_record = {
        "id": user_id,
        "email": email_clean,
        "displayName": display_name,
        "photoUrl": None,
        "password_hash": _hash_password(req.password),
        "token": token,
        "isGuest": False,
        "createdAt": now_iso,
        "updatedAt": now_iso,
    }
    _users_db[email_clean] = user_record

    return UserResponse(
        id=user_id,
        email=email_clean,
        displayName=display_name,
        photoUrl=None,
        token=token,
        isGuest=False,
        createdAt=now_iso,
        updatedAt=now_iso,
    )

@router.post("/login", response_model=UserResponse)
def login(req: LoginRequest):
    email_clean = req.email.lower().strip()
    user_record = _users_db.get(email_clean)

    if not user_record or user_record["password_hash"] != _hash_password(req.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password."
        )

    token = f"firebase_token_{uuid.uuid4().hex}"
    user_record["token"] = token
    user_record["updatedAt"] = datetime.now(timezone.utc).isoformat()

    return UserResponse(
        id=user_record["id"],
        email=user_record["email"],
        displayName=user_record["displayName"],
        photoUrl=user_record.get("photoUrl"),
        token=token,
        isGuest=False,
        createdAt=user_record["createdAt"],
        updatedAt=user_record["updatedAt"],
    )

@router.get("/me", response_model=UserResponse)
def get_current_user(token: str):
    for u in _users_db.values():
        if u["token"] == token:
            return UserResponse(
                id=u["id"],
                email=u["email"],
                displayName=u["displayName"],
                photoUrl=u.get("photoUrl"),
                token=u["token"],
                isGuest=False,
                createdAt=u["createdAt"],
                updatedAt=u["updatedAt"],
            )
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid session token.")


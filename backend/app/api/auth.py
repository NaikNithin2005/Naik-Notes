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

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetConfirmRequest(BaseModel):
    code: str
    newPassword: str = Field(..., min_length=6)

_reset_tokens = {}

@router.post("/password-reset/request")
def request_password_reset(req: PasswordResetRequest):
    email_clean = req.email.lower().strip()
    reset_code = f"naik_reset_{uuid.uuid4().hex[:16]}"
    _reset_tokens[reset_code] = {
        "email": email_clean,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    # Generate Naik Publications-Notes branded password reset email HTML
    branded_html = f"""
    <!DOCTYPE html>
    <html>
    <body style="font-family: -apple-system, sans-serif; background-color: #F8FAFC; padding: 24px;">
      <div style="max-width: 520px; margin: 0 auto; background: #FFFFFF; border-radius: 14px; padding: 32px; border: 1px solid #E2E8F0;">
        <h2 style="color: #0F172A; margin-top: 0; font-family: Georgia, serif;">Naik Notes</h2>
        <p style="color: #E07A5F; font-size: 12px; font-weight: bold; text-transform: uppercase;">Naik Publications-Notes</p>
        <p>Hello,</p>
        <p>You recently requested to reset the password for your Naik Notes account.</p>
        <p>To securely reset your password and regain access to your notebooks, notes, and documents, click the button below:</p>
        <div style="text-align: center; margin: 28px 0;">
          <a href="https://naik-notes.firebaseapp.com/reset-password?code={reset_code}" 
             style="background-color: #E07A5F; color: #FFFFFF; padding: 12px 28px; text-decoration: none; border-radius: 8px; font-weight: bold; display: inline-block;">
             Reset My Password
          </a>
        </div>
        <p style="font-size: 13px; color: #64748B;">If you did not request this password reset, you can safely ignore this email.</p>
        <hr style="border: none; border-top: 1px solid #E2E8F0; margin: 24px 0;" />
        <p style="font-size: 12px; color: #94A3B8; text-align: center;">Naik Publications-Notes &bull; Naik Notes &bull; &copy; 2026 All rights reserved.</p>
      </div>
    </body>
    </html>
    """

    return {
        "status": "success",
        "message": f"Password reset instructions dispatched to {email_clean}",
        "sender": "Naik Publications-Notes",
        "subject": "Reset Your Naik Notes Password",
        "reset_code": reset_code,
        "preview_html": branded_html,
    }

@router.post("/password-reset/confirm")
def confirm_password_reset(req: PasswordResetConfirmRequest):
    token_data = _reset_tokens.get(req.code)
    if not token_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired password reset action code."
        )

    email = token_data["email"]
    if email in _users_db:
        _users_db[email]["password_hash"] = _hash_password(req.newPassword)
        _users_db[email]["updatedAt"] = datetime.now(timezone.utc).isoformat()

    del _reset_tokens[req.code]

    return {
        "status": "success",
        "message": "Password reset successful. You can now log in with your new password.",
        "email": email,
    }


from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, EmailStr
from bson import ObjectId
from datetime import datetime, UTC

from core.database import get_db
from core.security import hash_password, verify_password, create_token
from core.config import settings

router = APIRouter()

# ── Schemas ──────────────────────────────────────────────────────────────────
class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    phone: str = ""
    admin_code: str = ""   # if provided and correct → role = admin

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

# ── Helpers ──────────────────────────────────────────────────────────────────
def _user_out(user: dict) -> dict:
    return {
        "id":    str(user["_id"]),
        "name":  user["name"],
        "email": user["email"],
        "phone": user.get("phone", ""),
        "role":  user.get("role", "user"),
        "loyalty_points": user.get("loyalty_points", 0),
        "created_at": str(user.get("created_at", "")),
    }

# ── Register ─────────────────────────────────────────────────────────────────
@router.post("/register")
async def register(body: RegisterRequest, db=Depends(get_db)):
    existing = await db.users.find_one({"email": body.email})
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    role = "user"
    if body.admin_code:
        if body.admin_code != settings.ADMIN_SECRET_CODE:
            raise HTTPException(status_code=400, detail="Invalid admin code")
        role = "admin"

    doc = {
        "name":           body.name,
        "email":          body.email,
        "password_hash":  hash_password(body.password),
        "phone":          body.phone,
        "role":           role,
        "loyalty_points": 0,
        "created_at":     datetime.now(UTC),
    }
    result = await db.users.insert_one(doc)
    doc["_id"] = result.inserted_id

    token = create_token({"sub": str(result.inserted_id), "role": role})
    return {"token": token, "user": _user_out(doc)}

# ── Login ─────────────────────────────────────────────────────────────────────
@router.post("/login")
async def login(body: LoginRequest, db=Depends(get_db)):
    user = await db.users.find_one({"email": body.email})
    if not user or not verify_password(body.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = create_token({"sub": str(user["_id"]), "role": user.get("role", "user")})
    return {"token": token, "user": _user_out(user)}

# ── Me ────────────────────────────────────────────────────────────────────────
@router.get("/me")
async def me(db=Depends(get_db), user=Depends(__import__("core.security", fromlist=["get_current_user"]).get_current_user)):
    return _user_out(user)

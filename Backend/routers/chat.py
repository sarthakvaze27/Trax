from fastapi import APIRouter, Depends
from pydantic import BaseModel
from bson import ObjectId
from datetime import datetime, UTC
from typing import Optional

from core.database import get_db
from core.security import get_current_user

router = APIRouter()

def _out(m: dict) -> dict:
    m["id"] = str(m.pop("_id"))
    return m

class SendMessage(BaseModel):
    room_id: str        # for DM: sorted "uid1_uid2", for group: "group_<id>"
    text: str
    group_id: Optional[str] = None

class CreateGroup(BaseModel):
    name: str
    member_ids: list[str]
    avatar_color: str = "#4CAF50"

# ── Get message history for a room ────────────────────────────────────────────
@router.get("/history/{room_id}")
async def get_history(room_id: str, db=Depends(get_db), user=Depends(get_current_user)):
    docs = await db.chat_messages.find(
        {"room_id": room_id}
    ).sort("created_at", 1).to_list(200)

    my_id = str(user["_id"])
    result = []
    for d in docs:
        d["id"] = str(d.pop("_id"))
        d["isMe"] = d.get("sender_id") == my_id
        d["timestamp"] = d.get("created_at", datetime.now(UTC)).isoformat()
        result.append(d)
    return result

# ── Send message (REST fallback — WS is primary) ─────────────────────────────
@router.post("/send")
async def send_message(body: SendMessage, db=Depends(get_db), user=Depends(get_current_user)):
    doc = {
        "room_id":   body.room_id,
        "sender_id": str(user["_id"]),
        "text":      body.text,
        "created_at": datetime.now(UTC),
    }
    if body.group_id:
        doc["group_id"] = body.group_id

    result = await db.chat_messages.insert_one(doc)
    doc["_id"] = result.inserted_id
    return _out(doc)

# ── List user's chat contacts ─────────────────────────────────────────────────
@router.get("/contacts")
async def get_contacts(db=Depends(get_db), user=Depends(get_current_user)):
    # Return all users except self (simplified — real app would filter friends)
    docs = await db.users.find(
        {"_id": {"$ne": user["_id"]}}
    ).to_list(200)
    return [{"id": str(d["_id"]), "name": d["name"], "email": d["email"]} for d in docs]

# ── Groups ─────────────────────────────────────────────────────────────────────
@router.post("/groups")
async def create_group(body: CreateGroup, db=Depends(get_db), user=Depends(get_current_user)):
    member_ids = list(set(body.member_ids + [str(user["_id"])]))
    doc = {
        "name":         body.name,
        "member_ids":   member_ids,
        "avatar_color": body.avatar_color,
        "created_by":   str(user["_id"]),
        "created_at":   datetime.now(UTC),
    }
    result = await db.groups.insert_one(doc)
    doc["_id"] = result.inserted_id
    doc["id"] = str(doc.pop("_id"))
    return doc

@router.get("/groups/my")
async def my_groups(db=Depends(get_db), user=Depends(get_current_user)):
    my_id = str(user["_id"])
    docs = await db.groups.find({"member_ids": my_id}).to_list(100)
    result = []
    for d in docs:
        d["id"] = str(d.pop("_id"))
        result.append(d)
    return result

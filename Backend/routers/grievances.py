from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from bson import ObjectId
from typing import Optional
from datetime import datetime, UTC

from core.database import get_db
from core.security import get_current_user, require_admin
from core.ws_manager import manager

router = APIRouter()

def _out(g: dict) -> dict:
    g["id"] = str(g.pop("_id"))
    return g

class GrievanceCreate(BaseModel):
    title: str
    description: Optional[str] = None
    facility_id: Optional[str] = None
    priority: str = "medium"   # low | medium | high

class StatusUpdate(BaseModel):
    status: str   # open | in_progress | resolved

# ── Submit grievance (user) ───────────────────────────────────────────────────
@router.post("/")
async def submit_grievance(
    body: GrievanceCreate,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    doc = {
        "user_id":     str(user["_id"]),
        "title":       body.title,
        "description": body.description,
        "facility_id": body.facility_id,
        "priority":    body.priority,
        "status":      "open",
        "created_at":  datetime.now(UTC),
        # Embed user snapshot
        "users": {
            "name":  user["name"],
            "email": user["email"],
        },
    }

    # Embed facility snapshot if provided
    if body.facility_id:
        facility = await db.facilities.find_one(
            {"_id": ObjectId(body.facility_id)}
        )
        if facility:
            doc["facilities"] = {
                "name":     facility["name"],
                "location": facility["location"],
            }

    result = await db.grievances.insert_one(doc)
    doc["_id"] = result.inserted_id
    created = _out(doc)
    await manager.broadcast("grievance_created", {
        "id": created["id"],
        "title": created.get("title", ""),
        "priority": created.get("priority", "medium"),
        "status": created.get("status", "open"),
        "submitted_by": created.get("users", {}),
    })
    return created

# ── My grievances ─────────────────────────────────────────────────────────────
@router.get("/my")
async def my_grievances(db=Depends(get_db), user=Depends(get_current_user)):
    docs = await db.grievances.find(
        {"user_id": str(user["_id"])}
    ).sort("created_at", -1).to_list(100)
    return [_out(d) for d in docs]

# ── Admin: all grievances ─────────────────────────────────────────────────────
@router.get("/admin/all")
async def all_grievances(db=Depends(get_db), _=Depends(require_admin)):
    docs = await db.grievances.find().sort("created_at", -1).to_list(500)
    return [_out(d) for d in docs]

# ── Update status (admin) ─────────────────────────────────────────────────────
@router.patch("/{grievance_id}/status")
async def update_status(
    grievance_id: str,
    body: StatusUpdate,
    db=Depends(get_db),
    _=Depends(require_admin),
):
    valid = {"open", "in_progress", "resolved"}
    if body.status not in valid:
        raise HTTPException(status_code=400, detail=f"Status must be one of {valid}")

    result = await db.grievances.update_one(
        {"_id": ObjectId(grievance_id)},
        {"$set": {"status": body.status, "updated_at": datetime.now(UTC)}},
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Grievance not found")
    await manager.broadcast("grievance_updated", {
        "id": grievance_id,
        "status": body.status,
    })
    return {"message": f"Status updated to {body.status}"}

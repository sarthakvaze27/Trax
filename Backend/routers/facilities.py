from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from bson import ObjectId
from typing import Optional, List
from datetime import datetime, UTC

from core.database import get_db
from core.security import get_current_user, require_admin
from core.ws_manager import manager

router = APIRouter()

# ── Helpers ──────────────────────────────────────────────────────────────────
def _out(f: dict) -> dict:
    f["id"] = str(f.pop("_id"))
    return f

# ── Schemas ──────────────────────────────────────────────────────────────────
class FacilityCreate(BaseModel):
    name: str
    location: str
    sag_tag: str = ""
    emoji: str = "🏟️"
    sports: List[str] = []
    amenities: List[str] = []
    price_per_hr: int = 500
    rating: float = 4.0
    is_open: bool = True
    lat: float = 15.4909      # default Panaji, Goa
    lng: float = 73.8278
    distance_km: float = 0.0
    utilization: int = 0
    mapbox_place_id: str = ""

class FacilityUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    price_per_hr: Optional[int] = None
    is_open: Optional[bool] = None
    amenities: Optional[List[str]] = None
    sports: Optional[List[str]] = None
    rating: Optional[float] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    utilization: Optional[int] = None

# ── GET all facilities (public) ───────────────────────────────────────────────
@router.get("/")
async def get_facilities(db=Depends(get_db)):
    docs = await db.facilities.find().to_list(100)
    return [_out(d) for d in docs]

# ── GET single facility ───────────────────────────────────────────────────────
@router.get("/{facility_id}")
async def get_facility(facility_id: str, db=Depends(get_db)):
    doc = await db.facilities.find_one({"_id": ObjectId(facility_id)})
    if not doc:
        raise HTTPException(status_code=404, detail="Facility not found")
    return _out(doc)

# ── GET available slots for a facility on a date ─────────────────────────────
@router.get("/{facility_id}/slots")
async def get_slots(facility_id: str, date: str, db=Depends(get_db)):
    """Returns list of hourly slots with availability."""
    facility = await db.facilities.find_one({"_id": ObjectId(facility_id)})
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")

    # Get confirmed bookings for this facility on this date
    bookings = await db.bookings.find({
        "facility_id": facility_id,
        "date": date,
        "status": "confirmed",
    }).to_list(100)

    booked_slots = set()
    for b in bookings:
        booked_slots.update(b.get("slots", []))

    # Build 6am–10pm slots
    all_slots = []
    for hour in range(6, 22):
        label = f"{hour:02d}:00 – {hour+1:02d}:00"
        slot_key = f"{hour:02d}"
        all_slots.append({
            "hour":      hour,
            "label":     label,
            "slot_key":  slot_key,
            "available": slot_key not in booked_slots,
        })
    return all_slots

# ── CREATE facility (admin) ───────────────────────────────────────────────────
@router.post("/")
async def create_facility(body: FacilityCreate, db=Depends(get_db), _=Depends(require_admin)):
    doc = body.dict()
    doc["created_at"] = datetime.now(UTC)
    result = await db.facilities.insert_one(doc)
    doc["_id"] = result.inserted_id
    created = _out(doc)
    # Broadcast to all WS clients
    await manager.broadcast("facility_created", created)
    return created

# ── UPDATE facility (admin) — triggers real-time push ────────────────────────
@router.patch("/{facility_id}")
async def update_facility(
    facility_id: str,
    body: FacilityUpdate,
    db=Depends(get_db),
    _=Depends(require_admin),
):
    updates = {k: v for k, v in body.dict().items() if v is not None}
    if not updates:
        raise HTTPException(status_code=400, detail="No fields to update")

    updates["updated_at"] = datetime.now(UTC)
    result = await db.facilities.update_one(
        {"_id": ObjectId(facility_id)}, {"$set": updates}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Facility not found")

    updated = await db.facilities.find_one({"_id": ObjectId(facility_id)})
    updated_out = _out(updated)

    # 🔴 Real-time push → all Flutter clients will update instantly
    await manager.broadcast("facility_updated", updated_out)
    return updated_out

# ── DELETE facility (admin) ───────────────────────────────────────────────────
@router.delete("/{facility_id}")
async def delete_facility(facility_id: str, db=Depends(get_db), _=Depends(require_admin)):
    result = await db.facilities.delete_one({"_id": ObjectId(facility_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Facility not found")
    await manager.broadcast("facility_deleted", {"id": facility_id})
    return {"message": "Deleted"}

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from bson import ObjectId
from typing import List
from datetime import datetime, UTC
import uuid

from core.database import get_db
from core.security import get_current_user

router = APIRouter()

def _out(b: dict) -> dict:
    b["id"] = str(b.pop("_id"))
    return b

class BookingCreate(BaseModel):
    facility_id: str
    date: str           # "YYYY-MM-DD"
    slots: List[str]    # ["06", "07", "08"] hour keys
    time_label: str     # "06:00 – 09:00"

# ── Create booking ────────────────────────────────────────────────────────────
@router.post("/")
async def create_booking(
    body: BookingCreate,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    facility = await db.facilities.find_one({"_id": ObjectId(body.facility_id)})
    if not facility:
        raise HTTPException(status_code=404, detail="Facility not found")
    if not facility.get("is_open", True):
        raise HTTPException(status_code=400, detail="Facility is currently closed")

    # Check slot conflicts
    conflict = await db.bookings.find_one({
        "facility_id": body.facility_id,
        "date":        body.date,
        "status":      "confirmed",
        "slots":       {"$in": body.slots},
    })
    if conflict:
        raise HTTPException(status_code=409, detail="One or more slots already booked")

    hours = len(body.slots)
    total_amount = hours * facility["price_per_hr"]
    qr_code = uuid.uuid4().hex[:8].upper()

    doc = {
        "user_id":      str(user["_id"]),
        "facility_id":  body.facility_id,
        "date":         body.date,
        "slots":        body.slots,
        "time_label":   body.time_label,
        "total_amount": total_amount,
        "qr_code":      qr_code,
        "status":       "confirmed",
        "created_at":   datetime.now(UTC),
        # Embed facility snapshot so it shows even if facility changes
        "facilities": {
            "name":     facility["name"],
            "location": facility["location"],
            "emoji":    facility.get("emoji", "🏟️"),
        },
    }
    result = await db.bookings.insert_one(doc)
    doc["_id"] = result.inserted_id

    # Award loyalty points: 1 pt per ₹10 spent
    pts = total_amount // 10
    if pts > 0:
        await db.users.update_one(
            {"_id": user["_id"]},
            {"$inc": {"loyalty_points": pts}},
        )

    # Update facility utilization (rough calc)
    total_bookings = await db.bookings.count_documents({
        "facility_id": body.facility_id,
        "status": "confirmed",
    })
    utilization = min(int((total_bookings / 50) * 100), 100)
    await db.facilities.update_one(
        {"_id": ObjectId(body.facility_id)},
        {"$set": {"utilization": utilization}},
    )

    return {
        "booking_id":   str(doc["_id"]),
        "qr_code":      qr_code,
        "facility_name": facility["name"],
        "date":         body.date,
        "time_label":   body.time_label,
        "total_amount": total_amount,
        "message":      f"Slot booked at {facility['name']}. Show QR at entrance.",
        "loyalty_earned": pts,
    }

# ── My bookings ───────────────────────────────────────────────────────────────
@router.get("/my")
async def my_bookings(db=Depends(get_db), user=Depends(get_current_user)):
    docs = await db.bookings.find(
        {"user_id": str(user["_id"])}
    ).sort("created_at", -1).to_list(200)
    return [_out(d) for d in docs]

# ── Cancel booking ────────────────────────────────────────────────────────────
@router.patch("/{booking_id}/cancel")
async def cancel_booking(
    booking_id: str,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    booking = await db.bookings.find_one({
        "_id":     ObjectId(booking_id),
        "user_id": str(user["_id"]),
    })
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking["status"] != "confirmed":
        raise HTTPException(status_code=400, detail="Booking is not active")

    await db.bookings.update_one(
        {"_id": ObjectId(booking_id)},
        {"$set": {"status": "cancelled", "cancelled_at": datetime.now(UTC)}},
    )
    return {"message": "Booking cancelled. Refund will be processed in 3–5 days."}

# ── Admin: all bookings ────────────────────────────────────────────────────────
@router.get("/admin/all")
async def all_bookings(db=Depends(get_db), user=Depends(get_current_user)):
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    docs = await db.bookings.find().sort("created_at", -1).to_list(500)
    return [_out(d) for d in docs]

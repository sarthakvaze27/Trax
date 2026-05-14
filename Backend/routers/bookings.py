from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from bson import ObjectId
from typing import List
from datetime import datetime, UTC
import uuid

from core.database import get_db
from core.security import get_current_user
from core.ws_manager import manager

router = APIRouter()

def _out(b: dict) -> dict:
    b["id"] = str(b.pop("_id"))
    return b

def _user_snapshot(user: dict) -> dict:
    return {
        "id": str(user["_id"]),
        "name": user.get("name", "Unknown user"),
        "email": user.get("email", ""),
        "phone": user.get("phone", ""),
    }

class BookingCreate(BaseModel):
    facility_id: str
    date: str           # "YYYY-MM-DD"
    slots: List[str]    # ["06", "07", "08"] hour keys
    split_count: int = 1
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
    split_count = max(1, min(body.split_count, 20))
    share_amount = (total_amount + split_count - 1) // split_count
    payment_links = []

    doc = {
        "user_id":      str(user["_id"]),
        "facility_id":  body.facility_id,
        "date":         body.date,
        "slots":        body.slots,
        "time_label":   body.time_label,
        "total_amount": total_amount,
        "qr_code":      qr_code,
        "status":       "confirmed",
        "payment_mode": "split" if split_count > 1 else "solo",
        "payment_status": "pending_split" if split_count > 1 else "paid",
        "split_count": split_count,
        "share_amount": share_amount,
        "created_at":   datetime.now(UTC),
        "user":         _user_snapshot(user),
        # Embed facility snapshot so it shows even if facility changes
        "facilities": {
            "name":     facility["name"],
            "location": facility["location"],
            "emoji":    facility.get("emoji", "🏟️"),
        },
    }
    result = await db.bookings.insert_one(doc)
    doc["_id"] = result.inserted_id

    if split_count > 1:
        owner_amount = share_amount
        remaining_amount = total_amount - owner_amount
        friend_count = split_count - 1
        for idx in range(friend_count):
            token = uuid.uuid4().hex
            amount = share_amount if idx < friend_count - 1 else remaining_amount - share_amount * (friend_count - 1)
            await db.payment_shares.insert_one({
                "booking_id": str(doc["_id"]),
                "payer_index": idx + 2,
                "amount": amount,
                "status": "pending",
                "token": token,
                "created_at": datetime.now(UTC),
            })
            payment_links.append({
                "payer": idx + 2,
                "amount": amount,
                "link": f"http://192.168.137.1:8000/api/bookings/pay/{token}",
            })

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

    created = {
        "booking_id":   str(doc["_id"]),
        "qr_code":      qr_code,
        "facility_name": facility["name"],
        "date":         body.date,
        "time_label":   body.time_label,
        "total_amount": total_amount,
        "facility_location": facility.get("location", ""),
        "payment_mode": doc["payment_mode"],
        "payment_status": doc["payment_status"],
        "split_count": split_count,
        "share_amount": share_amount,
        "payment_links": payment_links,
        "message":      f"Slot booked at {facility['name']}. Show QR at entrance.",
        "loyalty_earned": pts,
    }
    await manager.broadcast("booking_created", {
        "id": str(doc["_id"]),
        "facility_id": body.facility_id,
        "facility_name": facility["name"],
        "date": body.date,
        "time_label": body.time_label,
        "booked_by": doc["user"],
        "status": "confirmed",
    })
    return created

# ── My bookings ───────────────────────────────────────────────────────────────
@router.get("/my")
async def my_bookings(db=Depends(get_db), user=Depends(get_current_user)):
    docs = await db.bookings.find(
        {"user_id": str(user["_id"])}
    ).sort("created_at", -1).to_list(200)
    return [_out(d) for d in docs]

@router.get("/pay/{token}")
async def payment_share(token: str, db=Depends(get_db)):
    share = await db.payment_shares.find_one({"token": token})
    if not share:
        raise HTTPException(status_code=404, detail="Payment link not found")
    booking = await db.bookings.find_one({"_id": ObjectId(share["booking_id"])})
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return {
        "token": token,
        "amount": share.get("amount", 0),
        "status": share.get("status", "pending"),
        "facility": booking.get("facilities", {}).get("name", "Unknown"),
        "date": booking.get("date", ""),
        "time_label": booking.get("time_label", ""),
    }

@router.post("/pay/{token}/complete")
async def complete_payment_share(token: str, db=Depends(get_db)):
    share = await db.payment_shares.find_one({"token": token})
    if not share:
        raise HTTPException(status_code=404, detail="Payment link not found")
    await db.payment_shares.update_one(
        {"token": token},
        {"$set": {"status": "paid", "paid_at": datetime.now(UTC)}},
    )
    pending = await db.payment_shares.count_documents({
        "booking_id": share["booking_id"],
        "status": "pending",
    })
    if pending == 0:
        await db.bookings.update_one(
            {"_id": ObjectId(share["booking_id"])},
            {"$set": {"payment_status": "paid", "paid_at": datetime.now(UTC)}},
        )
    return {"message": "Payment marked as paid"}

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
    await manager.broadcast("booking_cancelled", {
        "id": booking_id,
        "facility_id": booking.get("facility_id", ""),
        "date": booking.get("date", ""),
        "time_label": booking.get("time_label", ""),
        "status": "cancelled",
    })
    return {"message": "Booking cancelled. Refund will be processed in 3–5 days."}

# ── Admin: all bookings ────────────────────────────────────────────────────────
@router.get("/admin/all")
async def all_bookings(db=Depends(get_db), user=Depends(get_current_user)):
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin only")
    docs = await db.bookings.find().sort("created_at", -1).to_list(500)
    for d in docs:
        if not d.get("user"):
            booked_by = await db.users.find_one({"_id": ObjectId(d.get("user_id"))})
            if booked_by:
                d["user"] = _user_snapshot(booked_by)
    return [_out(d) for d in docs]

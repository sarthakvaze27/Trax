from fastapi import APIRouter, Depends
from bson import ObjectId
from datetime import datetime, UTC
from core.database import get_db
from core.security import require_admin

router = APIRouter()

def _user_snapshot(user: dict | None) -> dict:
    if not user:
        return {
            "id": "",
            "name": "Unknown user",
            "email": "",
            "phone": "",
        }
    return {
        "id": str(user["_id"]),
        "name": user.get("name", "Unknown user"),
        "email": user.get("email", ""),
        "phone": user.get("phone", ""),
    }

async def _booking_user(db, booking: dict) -> dict:
    if booking.get("user"):
        return booking["user"]
    user_id = booking.get("user_id")
    if not user_id:
        return _user_snapshot(None)
    user = await db.users.find_one({"_id": ObjectId(user_id)})
    return _user_snapshot(user)

@router.get("/dashboard")
async def dashboard(db=Depends(get_db), _=Depends(require_admin)):
    """Returns KPI summary for the admin dashboard."""

    # Revenue: sum of all confirmed booking amounts
    pipeline = [
        {"$match": {"status": "confirmed"}},
        {"$group": {"_id": None, "total": {"$sum": "$total_amount"}}},
    ]
    rev_cursor = db.bookings.aggregate(pipeline)
    rev_result = await rev_cursor.to_list(1)
    total_revenue = rev_result[0]["total"] if rev_result else 0

    total_bookings   = await db.bookings.count_documents({"status": "confirmed"})
    cancelled_bookings = await db.bookings.count_documents({"status": "cancelled"})
    total_users      = await db.users.count_documents({"role": "user"})
    open_grievances  = await db.grievances.count_documents({"status": {"$in": ["open", "in_progress"]}})
    total_facilities = await db.facilities.count_documents({})
    today = datetime.now(UTC).date().isoformat()
    today_bookings = await db.bookings.count_documents({"date": today, "status": "confirmed"})

    # Per-facility utilization snapshot
    facilities_raw = await db.facilities.find(
        {}, {"name": 1, "emoji": 1, "utilization": 1, "is_open": 1}
    ).to_list(50)

    facilities = []
    for f in facilities_raw:
        facilities.append({
            "id":          str(f["_id"]),
            "name":        f.get("name", ""),
            "emoji":       f.get("emoji", "🏟️"),
            "utilization": f.get("utilization", 0),
            "is_open":     f.get("is_open", True),
        })

    # Recent bookings (last 10)
    recent_raw = await db.bookings.find().sort("created_at", -1).to_list(10)
    recent_bookings = []
    for b in recent_raw:
        recent_bookings.append({
            "id":           str(b["_id"]),
            "facility":     b.get("facilities", {}).get("name", "Unknown"),
            "booked_by":    await _booking_user(db, b),
            "date":         b.get("date", ""),
            "time_label":   b.get("time_label", ""),
            "total_amount": b.get("total_amount", 0),
            "status":       b.get("status", ""),
        })

    daily_raw = await db.bookings.aggregate([
        {"$match": {"status": "confirmed"}},
        {"$group": {
            "_id": "$date",
            "bookings": {"$sum": 1},
            "revenue": {"$sum": "$total_amount"},
        }},
        {"$sort": {"_id": -1}},
        {"$limit": 7},
    ]).to_list(7)
    daily_bookings = [
        {"date": d["_id"], "bookings": d["bookings"], "revenue": d["revenue"]}
        for d in reversed(daily_raw)
    ]

    top_raw = await db.bookings.aggregate([
        {"$match": {"status": "confirmed"}},
        {"$group": {
            "_id": "$facility_id",
            "facility": {"$first": "$facilities.name"},
            "bookings": {"$sum": 1},
            "revenue": {"$sum": "$total_amount"},
        }},
        {"$sort": {"bookings": -1}},
        {"$limit": 5},
    ]).to_list(5)
    top_facilities = [
        {
            "facility": f.get("facility") or "Unknown",
            "bookings": f.get("bookings", 0),
            "revenue": f.get("revenue", 0),
        }
        for f in top_raw
    ]

    slot_raw = await db.bookings.aggregate([
        {"$match": {"status": "confirmed"}},
        {"$unwind": "$slots"},
        {"$group": {"_id": "$slots", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}},
        {"$limit": 5},
    ]).to_list(5)
    peak_slots = [
        {"slot": f"{s['_id']}:00", "bookings": s.get("count", 0)}
        for s in slot_raw
    ]

    return {
        "kpis": {
            "total_revenue":    total_revenue,
            "total_bookings":   total_bookings,
            "today_bookings":   today_bookings,
            "cancelled_bookings": cancelled_bookings,
            "total_users":      total_users,
            "open_grievances":  open_grievances,
            "total_facilities": total_facilities,
        },
        "facilities":      facilities,
        "recent_bookings": recent_bookings,
        "analytics": {
            "daily_bookings": daily_bookings,
            "top_facilities": top_facilities,
            "peak_slots": peak_slots,
        },
    }

from fastapi import APIRouter, Depends
from core.database import get_db
from core.security import require_admin

router = APIRouter()

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
    total_users      = await db.users.count_documents({"role": "user"})
    open_grievances  = await db.grievances.count_documents({"status": {"$in": ["open", "in_progress"]}})
    total_facilities = await db.facilities.count_documents({})

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
            "date":         b.get("date", ""),
            "time_label":   b.get("time_label", ""),
            "total_amount": b.get("total_amount", 0),
            "status":       b.get("status", ""),
        })

    return {
        "kpis": {
            "total_revenue":    total_revenue,
            "total_bookings":   total_bookings,
            "total_users":      total_users,
            "open_grievances":  open_grievances,
            "total_facilities": total_facilities,
        },
        "facilities":      facilities,
        "recent_bookings": recent_bookings,
    }

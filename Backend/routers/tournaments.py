from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from bson import ObjectId
from typing import Optional, List
from datetime import datetime, UTC

from core.database import get_db
from core.security import get_current_user, require_admin

router = APIRouter()

def _out(t: dict) -> dict:
    t["id"] = str(t.pop("_id"))
    return t

class TournamentCreate(BaseModel):
    name: str
    sport: str
    start_date: str
    end_date: str
    location: str = ""
    max_teams: int = 16
    prize_pool: Optional[str] = None
    status: str = "upcoming"   # upcoming | ongoing | completed

# ── List all (public) ─────────────────────────────────────────────────────────
@router.get("/")
async def get_tournaments(db=Depends(get_db)):
    docs = await db.tournaments.find().sort("start_date", 1).to_list(100)
    for d in docs:
        d["registered"] = await db.tournament_registrations.count_documents(
            {"tournament_id": str(d["_id"])}
        )
    return [_out(d) for d in docs]

# ── Create (admin) ────────────────────────────────────────────────────────────
@router.post("/")
async def create_tournament(
    body: TournamentCreate,
    db=Depends(get_db),
    _=Depends(require_admin),
):
    doc = body.dict()
    doc["created_at"] = datetime.now(UTC)
    result = await db.tournaments.insert_one(doc)
    doc["_id"] = result.inserted_id
    return _out(doc)

# ── Register interest (user) ──────────────────────────────────────────────────
@router.post("/{tournament_id}/register")
async def register_interest(
    tournament_id: str,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    t = await db.tournaments.find_one({"_id": ObjectId(tournament_id)})
    if not t:
        raise HTTPException(status_code=404, detail="Tournament not found")

    already = await db.tournament_registrations.find_one({
        "tournament_id": tournament_id,
        "user_id": str(user["_id"]),
    })
    if already:
        raise HTTPException(status_code=400, detail="Already registered")

    await db.tournament_registrations.insert_one({
        "tournament_id": tournament_id,
        "user_id": str(user["_id"]),
        "registered_at": datetime.now(UTC),
    })
    return {"message": "Registered successfully!"}

# ── Update status (admin) ─────────────────────────────────────────────────────
@router.patch("/{tournament_id}")
async def update_tournament(
    tournament_id: str,
    status: str,
    db=Depends(get_db),
    _=Depends(require_admin),
):
    await db.tournaments.update_one(
        {"_id": ObjectId(tournament_id)},
        {"$set": {"status": status, "updated_at": datetime.now(UTC)}},
    )
    return {"message": "Updated"}

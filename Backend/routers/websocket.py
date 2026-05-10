from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from core.ws_manager import manager
from core.database import get_db
from core.security import decode_token
from datetime import datetime, UTC
import json

router = APIRouter()

# ── Global updates WebSocket ──────────────────────────────────────────────────
# Flutter connects here to receive live facility_updated / facility_created events
@router.websocket("/updates")
async def updates_ws(ws: WebSocket):
    await manager.connect(ws)
    try:
        while True:
            # Keep connection alive; client can send ping
            data = await ws.receive_text()
            if data == "ping":
                await ws.send_text(json.dumps({"event": "pong"}))
    except WebSocketDisconnect:
        manager.disconnect(ws)


# ── Chat WebSocket ─────────────────────────────────────────────────────────────
# Flutter connects with ?token=<jwt>&room=<room_id>
@router.websocket("/chat")
async def chat_ws(
    ws: WebSocket,
    token: str = Query(...),
    room: str = Query(...),
):
    # Authenticate
    try:
        payload = decode_token(token)
        sender_id = payload["sub"]
    except Exception:
        await ws.close(code=1008)
        return

    await manager.connect(ws)
    await manager.join_room(room, ws)

    db = get_db()

    try:
        while True:
            raw = await ws.receive_text()
            data = json.loads(raw)
            text = data.get("text", "").strip()
            if not text:
                continue

            # Persist to MongoDB
            doc = {
                "room_id":    room,
                "sender_id":  sender_id,
                "text":       text,
                "created_at": datetime.now(UTC),
            }
            if data.get("group_id"):
                doc["group_id"] = data["group_id"]

            result = await db.chat_messages.insert_one(doc)

            # Broadcast to everyone in the room
            await manager.send_to_room(room, "new_message", {
                "id":        str(result.inserted_id),
                "room_id":   room,
                "sender_id": sender_id,
                "text":      text,
                "timestamp": datetime.now(UTC).isoformat(),
            })
    except WebSocketDisconnect:
        manager.leave_room(room, ws)
        manager.disconnect(ws)
    except Exception:
        manager.leave_room(room, ws)
        manager.disconnect(ws)

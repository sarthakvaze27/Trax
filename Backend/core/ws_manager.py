from fastapi import WebSocket
import json
from typing import Dict, List

class ConnectionManager:
    """
    Manages all active WebSocket connections.
    Supports:
    - Broadcasting to ALL connected clients (e.g. facility price/open updates)
    - Room-based messaging (e.g. chat rooms)
    """

    def __init__(self):
        self.active: List[WebSocket] = []                    # global listeners
        self.rooms: Dict[str, List[WebSocket]] = {}          # room_id → sockets

    # ── Global ───────────────────────────────────────────────────────────────
    async def connect(self, ws: WebSocket):
        await ws.accept()
        self.active.append(ws)

    def disconnect(self, ws: WebSocket):
        self.active = [c for c in self.active if c != ws]
        for room in self.rooms.values():
            if ws in room:
                room.remove(ws)

    async def broadcast(self, event: str, data: dict):
        """Send an event to all global listeners."""
        msg = json.dumps({"event": event, "data": data})
        dead = []
        for ws in self.active:
            try:
                await ws.send_text(msg)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(ws)

    # ── Rooms (chat) ─────────────────────────────────────────────────────────
    async def join_room(self, room_id: str, ws: WebSocket):
        if room_id not in self.rooms:
            self.rooms[room_id] = []
        self.rooms[room_id].append(ws)

    def leave_room(self, room_id: str, ws: WebSocket):
        if room_id in self.rooms and ws in self.rooms[room_id]:
            self.rooms[room_id].remove(ws)

    async def send_to_room(self, room_id: str, event: str, data: dict):
        msg = json.dumps({"event": event, "data": data})
        if room_id not in self.rooms:
            return
        dead = []
        for ws in self.rooms[room_id]:
            try:
                await ws.send_text(msg)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.leave_room(room_id, ws)


# Singleton — imported everywhere
manager = ConnectionManager()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from core.database import connect_db, close_db
from routers import auth, facilities, bookings, grievances, tournaments, chat, admin, websocket

@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    yield
    await close_db()

app = FastAPI(title="SportSetu API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(auth.router,         prefix="/api/auth",        tags=["Auth"])
app.include_router(facilities.router,   prefix="/api/facilities",  tags=["Facilities"])
app.include_router(bookings.router,     prefix="/api/bookings",    tags=["Bookings"])
app.include_router(grievances.router,   prefix="/api/grievances",  tags=["Grievances"])
app.include_router(tournaments.router,  prefix="/api/tournaments", tags=["Tournaments"])
app.include_router(chat.router,         prefix="/api/chat",        tags=["Chat"])
app.include_router(admin.router,        prefix="/api/admin",       tags=["Admin"])
app.include_router(websocket.router,    prefix="/ws",              tags=["WebSocket"])

@app.get("/")
async def root():
    return {"message": "SportSetu API is running 🏟️"}

from motor.motor_asyncio import AsyncIOMotorClient
from core.config import settings

_client = None

async def connect_db():
    global _client
    _client = AsyncIOMotorClient(settings.MONGO_URI)

async def close_db():
    if _client:
        _client.close()

def get_db():
    return _client[settings.DB_NAME]
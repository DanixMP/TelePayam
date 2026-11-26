import os

os.environ["ENVIRONMENT"] = "test"
os.environ["DEBUG"] = "true"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///./test_messenger.db"
os.environ["REDIS_URL"] = ""
os.environ["JWT_SECRET"] = "test-jwt-secret-with-at-least-32-characters"
os.environ["DATA_HMAC_KEY"] = "test-hmac-secret-with-at-least-32-characters"
os.environ["LIVEKIT_API_SECRET"] = "test-livekit-secret-with-at-least-32-characters"

import httpx
import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import Base
from app.db.session import SessionLocal, engine
from app.main import app


@pytest.fixture(autouse=True)
async def clean_database():
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.drop_all)
        await connection.run_sync(Base.metadata.create_all)
    yield


@pytest.fixture
async def db() -> AsyncSession:
    async with SessionLocal() as session:
        yield session


@pytest.fixture
async def client():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as value:
        yield value

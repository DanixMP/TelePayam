import asyncio
from contextlib import asynccontextmanager, suppress
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text

from app.core.config import get_settings
from app.core.errors import install_error_handlers
from app.core.logging import configure_logging
from app.core.store import get_store
from app.db.base import Base
from app.db.session import SessionLocal, engine
from app.modules.approvals.router import router as approvals_router
from app.modules.auth.router import router as auth_router
from app.modules.calls.router import router as calls_router
from app.modules.conversations.router import router as conversations_router
from app.modules.media.router import router as media_router
from app.modules.messages.router import router as messages_router
from app.modules.realtime.manager import manager
from app.modules.realtime.router import router as realtime_router
from app.modules.reports.router import router as reports_router
from app.modules.search.router import router as search_router
from app.modules.services.router import router as services_router
from app.modules.stickers.router import router as stickers_router
from app.modules.users.router import router as users_router

configure_logging()
settings = get_settings()


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings.media_root.mkdir(parents=True, exist_ok=True)
    if settings.environment in {"development", "test"}:
        # Production deploys must run Alembic before starting the application.
        async with engine.begin() as connection:
            await connection.run_sync(Base.metadata.create_all)
    listener = asyncio.create_task(manager.listen(get_store()))
    yield
    listener.cancel()
    with suppress(asyncio.CancelledError):
        await listener
    await engine.dispose()


app = FastAPI(
    title=settings.app_name,
    description="Review student registrations in the [admin panel](/admin/).",
    version="0.1.0",
    lifespan=lifespan,
)
install_error_handlers(app)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

for router in (
    auth_router,
    users_router,
    approvals_router,
    conversations_router,
    messages_router,
    search_router,
    reports_router,
    services_router,
    media_router,
    stickers_router,
    calls_router,
    realtime_router,
):
    app.include_router(router, prefix="/api/v1" if router is not realtime_router else "")

app.mount(
    "/admin",
    StaticFiles(directory=Path(__file__).parent / "admin_panel", html=True),
    name="admin-panel",
)


@app.get("/health", tags=["operations"])
async def health():
    return {"status": "ok"}


@app.get("/ready", tags=["operations"])
async def ready():
    async with SessionLocal() as db:
        await db.execute(text("SELECT 1"))
    return {"status": "ready"}

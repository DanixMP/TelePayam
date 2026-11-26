import logging

from arq.connections import RedisSettings

from app.core.config import get_settings

logger = logging.getLogger(__name__)


async def send_push(ctx, user_id: str, event: str) -> None:
    # FCM/UnifiedPush providers plug in here; payloads intentionally omit message text.
    logger.info("push queued user=%s event=%s", user_id, event)


async def process_media(ctx, media_id: str) -> None:
    # ffmpeg/thumbnail processing is isolated from request workers.
    logger.info("media processing queued media=%s", media_id)


def redis_settings() -> RedisSettings:
    url = get_settings().redis_url or "redis://localhost:6379/0"
    return RedisSettings.from_dsn(url)


class WorkerSettings:
    functions = [send_push, process_media]
    redis_settings = redis_settings()
    max_jobs = 4
    job_timeout = 300

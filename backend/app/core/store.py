import asyncio
import time
from collections import defaultdict
from typing import Protocol

from redis.asyncio import Redis

from app.core.config import get_settings


class KeyValueStore(Protocol):
    async def get(self, key: str) -> str | None: ...

    async def set(self, key: str, value: str, ttl: int) -> None: ...

    async def delete(self, key: str) -> None: ...

    async def increment(self, key: str, ttl: int) -> int: ...

    async def publish(self, channel: str, message: str) -> None: ...


class MemoryStore:
    def __init__(self) -> None:
        self._values: dict[str, tuple[str, float]] = {}
        self._counts: defaultdict[str, int] = defaultdict(int)
        self._expires: dict[str, float] = {}
        self._lock = asyncio.Lock()

    async def get(self, key: str) -> str | None:
        async with self._lock:
            item = self._values.get(key)
            if not item or item[1] <= time.monotonic():
                self._values.pop(key, None)
                return None
            return item[0]

    async def set(self, key: str, value: str, ttl: int) -> None:
        async with self._lock:
            self._values[key] = (value, time.monotonic() + ttl)

    async def delete(self, key: str) -> None:
        async with self._lock:
            self._values.pop(key, None)
            self._counts.pop(key, None)
            self._expires.pop(key, None)

    async def increment(self, key: str, ttl: int) -> int:
        async with self._lock:
            now = time.monotonic()
            if self._expires.get(key, 0) <= now:
                self._counts[key] = 0
                self._expires[key] = now + ttl
            self._counts[key] += 1
            return self._counts[key]

    async def publish(self, channel: str, message: str) -> None:
        return None


class RedisStore:
    def __init__(self, client: Redis) -> None:
        self.client = client

    async def get(self, key: str) -> str | None:
        return await self.client.get(key)

    async def set(self, key: str, value: str, ttl: int) -> None:
        await self.client.set(key, value, ex=ttl)

    async def delete(self, key: str) -> None:
        await self.client.delete(key)

    async def increment(self, key: str, ttl: int) -> int:
        async with self.client.pipeline(transaction=True) as pipe:
            pipe.incr(key)
            pipe.expire(key, ttl, nx=True)
            count, _ = await pipe.execute()
        return int(count)

    async def publish(self, channel: str, message: str) -> None:
        await self.client.publish(channel, message)


_store: KeyValueStore | None = None


def get_store() -> KeyValueStore:
    global _store
    if _store is None:
        settings = get_settings()
        if settings.redis_url:
            client = Redis.from_url(settings.redis_url, decode_responses=True)
            _store = RedisStore(client)
        else:
            _store = MemoryStore()
    return _store


def set_store(store: KeyValueStore) -> None:
    global _store
    _store = store

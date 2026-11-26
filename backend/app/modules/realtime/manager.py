import asyncio
import json
import uuid
from collections import defaultdict
from contextlib import suppress
from typing import Any
from uuid import UUID

from fastapi import WebSocket

from app.core.store import KeyValueStore, RedisStore


class ConnectionManager:
    def __init__(self) -> None:
        self.instance_id = str(uuid.uuid4())
        self._connections: defaultdict[UUID, set[WebSocket]] = defaultdict(set)
        self._lock = asyncio.Lock()

    async def connect(self, user_id: UUID, websocket: WebSocket) -> None:
        await websocket.accept()
        async with self._lock:
            self._connections[user_id].add(websocket)

    async def disconnect(self, user_id: UUID, websocket: WebSocket) -> None:
        async with self._lock:
            self._connections[user_id].discard(websocket)
            if not self._connections[user_id]:
                self._connections.pop(user_id, None)

    async def send_user(self, user_id: UUID, event: dict[str, Any]) -> None:
        sockets = list(self._connections.get(user_id, ()))
        for socket in sockets:
            try:
                await socket.send_json(event)
            except Exception:
                await self.disconnect(user_id, socket)

    async def fanout(
        self,
        user_ids: list[UUID],
        event: dict[str, Any],
        store: KeyValueStore,
    ) -> None:
        for user_id in user_ids:
            await self.send_user(user_id, event)
        envelope = json.dumps(
            {
                "origin": self.instance_id,
                "users": [str(item) for item in user_ids],
                "event": event,
            },
            default=str,
        )
        await store.publish("realtime", envelope)

    async def listen(self, store: KeyValueStore) -> None:
        if not isinstance(store, RedisStore):
            return
        pubsub = store.client.pubsub()
        await pubsub.subscribe("realtime")
        try:
            async for message in pubsub.listen():
                if message["type"] != "message":
                    continue
                envelope = json.loads(message["data"])
                if envelope.get("origin") == self.instance_id:
                    continue
                for user_id in envelope.get("users", []):
                    await self.send_user(UUID(user_id), envelope["event"])
        finally:
            with suppress(Exception):
                await pubsub.unsubscribe("realtime")
                await pubsub.close()


manager = ConnectionManager()

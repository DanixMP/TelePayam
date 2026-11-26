from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from pydantic import ValidationError
from sqlalchemy import select

from app.core.config import get_settings
from app.core.enums import AccountStatus
from app.core.policy import require_conversation
from app.core.security import decode_access_token
from app.core.store import get_store
from app.db.models import Message, User
from app.db.session import SessionLocal
from app.modules.calls import service as call_service
from app.modules.calls.schemas import CallCreate
from app.modules.messages import service as message_service
from app.modules.messages.schemas import MessageCreate
from app.modules.realtime.events import broadcast_users, conversation_recipients
from app.modules.realtime.manager import manager

router = APIRouter()


async def authenticate(websocket: WebSocket) -> User | None:
    token = websocket.query_params.get("token")
    if not token:
        auth = websocket.headers.get("authorization", "")
        token = auth.removeprefix("Bearer ") if auth.startswith("Bearer ") else None
    if not token:
        return None
    try:
        claims = decode_access_token(token, get_settings())
        user_id = UUID(claims["sub"])
    except Exception:
        return None
    async with SessionLocal() as db:
        user = await db.get(User, user_id)
        if not user or user.status != AccountStatus.ACTIVE.value or user.role != claims.get("role"):
            return None
        db.expunge(user)
        return user


@router.websocket("/ws")
async def websocket_gateway(websocket: WebSocket) -> None:
    user = await authenticate(websocket)
    if not user:
        await websocket.close(code=4401)
        return
    await manager.connect(user.id, websocket)
    store = get_store()
    settings = get_settings()
    try:
        while True:
            frame = await websocket.receive_json()
            event_type = frame.get("type")
            data = frame.get("data") or {}
            try:
                if event_type == "ping":
                    await websocket.send_json({"type": "pong"})
                elif event_type == "msg.send":
                    conversation_id = UUID(str(data.pop("conv")))
                    payload = MessageCreate.model_validate(data)
                    async with SessionLocal() as db:
                        db_user = await db.get(User, user.id)
                        message, created = await message_service.send_message(
                            db, db_user, conversation_id, payload, settings
                        )
                        serialized = await message_service.serialize_message(db, message, settings)
                    body = serialized.model_dump(mode="json")
                    await websocket.send_json(
                        {
                            "type": "msg.ack",
                            "data": {
                                "client_msg_id": message.client_msg_id,
                                "seq": message.seq,
                                "id": str(message.id),
                            },
                        }
                    )
                    if created:
                        async with SessionLocal() as recipient_db:
                            recipients = await conversation_recipients(
                                recipient_db, conversation_id
                            )
                        await manager.fanout(recipients, {"type": "msg.new", "data": body}, store)
                elif event_type == "sync":
                    cursors = data.get("conv", {})
                    updates: list[dict] = []
                    async with SessionLocal() as db:
                        db_user = await db.get(User, user.id)
                        for raw_id, last_seq in list(cursors.items())[:100]:
                            conversation_id = UUID(raw_id)
                            await require_conversation(db, db_user, conversation_id, "read")
                            messages = list(
                                await db.scalars(
                                    select(Message)
                                    .where(
                                        Message.conversation_id == conversation_id,
                                        Message.seq > int(last_seq),
                                    )
                                    .order_by(Message.seq)
                                    .limit(500)
                                )
                            )
                            updates.extend(
                                [
                                    (
                                        await message_service.serialize_message(db, item, settings)
                                    ).model_dump(mode="json")
                                    for item in messages
                                ]
                            )
                    await websocket.send_json({"type": "sync.result", "data": updates})
                elif event_type == "read":
                    conversation_id = UUID(str(data["conv"]))
                    seq = int(data["seq"])
                    async with SessionLocal() as db:
                        db_user = await db.get(User, user.id)
                        conversation, member = await require_conversation(
                            db, db_user, conversation_id, "read"
                        )
                        if seq > conversation.last_seq:
                            raise ValueError("Read sequence is too high")
                        if member and seq > member.last_read_seq:
                            member.last_read_seq = seq
                            await db.commit()
                    async with SessionLocal() as recipient_db:
                        recipients = await conversation_recipients(recipient_db, conversation_id)
                    await manager.fanout(
                        recipients,
                        {
                            "type": "read.update",
                            "data": {
                                "conv": str(conversation_id),
                                "user": str(user.id),
                                "seq": seq,
                            },
                        },
                        store,
                    )
                elif event_type == "typing":
                    conversation_id = UUID(str(data["conv"]))
                    async with SessionLocal() as db:
                        db_user = await db.get(User, user.id)
                        await require_conversation(db, db_user, conversation_id, "read")
                    async with SessionLocal() as recipient_db:
                        recipients = [
                            item
                            for item in await conversation_recipients(recipient_db, conversation_id)
                            if item != user.id
                        ]
                    await manager.fanout(
                        recipients,
                        {
                            "type": "typing",
                            "data": {
                                "conv": str(conversation_id),
                                "user": str(user.id),
                                "action": data.get("action", "typing"),
                            },
                        },
                        store,
                    )
                elif event_type == "call.invite":
                    payload = CallCreate.model_validate(
                        {
                            "conversation_id": data.get("conversation_id") or data.get("conv"),
                            "client_call_id": data.get("client_call_id"),
                            "kind": data.get("kind", "audio"),
                        }
                    )
                    async with SessionLocal() as db:
                        db_user = await db.get(User, user.id)
                        call, created = await call_service.create_call(
                            db,
                            db_user,
                            payload.conversation_id,
                            payload.client_call_id,
                            payload.kind,
                        )
                        output = await call_service.serialize_call(db, call)
                        recipients = await call_service.participant_ids(db, call.id)
                    if created:
                        await broadcast_users(
                            recipients, "call.invite", output.model_dump(mode="json")
                        )
                    else:
                        await websocket.send_json(
                            {"type": "call.state", "data": output.model_dump(mode="json")}
                        )
                elif event_type in {"call.accept", "call.decline", "call.end"}:
                    call_id = UUID(str(data["call_id"]))
                    async with SessionLocal() as db:
                        db_user = await db.get(User, user.id)
                        if event_type == "call.accept":
                            call = await call_service.accept_call(db, db_user, call_id)
                        elif event_type == "call.decline":
                            call = await call_service.decline_call(db, db_user, call_id)
                        else:
                            call = await call_service.end_call(db, db_user, call_id)
                        output = await call_service.serialize_call(db, call)
                        recipients = await call_service.participant_ids(db, call.id)
                    await broadcast_users(recipients, event_type, output.model_dump(mode="json"))
                else:
                    await websocket.send_json(
                        {"type": "error", "data": {"code": "unsupported_event"}}
                    )
            except (ValueError, KeyError, ValidationError) as exc:
                await websocket.send_json(
                    {"type": "error", "data": {"code": "invalid_frame", "detail": str(exc)}}
                )
            except Exception as exc:
                code = getattr(exc, "code", "request_failed")
                detail = getattr(exc, "detail", "Realtime request failed")
                await websocket.send_json(
                    {"type": "error", "data": {"code": code, "detail": detail}}
                )
    except WebSocketDisconnect:
        pass
    finally:
        await manager.disconnect(user.id, websocket)

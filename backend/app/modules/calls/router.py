from datetime import timedelta
from typing import Annotated
from uuid import UUID

import jwt
from fastapi import APIRouter, Depends
from sqlalchemy import select

from app.core.config import Settings, get_settings
from app.core.deps import ActiveUser, Db
from app.core.enums import CallParticipantStatus, CallStatus
from app.core.errors import AppError
from app.core.security import utcnow
from app.db.models import CallParticipant, CallSession
from app.modules.calls import service
from app.modules.calls.schemas import CallCreate, CallOut, CallTokenOut, CallTokenRequest
from app.modules.realtime.events import broadcast_users

router = APIRouter(prefix="/calls", tags=["calls"])


async def emit_call(db: Db, call: CallSession, event_type: str) -> None:
    output = await service.serialize_call(db, call)
    await broadcast_users(
        await service.participant_ids(db, call.id), event_type, output.model_dump(mode="json")
    )


@router.post("", response_model=CallOut, status_code=201)
async def create_call(payload: CallCreate, db: Db, user: ActiveUser):
    call, created = await service.create_call(
        db, user, payload.conversation_id, payload.client_call_id, payload.kind
    )
    output = await service.serialize_call(db, call)
    if created:
        await emit_call(db, call, "call.invite")
    return output


@router.get("", response_model=list[CallOut])
async def call_history(db: Db, user: ActiveUser, limit: int = 50):
    calls = list(
        await db.scalars(
            select(CallSession)
            .join(CallParticipant, CallParticipant.call_id == CallSession.id)
            .where(CallParticipant.user_id == user.id)
            .order_by(CallSession.created_at.desc())
            .limit(min(max(limit, 1), 100))
        )
    )
    return [await service.serialize_call(db, call) for call in calls]


@router.get("/{call_id}", response_model=CallOut)
async def get_call(call_id: UUID, db: Db, user: ActiveUser):
    call, _ = await service.require_participant(db, user, call_id)
    return await service.serialize_call(db, call)


@router.post("/{call_id}/accept", response_model=CallOut)
async def accept_call(call_id: UUID, db: Db, user: ActiveUser):
    call = await service.accept_call(db, user, call_id)
    await emit_call(db, call, "call.accept")
    return await service.serialize_call(db, call)


@router.post("/{call_id}/decline", response_model=CallOut)
async def decline_call(call_id: UUID, db: Db, user: ActiveUser):
    call = await service.decline_call(db, user, call_id)
    await emit_call(db, call, "call.decline")
    return await service.serialize_call(db, call)


@router.post("/{call_id}/end", response_model=CallOut)
async def end_call(call_id: UUID, db: Db, user: ActiveUser):
    call = await service.end_call(db, user, call_id)
    await emit_call(db, call, "call.end")
    return await service.serialize_call(db, call)


@router.post("/token", response_model=CallTokenOut)
async def call_token(
    payload: CallTokenRequest,
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    call = await db.get(CallSession, payload.call_session_id) if payload.call_session_id else None
    if not call and payload.conversation_id:
        call = await db.scalar(
            select(CallSession)
            .join(CallParticipant, CallParticipant.call_id == CallSession.id)
            .where(
                CallSession.conversation_id == payload.conversation_id,
                CallSession.status == CallStatus.ACTIVE.value,
                CallParticipant.user_id == user.id,
                CallParticipant.status == CallParticipantStatus.ACCEPTED.value,
            )
            .order_by(CallSession.created_at.desc())
        )
    participant = await db.get(CallParticipant, (call.id, user.id)) if call else None
    if (
        not call
        or call.status != CallStatus.ACTIVE.value
        or not participant
        or participant.status != CallParticipantStatus.ACCEPTED.value
    ):
        raise AppError(403, "active_call_required", "An active accepted call session is required")
    room = f"call-{call.id}"
    now = utcnow()
    claims = {
        "iss": settings.livekit_api_key,
        "sub": str(user.id),
        "name": " ".join(filter(None, [user.first_name, user.last_name])),
        "nbf": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=10)).timestamp()),
        "video": {
            "roomJoin": True,
            "room": room,
            "canPublish": True,
            "canSubscribe": True,
        },
    }
    token = jwt.encode(claims, settings.livekit_api_secret, algorithm="HS256")
    return CallTokenOut(url=settings.livekit_url, room=room, token=token)

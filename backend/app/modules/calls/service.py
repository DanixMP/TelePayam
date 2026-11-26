from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import (
    CallParticipantStatus,
    CallStatus,
    ConversationType,
    MemberRole,
)
from app.core.errors import AppError
from app.core.policy import require_conversation
from app.core.security import utcnow
from app.db.models import CallParticipant, CallSession, ConversationMember, User
from app.modules.calls.schemas import CallOut, CallParticipantOut


async def serialize_call(db: AsyncSession, call: CallSession) -> CallOut:
    participants = list(
        await db.scalars(
            select(CallParticipant)
            .where(CallParticipant.call_id == call.id)
            .order_by(CallParticipant.user_id)
        )
    )
    return CallOut(
        id=call.id,
        conversation_id=call.conversation_id,
        caller_id=call.caller_id,
        client_call_id=call.client_call_id,
        kind=call.kind,
        status=call.status,
        started_at=call.started_at,
        ended_at=call.ended_at,
        ended_by=call.ended_by,
        created_at=call.created_at,
        participants=[CallParticipantOut.model_validate(item) for item in participants],
    )


async def create_call(
    db: AsyncSession,
    actor: User,
    conversation_id: UUID,
    client_call_id: str,
    kind: str,
) -> tuple[CallSession, bool]:
    conversation, _ = await require_conversation(db, actor, conversation_id, "read")
    if conversation.type != ConversationType.DM.value:
        raise AppError(422, "group_calls_unsupported", "Only one-to-one calls are supported")
    existing = await db.scalar(
        select(CallSession).where(
            CallSession.caller_id == actor.id, CallSession.client_call_id == client_call_id
        )
    )
    if existing:
        if existing.conversation_id != conversation_id:
            raise AppError(409, "client_call_id_conflict", "Call ID was already used")
        return existing, False
    active = await db.scalar(
        select(CallSession).where(
            CallSession.conversation_id == conversation_id,
            CallSession.status.in_([CallStatus.RINGING.value, CallStatus.ACTIVE.value]),
        )
    )
    if active:
        raise AppError(409, "call_in_progress", "A call is already in progress")
    user_ids = list(
        await db.scalars(
            select(ConversationMember.user_id).where(
                ConversationMember.conversation_id == conversation_id,
                ConversationMember.role != MemberRole.BANNED.value,
            )
        )
    )
    if len(user_ids) != 2 or actor.id not in user_ids:
        raise AppError(409, "call_unavailable", "The direct conversation cannot be called")
    call = CallSession(
        conversation_id=conversation_id,
        caller_id=actor.id,
        client_call_id=client_call_id,
        kind=kind,
        status=CallStatus.RINGING.value,
    )
    db.add(call)
    await db.flush()
    for user_id in user_ids:
        db.add(
            CallParticipant(
                call_id=call.id,
                user_id=user_id,
                status=(
                    CallParticipantStatus.ACCEPTED.value
                    if user_id == actor.id
                    else CallParticipantStatus.INVITED.value
                ),
                responded_at=utcnow() if user_id == actor.id else None,
            )
        )
    await db.commit()
    await db.refresh(call)
    return call, True


async def require_participant(
    db: AsyncSession, actor: User, call_id: UUID
) -> tuple[CallSession, CallParticipant]:
    call = await db.get(CallSession, call_id)
    participant = await db.get(CallParticipant, (call_id, actor.id)) if call else None
    if not call or not participant:
        raise AppError(404, "call_not_found", "Call was not found")
    return call, participant


async def accept_call(db: AsyncSession, actor: User, call_id: UUID) -> CallSession:
    call, participant = await require_participant(db, actor, call_id)
    if participant.status == CallParticipantStatus.ACCEPTED.value:
        return call
    if (
        call.status != CallStatus.RINGING.value
        or participant.status != CallParticipantStatus.INVITED.value
    ):
        raise AppError(409, "call_not_ringing", "Call is no longer ringing")
    participant.status = CallParticipantStatus.ACCEPTED.value
    participant.responded_at = utcnow()
    call.status = CallStatus.ACTIVE.value
    call.started_at = call.started_at or utcnow()
    await db.commit()
    await db.refresh(call)
    return call


async def decline_call(db: AsyncSession, actor: User, call_id: UUID) -> CallSession:
    call, participant = await require_participant(db, actor, call_id)
    if participant.status == CallParticipantStatus.DECLINED.value:
        return call
    if (
        call.status != CallStatus.RINGING.value
        or participant.status != CallParticipantStatus.INVITED.value
    ):
        raise AppError(409, "call_not_ringing", "Call is no longer ringing")
    participant.status = CallParticipantStatus.DECLINED.value
    participant.responded_at = utcnow()
    call.status = CallStatus.DECLINED.value
    call.ended_at = utcnow()
    call.ended_by = actor.id
    await db.commit()
    await db.refresh(call)
    return call


async def end_call(db: AsyncSession, actor: User, call_id: UUID) -> CallSession:
    call, participant = await require_participant(db, actor, call_id)
    if call.status in {CallStatus.ENDED.value, CallStatus.DECLINED.value}:
        return call
    if participant.status not in {
        CallParticipantStatus.ACCEPTED.value,
        CallParticipantStatus.INVITED.value,
    }:
        raise AppError(409, "call_not_active", "Call is not active")
    call.status = CallStatus.ENDED.value
    call.ended_at = utcnow()
    call.ended_by = actor.id
    participants = list(
        await db.scalars(select(CallParticipant).where(CallParticipant.call_id == call.id))
    )
    for item in participants:
        if item.status != CallParticipantStatus.DECLINED.value:
            item.status = CallParticipantStatus.ENDED.value
            item.responded_at = item.responded_at or utcnow()
    await db.commit()
    await db.refresh(call)
    return call


async def participant_ids(db: AsyncSession, call_id: UUID) -> list[UUID]:
    return list(
        await db.scalars(select(CallParticipant.user_id).where(CallParticipant.call_id == call_id))
    )

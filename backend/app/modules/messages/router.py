from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Response
from sqlalchemy import delete, select

from app.core.config import Settings, get_settings
from app.core.deps import ActiveUser, Db
from app.core.enums import ConversationType
from app.core.errors import AppError
from app.core.policy import require_conversation
from app.core.security import encrypt_text, utcnow
from app.db.models import Message, MessagePin, MessageReaction, Poll, PollVote
from app.modules.messages import service
from app.modules.messages.schemas import (
    MessageCreate,
    MessageEdit,
    MessageOut,
    PollVoteUpdate,
    ReactionCreate,
    ReadUpdate,
)
from app.modules.realtime.events import broadcast_conversation

router = APIRouter(tags=["messages"])


@router.get("/conversations/{conversation_id}/messages", response_model=list[MessageOut])
async def list_messages(
    conversation_id: UUID,
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
    before_seq: int | None = None,
    after_seq: int | None = None,
    limit: int = 50,
):
    await require_conversation(db, user, conversation_id, "read")
    limit = min(max(limit, 1), 100)
    query = select(Message).where(Message.conversation_id == conversation_id)
    if before_seq is not None:
        query = query.where(Message.seq < before_seq)
    if after_seq is not None:
        query = query.where(Message.seq > after_seq)
    query = query.order_by(Message.seq.desc() if before_seq is not None else Message.seq).limit(
        limit
    )
    messages = list(await db.scalars(query))
    if before_seq is not None:
        messages.reverse()
    return [await service.serialize_message(db, message, settings) for message in messages]


@router.post(
    "/conversations/{conversation_id}/messages", response_model=MessageOut, status_code=201
)
async def send_message(
    conversation_id: UUID,
    payload: MessageCreate,
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    message, created = await service.send_message(db, user, conversation_id, payload, settings)
    output = await service.serialize_message(db, message, settings)
    if created:
        await broadcast_conversation(db, conversation_id, "msg.new", output.model_dump(mode="json"))
    return output


@router.get("/messages/{message_id}", response_model=MessageOut)
async def get_message(
    message_id: UUID, db: Db, user: ActiveUser, settings: Annotated[Settings, Depends(get_settings)]
):
    message = await db.get(Message, message_id)
    if not message or message.deleted_at:
        raise AppError(404, "message_not_found", "Original message is unavailable")
    await require_conversation(db, user, message.conversation_id, "read")
    return await service.serialize_message(db, message, settings)


@router.patch("/messages/{message_id}", response_model=MessageOut)
async def edit_message(
    message_id: UUID,
    payload: MessageEdit,
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    message = await db.get(Message, message_id)
    if not message:
        raise AppError(404, "message_not_found", "Message was not found")
    await require_conversation(db, user, message.conversation_id, "send")
    if message.sender_id != user.id or message.deleted_at:
        raise AppError(403, "forbidden", "Only the sender can edit this message")
    message.body_enc = encrypt_text(payload.body, settings)
    message.entities = payload.entities
    message.edited_at = utcnow()
    await db.commit()
    output = await service.serialize_message(db, message, settings)
    await broadcast_conversation(
        db, message.conversation_id, "msg.edited", output.model_dump(mode="json")
    )
    return output


@router.delete("/messages/{message_id}", status_code=204)
async def delete_message(message_id: UUID, db: Db, user: ActiveUser) -> Response:
    message = await db.get(Message, message_id)
    if not message:
        raise AppError(404, "message_not_found", "Message was not found")
    await require_conversation(db, user, message.conversation_id, "read")
    if message.sender_id != user.id:
        raise AppError(403, "forbidden", "Only the sender can delete this message")
    if not message.deleted_at:
        message.deleted_at = utcnow()
        message.body_enc = None
        await db.commit()
        await broadcast_conversation(
            db,
            message.conversation_id,
            "msg.deleted",
            {"id": str(message.id), "conv": str(message.conversation_id), "seq": message.seq},
        )
    return Response(status_code=204)


@router.put("/messages/{message_id}/reactions", response_model=MessageOut)
async def react(
    message_id: UUID,
    payload: ReactionCreate,
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    message = await db.get(Message, message_id)
    if not message:
        raise AppError(404, "message_not_found", "Message was not found")
    await require_conversation(db, user, message.conversation_id, "read")
    reaction = await db.get(MessageReaction, (message.id, user.id, payload.emoji))
    if not reaction:
        db.add(
            MessageReaction(
                message_id=message.id,
                user_id=user.id,
                emoji=payload.emoji,
                created_at=utcnow(),
            )
        )
        await db.commit()
    output = await service.serialize_message(db, message, settings)
    if not reaction:
        await broadcast_conversation(
            db, message.conversation_id, "msg.reactions", output.model_dump(mode="json")
        )
    return output


@router.delete("/messages/{message_id}/reactions/{emoji}", response_model=MessageOut)
async def remove_reaction(
    message_id: UUID,
    emoji: str,
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    message = await db.get(Message, message_id)
    if not message:
        raise AppError(404, "message_not_found", "Message was not found")
    await require_conversation(db, user, message.conversation_id, "read")
    reaction = await db.get(MessageReaction, (message.id, user.id, emoji))
    if reaction:
        await db.delete(reaction)
        await db.commit()
    output = await service.serialize_message(db, message, settings)
    if reaction:
        await broadcast_conversation(
            db, message.conversation_id, "msg.reactions", output.model_dump(mode="json")
        )
    return output


async def require_pin_access(db: Db, user, message: Message):
    conversation, _ = await require_conversation(db, user, message.conversation_id, "read")
    if conversation.type != ConversationType.DM.value:
        await require_conversation(db, user, message.conversation_id, "manage")
    return conversation


@router.put("/messages/{message_id}/pin", status_code=204)
async def pin_message(message_id: UUID, db: Db, user: ActiveUser) -> Response:
    message = await db.get(Message, message_id)
    if not message or message.deleted_at:
        raise AppError(404, "message_not_found", "Message was not found")
    await require_pin_access(db, user, message)
    if not await db.get(MessagePin, (message.conversation_id, message.id)):
        db.add(
            MessagePin(
                conversation_id=message.conversation_id,
                message_id=message.id,
                pinned_by=user.id,
                pinned_at=utcnow(),
            )
        )
        await db.commit()
        await broadcast_conversation(
            db,
            message.conversation_id,
            "msg.pinned",
            {"id": str(message.id), "conv": str(message.conversation_id)},
        )
    return Response(status_code=204)


@router.delete("/messages/{message_id}/pin", status_code=204)
async def unpin_message(message_id: UUID, db: Db, user: ActiveUser) -> Response:
    message = await db.get(Message, message_id)
    if not message:
        raise AppError(404, "message_not_found", "Message was not found")
    await require_pin_access(db, user, message)
    pin = await db.get(MessagePin, (message.conversation_id, message.id))
    if pin:
        await db.delete(pin)
        await db.commit()
        await broadcast_conversation(
            db,
            message.conversation_id,
            "msg.unpinned",
            {"id": str(message.id), "conv": str(message.conversation_id)},
        )
    return Response(status_code=204)


@router.get("/conversations/{conversation_id}/pinned", response_model=list[MessageOut])
async def pinned_messages(
    conversation_id: UUID,
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    await require_conversation(db, user, conversation_id, "read")
    messages = list(
        await db.scalars(
            select(Message)
            .join(MessagePin, MessagePin.message_id == Message.id)
            .where(MessagePin.conversation_id == conversation_id, Message.deleted_at.is_(None))
            .order_by(MessagePin.pinned_at.desc())
        )
    )
    return [await service.serialize_message(db, message, settings) for message in messages]


@router.put("/messages/{message_id}/poll-vote", response_model=MessageOut)
async def vote_poll(
    message_id: UUID,
    payload: PollVoteUpdate,
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    message = await db.get(Message, message_id)
    poll = await db.get(Poll, message_id)
    if not message or not poll or message.deleted_at:
        raise AppError(404, "poll_not_found", "Poll was not found")
    await require_conversation(db, user, message.conversation_id, "read")
    indexes = set(payload.option_indexes)
    if any(index < 0 or index >= len(poll.options) for index in indexes):
        raise AppError(422, "invalid_poll_option", "A poll option is invalid")
    if not poll.multiple_choice and len(indexes) != 1:
        raise AppError(422, "single_choice_poll", "This poll accepts one option")
    if poll.closed_at:
        raise AppError(409, "poll_closed", "This poll is closed")
    existing = set(
        await db.scalars(
            select(PollVote.option_index).where(
                PollVote.message_id == message.id, PollVote.user_id == user.id
            )
        )
    )
    if existing != indexes:
        await db.execute(
            delete(PollVote).where(PollVote.message_id == message.id, PollVote.user_id == user.id)
        )
        for index in indexes:
            db.add(
                PollVote(
                    message_id=message.id,
                    user_id=user.id,
                    option_index=index,
                    created_at=utcnow(),
                )
            )
        await db.commit()
    output = await service.serialize_message(db, message, settings)
    if existing != indexes:
        await broadcast_conversation(
            db, message.conversation_id, "poll.updated", output.model_dump(mode="json")
        )
    return output


@router.put("/conversations/{conversation_id}/read", status_code=204)
async def mark_read(
    conversation_id: UUID, payload: ReadUpdate, db: Db, user: ActiveUser
) -> Response:
    conversation, member = await require_conversation(db, user, conversation_id, "read")
    if payload.seq > conversation.last_seq:
        raise AppError(422, "invalid_seq", "Read sequence exceeds the conversation sequence")
    if member and payload.seq > member.last_read_seq:
        member.last_read_seq = payload.seq
        await db.commit()
    return Response(status_code=204)

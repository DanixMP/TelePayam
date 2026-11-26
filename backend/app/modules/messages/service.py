from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.errors import AppError
from app.core.policy import require_conversation
from app.core.security import decrypt_text, encrypt_text, utcnow
from app.db.models import (
    Conversation,
    Media,
    Message,
    MessageAttachment,
    MessageReaction,
    Poll,
    PollVote,
    User,
)
from app.modules.media.access import is_library_media
from app.modules.messages.schemas import MessageCreate, MessageOut, PollCreate, PollOut


async def serialize_message(db: AsyncSession, message: Message, settings: Settings) -> MessageOut:
    attachments = list(
        await db.scalars(
            select(MessageAttachment.media_id)
            .where(MessageAttachment.message_id == message.id)
            .order_by(MessageAttachment.position)
        )
    )
    reactions = (
        (
            await db.execute(
                select(MessageReaction.emoji).where(MessageReaction.message_id == message.id)
            )
        )
        .scalars()
        .all()
    )
    reaction_counts: dict[str, int] = {}
    for emoji in reactions:
        reaction_counts[emoji] = reaction_counts.get(emoji, 0) + 1
    body = None
    if message.body_enc and not message.deleted_at:
        body = decrypt_text(message.body_enc, settings)
    poll_out = None
    poll = await db.get(Poll, message.id)
    if poll:
        votes = list(
            await db.scalars(select(PollVote.option_index).where(PollVote.message_id == message.id))
        )
        counts = [0] * len(poll.options)
        for option_index in votes:
            if 0 <= option_index < len(counts):
                counts[option_index] += 1
        poll_out = PollOut(
            question=poll.question,
            options=poll.options,
            multiple_choice=poll.multiple_choice,
            closed_at=poll.closed_at,
            vote_counts=counts,
        )
    return MessageOut(
        id=message.id,
        conversation_id=message.conversation_id,
        seq=message.seq,
        sender_id=message.sender_id,
        client_msg_id=message.client_msg_id,
        type=message.type,
        body=body,
        entities=message.entities,
        reply_to_id=message.reply_to_id,
        forward_from=message.forward_from,
        silent=message.silent,
        attachment_ids=[] if message.deleted_at else attachments,
        reactions=reaction_counts,
        poll=None if message.deleted_at else poll_out,
        edited_at=message.edited_at,
        deleted_at=message.deleted_at,
        created_at=message.created_at,
    )


async def send_message(
    db: AsyncSession,
    actor: User,
    conversation_id: UUID,
    payload: MessageCreate,
    settings: Settings,
) -> tuple[Message, bool]:
    await require_conversation(db, actor, conversation_id, "send")
    existing_query = select(Message).where(
        Message.sender_id == actor.id, Message.client_msg_id == payload.client_msg_id
    )
    existing = await db.scalar(existing_query)
    if existing:
        if existing.conversation_id != conversation_id:
            raise AppError(409, "client_message_id_conflict", "Message ID was already used")
        return existing, False
    if payload.forward_from is not None:
        try:
            source_id = UUID(str(payload.forward_from.get("message_id")))
        except ValueError as exc:
            raise AppError(422, "invalid_forward", "Choose a message to forward") from exc
        source = await db.get(Message, source_id)
        if not source or source.deleted_at:
            raise AppError(404, "message_not_found", "Original message is unavailable")
        await require_conversation(db, actor, source.conversation_id, "read")
        original = await serialize_message(db, source, settings)
        author = await db.get(User, source.sender_id)
        # Only the server supplies the forwarded content, media and attribution.
        payload = payload.model_copy(
            update={
                "type": original.type,
                "body": original.body,
                "entities": original.entities,
                "attachment_ids": original.attachment_ids,
                "poll": PollCreate(**original.poll.model_dump()) if original.poll else None,
                "forward_from": {
                    "message_id": str(source.id),
                    "sender_id": str(source.sender_id),
                    "name": " ".join(filter(None, (author.first_name, author.last_name)))
                    or author.handle,
                },
            }
        )
    if not payload.body and not payload.attachment_ids and not payload.poll:
        raise AppError(422, "empty_message", "A message body or attachment is required")
    if payload.reply_to_id:
        reply = await db.get(Message, payload.reply_to_id)
        if not reply or reply.deleted_at or reply.conversation_id != conversation_id:
            raise AppError(422, "invalid_reply", "Reply target is not in this conversation")
    if payload.attachment_ids and payload.forward_from is None:
        media = list(await db.scalars(select(Media).where(Media.id.in_(payload.attachment_ids))))
        if len(media) != len(payload.attachment_ids):
            raise AppError(422, "invalid_attachment", "One or more attachments are unavailable")
        for item in media:
            if item.status != "ready" or (
                item.owner_id != actor.id
                and not await is_library_media(db, actor, item, payload.type)
            ):
                raise AppError(422, "invalid_attachment", "One or more attachments are unavailable")
    seq = await db.scalar(
        update(Conversation)
        .where(Conversation.id == conversation_id)
        .values(last_seq=Conversation.last_seq + 1, updated_at=utcnow())
        .returning(Conversation.last_seq)
    )
    message = Message(
        conversation_id=conversation_id,
        seq=seq,
        sender_id=actor.id,
        client_msg_id=payload.client_msg_id,
        type=payload.type,
        body_enc=encrypt_text(payload.body, settings) if payload.body else None,
        entities=payload.entities,
        reply_to_id=payload.reply_to_id,
        forward_from=payload.forward_from,
        silent=payload.silent,
        scheduled_for=payload.scheduled_for,
        created_at=utcnow(),
    )
    db.add(message)
    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        duplicate = await db.scalar(existing_query)
        if not duplicate or duplicate.conversation_id != conversation_id:
            raise
        return duplicate, False
    for position, media_id in enumerate(payload.attachment_ids):
        db.add(MessageAttachment(message_id=message.id, media_id=media_id, position=position))
    if payload.poll:
        db.add(
            Poll(
                message_id=message.id,
                question=payload.poll.question,
                options=payload.poll.options,
                multiple_choice=payload.poll.multiple_choice,
            )
        )
    await db.commit()
    await db.refresh(message)
    return message, True

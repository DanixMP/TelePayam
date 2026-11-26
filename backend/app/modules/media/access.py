from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import AccountStatus, MemberRole
from app.core.errors import AppError
from app.core.policy import require_conversation
from app.db.models import (
    ConversationMember,
    Media,
    Message,
    MessageAttachment,
    SavedGif,
    ServiceRequest,
    ServiceRequestDocument,
    ServiceRequestMessage,
    Sticker,
    User,
)
from app.modules.stickers.builtin import FEATURED_GIFS


async def is_library_media(db: AsyncSession, user: User, media: Media, kind: str) -> bool:
    if kind == "sticker":
        return bool(
            await db.scalar(select(Sticker.id).where(Sticker.media_id == media.id).limit(1))
        )
    if kind == "animation":
        return media.id in FEATURED_GIFS or bool(await db.get(SavedGif, (user.id, media.id)))
    return False


async def can_download(db: AsyncSession, user: User, media: Media) -> bool:
    if media.owner_id == user.id:
        return True
    if await is_library_media(db, user, media, "sticker") or await is_library_media(
        db, user, media, "animation"
    ):
        return True
    if media.kind == "image" and await db.scalar(
        select(User.id).where(
            User.id == media.owner_id,
            User.avatar_id == media.id,
            User.status == AccountStatus.ACTIVE,
        )
    ):
        return True
    # A forward can reference the same file in several chats. Check this viewer's memberships.
    chats = await db.scalars(
        select(Message.conversation_id)
        .distinct()
        .join(MessageAttachment, MessageAttachment.message_id == Message.id)
        .join(ConversationMember, ConversationMember.conversation_id == Message.conversation_id)
        .where(
            MessageAttachment.media_id == media.id,
            Message.deleted_at.is_(None),
            ConversationMember.user_id == user.id,
            ConversationMember.role != MemberRole.BANNED,
        )
    )
    for chat in chats:
        try:
            await require_conversation(db, user, chat, "read")
            return True
        except AppError:
            continue
    allowed = or_(ServiceRequest.student_id == user.id, ServiceRequest.assigned_staff_id == user.id)
    for model, column in [
        (ServiceRequestDocument, ServiceRequestDocument.media_id),
        (ServiceRequestMessage, ServiceRequestMessage.attachment_id),
    ]:
        if await db.scalar(
            select(ServiceRequest.id)
            .join(model, model.request_id == ServiceRequest.id)
            .where(column == media.id, allowed)
            .limit(1)
        ):
            return True
    return False

from typing import Any
from uuid import UUID

from sqlalchemy import and_, not_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import AccountStatus, ConversationType, MemberRole, UserRole
from app.core.store import get_store
from app.db.models import Conversation, ConversationMember, User
from app.modules.realtime.manager import manager


async def conversation_recipients(db: AsyncSession, conversation_id: UUID) -> list[UUID]:
    return list(
        await db.scalars(
            select(ConversationMember.user_id)
            .join(User, User.id == ConversationMember.user_id)
            .join(Conversation, Conversation.id == ConversationMember.conversation_id)
            .where(
                ConversationMember.conversation_id == conversation_id,
                ConversationMember.role != MemberRole.BANNED.value,
                User.status == AccountStatus.ACTIVE,
                User.role.in_([UserRole.STUDENT, UserRole.PROFESSOR]),
                not_(
                    and_(
                        User.role == UserRole.PROFESSOR,
                        Conversation.type == ConversationType.GROUP,
                        Conversation.audience == "students",
                    )
                ),
            )
        )
    )


async def broadcast_conversation(
    db: AsyncSession, conversation_id: UUID, event_type: str, data: dict[str, Any]
) -> None:
    recipients = await conversation_recipients(db, conversation_id)
    await manager.fanout(recipients, {"type": event_type, "data": data}, get_store())


async def broadcast_users(user_ids: list[UUID], event_type: str, data: dict[str, Any]) -> None:
    await manager.fanout(user_ids, {"type": event_type, "data": data}, get_store())

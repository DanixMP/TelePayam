from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import ConversationType, MemberRole, UserRole, Visibility
from app.core.errors import AppError
from app.db.models import Conversation, ConversationMember, ReportAccessGrant, User


async def membership(
    db: AsyncSession, user_id: UUID, conversation_id: UUID
) -> ConversationMember | None:
    return await db.scalar(
        select(ConversationMember).where(
            ConversationMember.user_id == user_id,
            ConversationMember.conversation_id == conversation_id,
        )
    )


def is_hidden_student_group(user: User, conversation: Conversation) -> bool:
    return (
        user.role == UserRole.PROFESSOR.value
        and conversation.type == ConversationType.GROUP.value
        and conversation.audience == "students"
    )


async def active_report_grant(
    db: AsyncSession, user_id: UUID, conversation_id: UUID
) -> ReportAccessGrant | None:
    now = datetime.now(UTC)
    return await db.scalar(
        select(ReportAccessGrant).where(
            ReportAccessGrant.granted_to == user_id,
            ReportAccessGrant.conversation_id == conversation_id,
            ReportAccessGrant.revoked_at.is_(None),
            ReportAccessGrant.expires_at > now,
        )
    )


async def require_conversation(
    db: AsyncSession,
    user: User,
    conversation_id: UUID,
    action: str = "read",
    seq: int | None = None,
) -> tuple[Conversation, ConversationMember | None]:
    conversation = await db.get(Conversation, conversation_id)
    if not conversation or is_hidden_student_group(user, conversation):
        raise AppError(404, "conversation_not_found", "Conversation was not found")

    member = await membership(db, user.id, conversation_id)
    if user.role == UserRole.MODERATOR.value and action == "moderate":
        grant = await active_report_grant(db, user.id, conversation_id)
        if grant and (seq is None or grant.min_seq <= seq <= grant.max_seq):
            return conversation, None
        raise AppError(403, "report_grant_required", "An active scoped report grant is required")

    # Administrative roles never receive implicit access to personal conversations.
    if user.role in {UserRole.ADMIN, UserRole.SUPER_ADMIN, UserRole.MODERATOR, UserRole.STAFF}:
        raise AppError(404, "conversation_not_found", "Conversation was not found")

    if action == "view_metadata" and conversation.visibility == Visibility.PUBLIC.value:
        return conversation, member
    if not member or member.role == MemberRole.BANNED.value:
        raise AppError(404, "conversation_not_found", "Conversation was not found")
    if action == "send" and conversation.type == ConversationType.CHANNEL.value:
        if member.role not in {MemberRole.OWNER.value, MemberRole.ADMIN.value}:
            raise AppError(403, "channel_read_only", "Only channel administrators may post")
    if action == "manage" and member.role not in {
        MemberRole.OWNER.value,
        MemberRole.ADMIN.value,
    }:
        raise AppError(403, "forbidden", "Conversation administrator access is required")
    return conversation, member


def require_group_creation(user: User) -> None:
    if user.role != UserRole.STUDENT.value:
        raise AppError(403, "forbidden", "Only students can create groups")


def require_join_allowed(user: User, conversation: Conversation) -> None:
    if is_hidden_student_group(user, conversation):
        raise AppError(404, "conversation_not_found", "Conversation was not found")
    if user.role != UserRole.STUDENT.value and conversation.type == ConversationType.GROUP.value:
        raise AppError(403, "forbidden", "This account cannot join student groups")

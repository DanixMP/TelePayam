import hashlib
import secrets
from datetime import timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.enums import AccountStatus, ConversationType, MemberRole, UserRole, Visibility
from app.core.errors import AppError
from app.core.handles import handle_policy
from app.core.policy import require_group_creation, require_join_allowed
from app.core.security import utcnow
from app.db.models import Conversation, ConversationMember, DmPair, InviteLink, User


def invite_hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


async def ensure_global_handle_available(
    db: AsyncSession, handle: str, conversation_id: UUID | None = None
) -> str:
    handle = handle.lower().removeprefix("@")
    if not handle_policy.validate(handle):
        raise AppError(422, "invalid_handle", "Handle does not satisfy the current policy")
    user_match = await db.scalar(select(User.id).where(User.handle == handle))
    conversation_match = await db.scalar(
        select(Conversation.id).where(
            Conversation.handle == handle,
            Conversation.id != conversation_id if conversation_id else True,
        )
    )
    if user_match or conversation_match:
        raise AppError(409, "handle_taken", "Handle is already in use")
    return handle


async def create_dm(db: AsyncSession, actor: User, target_id: UUID) -> Conversation:
    chat_roles = {UserRole.STUDENT, UserRole.PROFESSOR}
    if actor.role not in chat_roles:
        raise AppError(403, "forbidden", "This account cannot start personal chats")
    if actor.id == target_id:
        # Saved messages uses a one-member DM and a stable pair of the same ID.
        target = actor
    else:
        target = await db.get(User, target_id)
    if not target or target.role not in chat_roles or target.status != AccountStatus.ACTIVE:
        raise AppError(404, "user_not_found", "User was not found")
    low, high = sorted((actor.id, target.id), key=str)
    pair_query = (
        select(Conversation)
        .join(DmPair, DmPair.conversation_id == Conversation.id)
        .where(DmPair.low_user_id == low, DmPair.high_user_id == high)
    )
    existing = await db.scalar(pair_query)
    if existing:
        return existing
    conversation = Conversation(
        type=ConversationType.DM.value,
        visibility=Visibility.PRIVATE.value,
        owner_id=actor.id,
        member_count=1 if actor.id == target.id else 2,
        created_by_role=actor.role,
        audience="participants",
        settings={},
    )
    db.add(conversation)
    await db.flush()
    db.add(DmPair(conversation_id=conversation.id, low_user_id=low, high_user_id=high))
    members = {actor.id, target.id}
    for user_id in members:
        db.add(
            ConversationMember(
                conversation_id=conversation.id,
                user_id=user_id,
                role=MemberRole.MEMBER.value,
                joined_at=utcnow(),
            )
        )
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        existing = await db.scalar(pair_query)
        if existing is None:
            raise
        await db.refresh(actor)
        return existing
    await db.refresh(conversation)
    return conversation


async def create_group(
    db: AsyncSession,
    actor: User,
    title: str,
    description: str | None,
    visibility: str,
    handle: str | None,
    member_ids: list[UUID],
) -> Conversation:
    require_group_creation(actor)
    if visibility == Visibility.PUBLIC.value and not handle:
        raise AppError(422, "handle_required", "Public groups require a handle")
    normalized_handle = await ensure_global_handle_available(db, handle) if handle else None
    unique_member_ids = set(member_ids) - {actor.id}
    if unique_member_ids:
        users = list(await db.scalars(select(User).where(User.id.in_(unique_member_ids))))
        if len(users) != len(unique_member_ids):
            raise AppError(404, "user_not_found", "One or more users were not found")
        if any(user.role != UserRole.STUDENT.value for user in users):
            raise AppError(403, "invalid_group_member", "Student groups can contain students only")
    conversation = Conversation(
        type=ConversationType.GROUP.value,
        visibility=visibility,
        handle=normalized_handle,
        title=title.strip(),
        description=description,
        owner_id=actor.id,
        member_count=1 + len(unique_member_ids),
        created_by_role=UserRole.STUDENT.value,
        audience="students",
        settings={},
    )
    db.add(conversation)
    await db.flush()
    db.add(
        ConversationMember(
            conversation_id=conversation.id,
            user_id=actor.id,
            role=MemberRole.OWNER.value,
            joined_at=utcnow(),
        )
    )
    for user_id in unique_member_ids:
        db.add(
            ConversationMember(
                conversation_id=conversation.id,
                user_id=user_id,
                role=MemberRole.MEMBER.value,
                joined_at=utcnow(),
            )
        )
    await db.commit()
    await db.refresh(conversation)
    return conversation


async def create_channel(
    db: AsyncSession,
    actor: User,
    title: str,
    description: str | None,
    visibility: str,
    handle: str | None,
) -> Conversation:
    if actor.role not in {UserRole.STUDENT.value, UserRole.PROFESSOR.value}:
        raise AppError(403, "forbidden", "This role cannot create channels")
    if visibility == Visibility.PUBLIC.value and not handle:
        raise AppError(422, "handle_required", "Public channels require a handle")
    normalized_handle = await ensure_global_handle_available(db, handle) if handle else None
    conversation = Conversation(
        type=ConversationType.CHANNEL.value,
        visibility=visibility,
        handle=normalized_handle,
        title=title.strip(),
        description=description,
        owner_id=actor.id,
        member_count=1,
        is_professor_channel=actor.role == UserRole.PROFESSOR.value,
        created_by_role=actor.role,
        audience="all",
        settings={},
    )
    db.add(conversation)
    await db.flush()
    db.add(
        ConversationMember(
            conversation_id=conversation.id,
            user_id=actor.id,
            role=MemberRole.OWNER.value,
            joined_at=utcnow(),
        )
    )
    await db.commit()
    await db.refresh(conversation)
    return conversation


async def join_conversation(db: AsyncSession, actor: User, conversation: Conversation) -> bool:
    require_join_allowed(actor, conversation)
    if actor.role not in {UserRole.STUDENT.value, UserRole.PROFESSOR.value}:
        raise AppError(403, "forbidden", "This role cannot join conversations")
    existing = await db.get(ConversationMember, (conversation.id, actor.id))
    if existing and existing.role != MemberRole.BANNED.value:
        return False
    if existing:
        raise AppError(403, "member_banned", "This account cannot rejoin")
    role = (
        MemberRole.SUBSCRIBER.value
        if conversation.type == ConversationType.CHANNEL.value
        else MemberRole.MEMBER.value
    )
    db.add(
        ConversationMember(
            conversation_id=conversation.id,
            user_id=actor.id,
            role=role,
            joined_at=utcnow(),
        )
    )
    conversation.member_count += 1
    await db.commit()
    return True


async def create_invite(
    db: AsyncSession,
    conversation: Conversation,
    expires_in_hours: int | None,
    max_uses: int | None,
) -> tuple[str, InviteLink]:
    token = secrets.token_urlsafe(24)
    invite = InviteLink(
        conversation_id=conversation.id,
        token_hash=invite_hash(token),
        expires_at=utcnow() + timedelta(hours=expires_in_hours) if expires_in_hours else None,
        max_uses=max_uses,
    )
    db.add(invite)
    await db.commit()
    return token, invite

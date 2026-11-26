from datetime import UTC
from uuid import UUID

from fastapi import APIRouter, Response
from sqlalchemy import and_, case, not_, select

from app.core.config import get_settings
from app.core.deps import ActiveUser, Db
from app.core.enums import ConversationType, MemberRole, ReportStatus, UserRole, Visibility
from app.core.errors import AppError
from app.core.policy import require_conversation
from app.core.security import decrypt_text, utcnow
from app.db.models import (
    Conversation,
    ConversationMember,
    DmPair,
    InviteLink,
    Message,
    Report,
    ReportAccessGrant,
    User,
)
from app.modules.common import UserPublic
from app.modules.conversations import service
from app.modules.conversations.schemas import (
    AddMember,
    ChannelCreate,
    ConversationMemberOut,
    ConversationOut,
    ConversationSettingsUpdate,
    ConversationUpdate,
    DmCreate,
    GroupCreate,
    InviteCreate,
    InviteOut,
    InviteSummary,
    MemberUpdate,
    ReviewState,
)

router = APIRouter(prefix="/conversations", tags=["conversations"])


async def active_review(db: Db, conversation_id: UUID) -> Report | None:
    now = utcnow()
    return await db.scalar(
        select(Report)
        .join(ReportAccessGrant, ReportAccessGrant.report_id == Report.id)
        .where(
            Report.conversation_id == conversation_id,
            Report.status == ReportStatus.ASSIGNED.value,
            ReportAccessGrant.revoked_at.is_(None),
            ReportAccessGrant.expires_at > now,
        )
        .order_by(Report.created_at)
        .limit(1)
    )


async def conversation_out(
    db: Db, conversation: Conversation, member: ConversationMember | None = None
) -> ConversationOut:
    if member and member.role == MemberRole.BANNED:
        member = None  # Public discovery must not expose a former member's message preview.
    details = {
        "my_role": member.role if member else None,
        "last_read_seq": member.last_read_seq if member else 0,
        "under_review": bool(await active_review(db, conversation.id)) if member else False,
    }
    if member and conversation.type == ConversationType.DM:
        peer = await db.scalar(
            select(User)
            .join(
                DmPair,
                User.id
                == case(
                    (DmPair.low_user_id == member.user_id, DmPair.high_user_id),
                    else_=DmPair.low_user_id,
                ),
            )
            .where(DmPair.conversation_id == conversation.id)
        )
        if peer:
            details.update(
                title=(
                    "Saved messages"
                    if peer.id == member.user_id
                    else " ".join(filter(None, (peer.first_name, peer.last_name))) or peer.handle
                ),
                handle=peer.handle,
                avatar_id=peer.avatar_id,
            )
    if member and conversation.last_seq:
        viewer = await db.get(User, member.user_id)
        if viewer and viewer.role in {UserRole.STUDENT, UserRole.PROFESSOR}:
            last = await db.scalar(
                select(Message).where(
                    Message.conversation_id == conversation.id, Message.seq == conversation.last_seq
                )
            )
            if last:
                details.update(
                    last_message_at=last.created_at,
                    last_message_body=(
                        "Message deleted"
                        if last.deleted_at
                        else decrypt_text(last.body_enc, get_settings())[:160]
                        if last.body_enc
                        else last.type.title()
                    ),
                )
    return ConversationOut.model_validate(conversation).model_copy(update=details)


@router.get("", response_model=list[ConversationOut])
async def list_conversations(db: Db, user: ActiveUser, limit: int = 50):
    if user.role not in {UserRole.STUDENT, UserRole.PROFESSOR}:
        return []
    limit = min(max(limit, 1), 100)
    rows = (
        await db.execute(
            select(Conversation, ConversationMember)
            .join(
                ConversationMember,
                ConversationMember.conversation_id == Conversation.id,
            )
            .where(
                ConversationMember.user_id == user.id,
                ConversationMember.role != MemberRole.BANNED.value,
                not_(
                    and_(
                        Conversation.type == ConversationType.GROUP.value,
                        Conversation.audience == "students",
                    )
                )
                if user.role == UserRole.PROFESSOR.value
                else True,
            )
            .order_by(Conversation.updated_at.desc())
            .limit(limit)
        )
    ).all()
    return [await conversation_out(db, conversation, member) for conversation, member in rows]


@router.get("/discover", response_model=list[ConversationOut])
async def discover_public(
    db: Db,
    user: ActiveUser,
    professor_channels: bool = False,
    query: str | None = None,
    limit: int = 50,
):
    if user.role not in {UserRole.STUDENT.value, UserRole.PROFESSOR.value}:
        return []
    statement = select(Conversation).where(
        Conversation.visibility == Visibility.PUBLIC.value,
        Conversation.archived_at.is_(None),
    )
    if professor_channels:
        statement = statement.where(Conversation.is_professor_channel.is_(True))
    if user.role == UserRole.PROFESSOR.value:
        statement = statement.where(Conversation.type == ConversationType.CHANNEL.value)
    if query:
        term = f"%{query.strip().lower()}%"
        statement = statement.where(
            (Conversation.title.ilike(term)) | (Conversation.handle.ilike(term))
        )
    conversations = list(
        await db.scalars(statement.order_by(Conversation.created_at.desc()).limit(min(limit, 100)))
    )
    members = (
        {
            item.conversation_id: item
            for item in await db.scalars(
                select(ConversationMember).where(
                    ConversationMember.user_id == user.id,
                    ConversationMember.conversation_id.in_([item.id for item in conversations]),
                )
            )
        }
        if conversations
        else {}
    )
    return [await conversation_out(db, item, members.get(item.id)) for item in conversations]


@router.post("/dm", response_model=ConversationOut, status_code=201)
async def create_dm(payload: DmCreate, db: Db, user: ActiveUser):
    conversation = await service.create_dm(db, user, payload.user_id)
    member = await db.get(ConversationMember, (conversation.id, user.id))
    return await conversation_out(db, conversation, member)


@router.post("/groups", response_model=ConversationOut, status_code=201)
async def create_group(payload: GroupCreate, db: Db, user: ActiveUser):
    conversation = await service.create_group(
        db,
        user,
        payload.title,
        payload.description,
        payload.visibility,
        payload.handle,
        payload.member_ids,
    )
    member = await db.get(ConversationMember, (conversation.id, user.id))
    return await conversation_out(db, conversation, member)


@router.post("/channels", response_model=ConversationOut, status_code=201)
async def create_channel(payload: ChannelCreate, db: Db, user: ActiveUser):
    conversation = await service.create_channel(
        db,
        user,
        payload.title,
        payload.description,
        payload.visibility,
        payload.handle,
    )
    member = await db.get(ConversationMember, (conversation.id, user.id))
    return await conversation_out(db, conversation, member)


@router.get("/{conversation_id}", response_model=ConversationOut)
async def get_conversation(conversation_id: UUID, db: Db, user: ActiveUser):
    conversation, member = await require_conversation(db, user, conversation_id, "view_metadata")
    return await conversation_out(db, conversation, member)


@router.post("/{conversation_id}/join", response_model=ConversationOut)
async def join_public(conversation_id: UUID, db: Db, user: ActiveUser):
    conversation = await db.get(Conversation, conversation_id)
    if not conversation or conversation.visibility != Visibility.PUBLIC.value:
        raise AppError(404, "conversation_not_found", "Public conversation was not found")
    await service.join_conversation(db, user, conversation)
    member = await db.get(ConversationMember, (conversation.id, user.id))
    return await conversation_out(db, conversation, member)


@router.post("/{conversation_id}/invites", response_model=InviteOut, status_code=201)
async def create_invite(conversation_id: UUID, payload: InviteCreate, db: Db, user: ActiveUser):
    conversation, _ = await require_conversation(db, user, conversation_id, "manage")
    token, invite = await service.create_invite(
        db, conversation, payload.expires_in_hours, payload.max_uses
    )
    return InviteOut(
        id=invite.id, token=token, expires_at=invite.expires_at, max_uses=invite.max_uses
    )


@router.get("/{conversation_id}/invites", response_model=list[InviteSummary])
async def list_invites(conversation_id: UUID, db: Db, user: ActiveUser):
    await require_conversation(db, user, conversation_id, "manage")
    return list(
        await db.scalars(
            select(InviteLink)
            .where(InviteLink.conversation_id == conversation_id)
            .order_by(InviteLink.created_at.desc())
        )
    )


@router.delete("/{conversation_id}/invites/{invite_id}", status_code=204)
async def revoke_invite(
    conversation_id: UUID, invite_id: UUID, db: Db, user: ActiveUser
) -> Response:
    await require_conversation(db, user, conversation_id, "manage")
    invite = await db.get(InviteLink, invite_id)
    if not invite or invite.conversation_id != conversation_id:
        raise AppError(404, "invite_not_found", "Invite was not found")
    if invite.revoked_at is None:
        invite.revoked_at = utcnow()
        await db.commit()
    return Response(status_code=204)


@router.post("/join/{token}", response_model=ConversationOut)
async def join_invite(token: str, db: Db, user: ActiveUser):
    invite = await db.scalar(
        select(InviteLink).where(InviteLink.token_hash == service.invite_hash(token))
    )
    now = utcnow()
    if (
        not invite
        or invite.revoked_at
        or (
            invite.expires_at
            and invite.expires_at.replace(tzinfo=invite.expires_at.tzinfo or UTC) <= now
        )
        or (invite.max_uses is not None and invite.uses >= invite.max_uses)
    ):
        raise AppError(404, "invite_not_found", "Invite is invalid or expired")
    conversation = await db.get(Conversation, invite.conversation_id)
    if not conversation:
        raise AppError(404, "invite_not_found", "Invite is invalid or expired")
    joined = await service.join_conversation(db, user, conversation)
    if joined:
        invite.uses += 1
        await db.commit()
    member = await db.get(ConversationMember, (conversation.id, user.id))
    return await conversation_out(db, conversation, member)


@router.post("/{conversation_id}/members", status_code=204)
async def add_member(conversation_id: UUID, payload: AddMember, db: Db, user: ActiveUser):
    conversation, actor_member = await require_conversation(db, user, conversation_id, "manage")
    if payload.role == MemberRole.ADMIN.value and actor_member.role != MemberRole.OWNER.value:
        raise AppError(403, "forbidden", "Only the owner can appoint administrators")
    target = await db.get(User, payload.user_id)
    if not target:
        raise AppError(404, "user_not_found", "User was not found")
    from app.core.policy import require_join_allowed

    require_join_allowed(target, conversation)
    if await db.get(ConversationMember, (conversation.id, target.id)):
        raise AppError(409, "already_member", "User is already a member")
    db.add(
        ConversationMember(
            conversation_id=conversation.id,
            user_id=target.id,
            role=(
                payload.role
                if payload.role == MemberRole.ADMIN.value
                or conversation.type == ConversationType.GROUP.value
                else MemberRole.SUBSCRIBER.value
            ),
            joined_at=utcnow(),
        )
    )
    conversation.member_count += 1
    await db.commit()


@router.get("/{conversation_id}/members", response_model=list[ConversationMemberOut])
async def list_members(conversation_id: UUID, db: Db, user: ActiveUser):
    await require_conversation(db, user, conversation_id, "read")
    rows = (
        await db.execute(
            select(ConversationMember, User)
            .join(User, User.id == ConversationMember.user_id)
            .where(
                ConversationMember.conversation_id == conversation_id,
                ConversationMember.role != MemberRole.BANNED.value,
            )
            .order_by(ConversationMember.joined_at)
        )
    ).all()
    return [
        ConversationMemberOut(
            user=UserPublic.model_validate(member_user),
            role=member.role,
            admin_rights=member.admin_rights,
            joined_at=member.joined_at,
        )
        for member, member_user in rows
    ]


@router.patch("/{conversation_id}", response_model=ConversationOut)
async def update_conversation(
    conversation_id: UUID, payload: ConversationUpdate, db: Db, user: ActiveUser
):
    conversation, member = await require_conversation(db, user, conversation_id, "manage")
    if conversation.type == ConversationType.DM.value:
        raise AppError(422, "conversation_not_editable", "Direct messages cannot be edited")
    changes = payload.model_dump(exclude_unset=True)
    new_visibility = changes.get("visibility", conversation.visibility)
    new_handle = changes.get("handle", conversation.handle)
    if new_visibility == Visibility.PUBLIC.value and not new_handle:
        raise AppError(422, "handle_required", "Public conversations require a handle")
    if "handle" in changes and changes["handle"]:
        changes["handle"] = await service.ensure_global_handle_available(
            db, changes["handle"], conversation.id
        )
    for key, value in changes.items():
        setattr(conversation, key, value)
    await db.commit()
    await db.refresh(conversation)
    return await conversation_out(db, conversation, member)


@router.patch("/{conversation_id}/settings", response_model=ConversationOut)
async def update_settings(
    conversation_id: UUID,
    payload: ConversationSettingsUpdate,
    db: Db,
    user: ActiveUser,
):
    conversation, member = await require_conversation(db, user, conversation_id, "manage")
    conversation.settings = {
        **(conversation.settings or {}),
        **payload.model_dump(exclude_unset=True),
    }
    await db.commit()
    await db.refresh(conversation)
    return await conversation_out(db, conversation, member)


@router.get("/{conversation_id}/review-state", response_model=ReviewState)
async def review_state(conversation_id: UUID, db: Db, user: ActiveUser):
    await require_conversation(db, user, conversation_id, "read")
    report = await active_review(db, conversation_id)
    return ReviewState(under_review=bool(report), started_at=report.updated_at if report else None)


@router.post("/{conversation_id}/leave", status_code=204)
async def leave_conversation(conversation_id: UUID, db: Db, user: ActiveUser) -> Response:
    conversation, member = await require_conversation(db, user, conversation_id, "read")
    if conversation.type == ConversationType.DM.value:
        raise AppError(422, "cannot_leave_dm", "Direct messages cannot be left")
    if member.role == MemberRole.OWNER.value:
        raise AppError(409, "owner_cannot_leave", "Transfer ownership or delete the conversation")
    await db.delete(member)
    conversation.member_count = max(0, conversation.member_count - 1)
    await db.commit()
    return Response(status_code=204)


@router.delete("/{conversation_id}", status_code=204)
async def delete_conversation(conversation_id: UUID, db: Db, user: ActiveUser) -> Response:
    conversation, member = await require_conversation(db, user, conversation_id, "manage")
    if member.role != MemberRole.OWNER.value or conversation.type == ConversationType.DM.value:
        raise AppError(403, "forbidden", "Only the owner can delete this conversation")
    await db.delete(conversation)
    await db.commit()
    return Response(status_code=204)


async def editable_member(db: Db, conversation_id: UUID, actor: User, target_id: UUID):
    conversation, actor_member = await require_conversation(db, actor, conversation_id, "manage")
    target = await db.get(ConversationMember, (conversation_id, target_id))
    if not target:
        raise AppError(404, "member_not_found", "Member was not found")
    if target.role == MemberRole.OWNER.value or target.user_id == actor.id:
        raise AppError(403, "forbidden", "This member cannot be changed")
    if actor_member.role != MemberRole.OWNER.value and target.role == MemberRole.ADMIN.value:
        raise AppError(403, "forbidden", "Only the owner can change administrators")
    return conversation, actor_member, target


@router.patch("/{conversation_id}/members/{member_id}", status_code=204)
async def update_member(
    conversation_id: UUID,
    member_id: UUID,
    payload: MemberUpdate,
    db: Db,
    user: ActiveUser,
) -> Response:
    conversation, actor_member, target = await editable_member(db, conversation_id, user, member_id)
    if payload.role == MemberRole.ADMIN.value and actor_member.role != MemberRole.OWNER.value:
        raise AppError(403, "forbidden", "Only the owner can appoint administrators")
    if (
        conversation.type == ConversationType.CHANNEL.value
        and payload.role == MemberRole.MEMBER.value
    ):
        raise AppError(422, "invalid_member_role", "Channel participants are subscribers")
    if (
        conversation.type == ConversationType.GROUP.value
        and payload.role == MemberRole.SUBSCRIBER.value
    ):
        raise AppError(422, "invalid_member_role", "Group participants are members")
    was_banned = target.role == MemberRole.BANNED.value
    target.role = payload.role
    if payload.role == MemberRole.BANNED.value and not was_banned:
        conversation.member_count = max(0, conversation.member_count - 1)
    elif payload.role != MemberRole.BANNED.value and was_banned:
        conversation.member_count += 1
    await db.commit()
    return Response(status_code=204)


@router.delete("/{conversation_id}/members/{member_id}", status_code=204)
async def remove_member(
    conversation_id: UUID, member_id: UUID, db: Db, user: ActiveUser
) -> Response:
    conversation, _, target = await editable_member(db, conversation_id, user, member_id)
    was_active = target.role != MemberRole.BANNED.value
    await db.delete(target)
    if was_active:
        conversation.member_count = max(0, conversation.member_count - 1)
    await db.commit()
    return Response(status_code=204)

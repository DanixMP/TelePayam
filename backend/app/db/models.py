from datetime import datetime
from uuid import UUID

from sqlalchemy import (
    JSON,
    BigInteger,
    Boolean,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import (
    AccountStatus,
    MemberRole,
    ReportStatus,
    ServiceRequestStatus,
    UserRole,
    Visibility,
)
from app.db.base import Base, TimestampMixin, UUIDPrimaryKeyMixin


class User(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "users"

    phone: Mapped[str] = mapped_column(String(16), unique=True, index=True)
    role: Mapped[str] = mapped_column(String(20), default=UserRole.STUDENT.value, index=True)
    status: Mapped[str] = mapped_column(
        String(24), default=AccountStatus.PENDING_PROFILE.value, index=True
    )
    first_name: Mapped[str | None] = mapped_column(String(80))
    last_name: Mapped[str | None] = mapped_column(String(80))
    handle: Mapped[str | None] = mapped_column(String(32), unique=True, index=True)
    avatar_id: Mapped[UUID | None] = mapped_column(Uuid)
    bio: Mapped[str | None] = mapped_column(String(500))
    correction_note: Mapped[str | None] = mapped_column(String(500))
    totp_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    totp_secret_enc: Mapped[str | None] = mapped_column(Text)

    student_profile: Mapped["StudentProfile | None"] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
        uselist=False,
        foreign_keys="StudentProfile.user_id",
    )
    professor_profile: Mapped["ProfessorProfile | None"] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
        uselist=False,
        foreign_keys="ProfessorProfile.user_id",
    )


class StudentProfile(Base, TimestampMixin):
    __tablename__ = "student_profiles"

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    national_id_enc: Mapped[str] = mapped_column(Text)
    national_id_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    national_id_last4: Mapped[str] = mapped_column(String(4))
    degree: Mapped[str] = mapped_column(String(20))
    department: Mapped[str] = mapped_column(String(120))
    university_id: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    reviewed_by: Mapped[UUID | None] = mapped_column(ForeignKey("users.id"))
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    reject_reason: Mapped[str | None] = mapped_column(String(500))

    user: Mapped[User] = relationship(back_populates="student_profile", foreign_keys=[user_id])


class ProfessorProfile(Base, TimestampMixin):
    __tablename__ = "professor_profiles"

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    department: Mapped[str] = mapped_column(String(120))
    title: Mapped[str] = mapped_column(String(50), default="Professor")
    channel_id: Mapped[UUID | None] = mapped_column(ForeignKey("conversations.id"))

    user: Mapped[User] = relationship(back_populates="professor_profile", foreign_keys=[user_id])


class StaffProfile(Base, TimestampMixin):
    __tablename__ = "staff_profiles"

    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    department: Mapped[str] = mapped_column(String(120), index=True)
    permissions: Mapped[dict] = mapped_column(JSON, default=dict)


class ProfessorInvite(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "professor_invites"

    phone: Mapped[str] = mapped_column(String(16), index=True)
    first_name: Mapped[str] = mapped_column(String(80))
    last_name: Mapped[str] = mapped_column(String(80))
    department: Mapped[str] = mapped_column(String(120))
    title: Mapped[str] = mapped_column(String(50), default="Professor")
    created_by: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Device(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "devices"
    __table_args__ = (UniqueConstraint("user_id", "fcm_token"),)

    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    platform: Mapped[str] = mapped_column(String(30))
    fcm_token: Mapped[str | None] = mapped_column(String(500))
    name: Mapped[str | None] = mapped_column(String(100))
    last_seen: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class RefreshToken(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "refresh_tokens"

    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    family_id: Mapped[UUID] = mapped_column(Uuid, index=True)
    token_hash: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    replaced_by_id: Mapped[UUID | None] = mapped_column(ForeignKey("refresh_tokens.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class Conversation(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "conversations"

    type: Mapped[str] = mapped_column(String(20), index=True)
    visibility: Mapped[str] = mapped_column(String(20), default=Visibility.PRIVATE.value)
    handle: Mapped[str | None] = mapped_column(String(32), unique=True, index=True)
    title: Mapped[str | None] = mapped_column(String(180))
    description: Mapped[str | None] = mapped_column(String(1000))
    avatar_id: Mapped[UUID | None] = mapped_column(Uuid)
    owner_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)
    member_count: Mapped[int] = mapped_column(Integer, default=0)
    last_seq: Mapped[int] = mapped_column(BigInteger, default=0)
    is_professor_channel: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    created_by_role: Mapped[str] = mapped_column(String(20))
    audience: Mapped[str] = mapped_column(String(30), default="all", index=True)
    settings: Mapped[dict] = mapped_column(JSON, default=dict)
    archived_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    members: Mapped[list["ConversationMember"]] = relationship(
        back_populates="conversation", cascade="all, delete-orphan"
    )


class DmPair(Base):
    __tablename__ = "dm_pairs"
    __table_args__ = (UniqueConstraint("low_user_id", "high_user_id"),)

    conversation_id: Mapped[UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"), primary_key=True
    )
    low_user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)
    high_user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)


class ConversationMember(Base, TimestampMixin):
    __tablename__ = "conversation_members"

    conversation_id: Mapped[UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"), primary_key=True
    )
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True, index=True
    )
    role: Mapped[str] = mapped_column(String(20), default=MemberRole.MEMBER.value)
    admin_rights: Mapped[dict] = mapped_column(JSON, default=dict)
    last_read_seq: Mapped[int] = mapped_column(BigInteger, default=0)
    muted_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    joined_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))

    conversation: Mapped[Conversation] = relationship(back_populates="members")


class InviteLink(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "invite_links"

    conversation_id: Mapped[UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"), index=True
    )
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    uses: Mapped[int] = mapped_column(Integer, default=0)
    max_uses: Mapped[int | None] = mapped_column(Integer)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Message(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "messages"
    __table_args__ = (
        UniqueConstraint("sender_id", "client_msg_id"),
        UniqueConstraint("conversation_id", "seq"),
        Index("ix_messages_conversation_seq_desc", "conversation_id", "seq"),
    )

    conversation_id: Mapped[UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"), index=True
    )
    seq: Mapped[int] = mapped_column(BigInteger)
    sender_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)
    client_msg_id: Mapped[str] = mapped_column(String(64))
    type: Mapped[str] = mapped_column(String(30), default="text")
    body_enc: Mapped[str | None] = mapped_column(Text)
    entities: Mapped[list] = mapped_column(JSON, default=list)
    reply_to_id: Mapped[UUID | None] = mapped_column(ForeignKey("messages.id"))
    forward_from: Mapped[dict | None] = mapped_column(JSON)
    silent: Mapped[bool] = mapped_column(Boolean, default=False)
    scheduled_for: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    edited_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)


class MessageReaction(Base):
    __tablename__ = "message_reactions"

    message_id: Mapped[UUID] = mapped_column(
        ForeignKey("messages.id", ondelete="CASCADE"), primary_key=True
    )
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    emoji: Mapped[str] = mapped_column(String(32), primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class Media(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "media"

    owner_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)
    kind: Mapped[str] = mapped_column(String(30))
    mime: Mapped[str] = mapped_column(String(120))
    size: Mapped[int] = mapped_column(BigInteger)
    path: Mapped[str] = mapped_column(String(500))
    original_name: Mapped[str | None] = mapped_column(String(255))
    width: Mapped[int | None] = mapped_column(Integer)
    height: Mapped[int | None] = mapped_column(Integer)
    duration: Mapped[float | None]
    thumb_path: Mapped[str | None] = mapped_column(String(500))
    blurhash: Mapped[str | None] = mapped_column(String(100))
    sha256: Mapped[str] = mapped_column(String(64), index=True)
    status: Mapped[str] = mapped_column(String(20), default="ready")


class MessageAttachment(Base):
    __tablename__ = "message_attachments"

    message_id: Mapped[UUID] = mapped_column(
        ForeignKey("messages.id", ondelete="CASCADE"), primary_key=True
    )
    media_id: Mapped[UUID] = mapped_column(ForeignKey("media.id"), primary_key=True)
    position: Mapped[int] = mapped_column(Integer, default=0)


class MessagePin(Base):
    __tablename__ = "message_pins"

    conversation_id: Mapped[UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"), primary_key=True
    )
    message_id: Mapped[UUID] = mapped_column(
        ForeignKey("messages.id", ondelete="CASCADE"), primary_key=True
    )
    pinned_by: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    pinned_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)


class Poll(Base):
    __tablename__ = "polls"

    message_id: Mapped[UUID] = mapped_column(
        ForeignKey("messages.id", ondelete="CASCADE"), primary_key=True
    )
    question: Mapped[str] = mapped_column(String(300))
    options: Mapped[list] = mapped_column(JSON)
    multiple_choice: Mapped[bool] = mapped_column(Boolean, default=False)
    closed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class PollVote(Base):
    __tablename__ = "poll_votes"

    message_id: Mapped[UUID] = mapped_column(
        ForeignKey("polls.message_id", ondelete="CASCADE"), primary_key=True
    )
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    option_index: Mapped[int] = mapped_column(Integer, primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class Report(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "reports"

    reporter_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)
    target_type: Mapped[str] = mapped_column(String(30))
    target_id: Mapped[UUID] = mapped_column(Uuid)
    conversation_id: Mapped[UUID | None] = mapped_column(ForeignKey("conversations.id"))
    message_id: Mapped[UUID | None] = mapped_column(ForeignKey("messages.id"))
    reason: Mapped[str] = mapped_column(String(80))
    note: Mapped[str | None] = mapped_column(String(1000))
    status: Mapped[str] = mapped_column(String(20), default=ReportStatus.OPEN.value, index=True)
    assigned_to: Mapped[UUID | None] = mapped_column(ForeignKey("users.id"), index=True)
    evidence_enc: Mapped[str] = mapped_column(Text)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    resolved_by: Mapped[UUID | None] = mapped_column(ForeignKey("users.id"))
    resolution: Mapped[str | None] = mapped_column(String(500))


class ReportAccessGrant(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "report_access_grants"

    report_id: Mapped[UUID] = mapped_column(
        ForeignKey("reports.id", ondelete="CASCADE"), index=True
    )
    conversation_id: Mapped[UUID] = mapped_column(ForeignKey("conversations.id"), index=True)
    granted_to: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)
    min_seq: Mapped[int] = mapped_column(BigInteger)
    max_seq: Mapped[int] = mapped_column(BigInteger)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class AuditLog(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "audit_log"

    actor_id: Mapped[UUID | None] = mapped_column(ForeignKey("users.id"), index=True)
    action: Mapped[str] = mapped_column(String(100), index=True)
    target: Mapped[str] = mapped_column(String(200))
    context: Mapped[dict] = mapped_column(JSON, default=dict)
    ip: Mapped[str | None] = mapped_column(String(64))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)


class ServiceType(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "service_types"

    name: Mapped[str] = mapped_column(String(150), unique=True)
    description: Mapped[str | None] = mapped_column(String(1000))
    required_fields: Mapped[dict] = mapped_column(JSON, default=dict)
    required_documents: Mapped[list] = mapped_column(JSON, default=list)
    assignee_dept: Mapped[str] = mapped_column(String(120), index=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    sla_hours: Mapped[int | None] = mapped_column(Integer)


class ServiceRequest(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "service_requests"

    student_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)
    service_type_id: Mapped[UUID] = mapped_column(ForeignKey("service_types.id"), index=True)
    status: Mapped[str] = mapped_column(
        String(30), default=ServiceRequestStatus.DRAFT.value, index=True
    )
    assigned_staff_id: Mapped[UUID | None] = mapped_column(ForeignKey("users.id"), index=True)
    data: Mapped[dict] = mapped_column(JSON, default=dict)
    verification_code: Mapped[str | None] = mapped_column(String(40), unique=True, index=True)


class ServiceRequestEvent(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "service_request_events"

    request_id: Mapped[UUID] = mapped_column(
        ForeignKey("service_requests.id", ondelete="CASCADE"), index=True
    )
    actor_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    kind: Mapped[str] = mapped_column(String(50))
    note: Mapped[str | None] = mapped_column(String(1000))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class ServiceRequestMessage(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "service_request_messages"

    request_id: Mapped[UUID] = mapped_column(
        ForeignKey("service_requests.id", ondelete="CASCADE"), index=True
    )
    sender_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    body_enc: Mapped[str] = mapped_column(Text)
    attachment_id: Mapped[UUID | None] = mapped_column(ForeignKey("media.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class ServiceRequestDocument(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "service_request_documents"

    request_id: Mapped[UUID] = mapped_column(
        ForeignKey("service_requests.id", ondelete="CASCADE"), index=True
    )
    media_id: Mapped[UUID] = mapped_column(ForeignKey("media.id"))
    kind: Mapped[str] = mapped_column(String(80))
    uploaded_by: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class StickerPack(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "sticker_packs"

    handle: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    title: Mapped[str] = mapped_column(String(120))
    kind: Mapped[str] = mapped_column(String(20))
    owner_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    is_official: Mapped[bool] = mapped_column(Boolean, default=False)


class Sticker(Base, UUIDPrimaryKeyMixin):
    __tablename__ = "stickers"

    pack_id: Mapped[UUID] = mapped_column(ForeignKey("sticker_packs.id", ondelete="CASCADE"))
    media_id: Mapped[UUID] = mapped_column(ForeignKey("media.id"))
    emoji: Mapped[str] = mapped_column(String(32))
    position: Mapped[int] = mapped_column(Integer)


class UserStickerPack(Base):
    __tablename__ = "user_sticker_packs"

    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), primary_key=True)
    pack_id: Mapped[UUID] = mapped_column(ForeignKey("sticker_packs.id"), primary_key=True)
    position: Mapped[int] = mapped_column(Integer)


class SavedGif(Base):
    __tablename__ = "saved_gifs"

    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), primary_key=True)
    media_id: Mapped[UUID] = mapped_column(ForeignKey("media.id"), primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class FavoriteSticker(Base):
    __tablename__ = "favorite_stickers"

    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), primary_key=True)
    sticker_id: Mapped[UUID] = mapped_column(ForeignKey("stickers.id"), primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class RecentSticker(Base):
    __tablename__ = "recent_stickers"

    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), primary_key=True)
    sticker_id: Mapped[UUID] = mapped_column(ForeignKey("stickers.id"), primary_key=True)
    used_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class CallSession(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    __tablename__ = "call_sessions"
    __table_args__ = (UniqueConstraint("caller_id", "client_call_id"),)

    conversation_id: Mapped[UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"), index=True
    )
    caller_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True)
    client_call_id: Mapped[str] = mapped_column(String(64))
    kind: Mapped[str] = mapped_column(String(10), default="audio")
    status: Mapped[str] = mapped_column(String(20), index=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    ended_by: Mapped[UUID | None] = mapped_column(ForeignKey("users.id"))


class CallParticipant(Base):
    __tablename__ = "call_participants"

    call_id: Mapped[UUID] = mapped_column(
        ForeignKey("call_sessions.id", ondelete="CASCADE"), primary_key=True
    )
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True, index=True
    )
    status: Mapped[str] = mapped_column(String(20))
    responded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

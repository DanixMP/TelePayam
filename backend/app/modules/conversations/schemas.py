from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field

from app.modules.common import ORMModel, UserPublic


class ConversationOut(ORMModel):
    id: UUID
    type: str
    visibility: str
    handle: str | None
    title: str | None
    description: str | None
    owner_id: UUID
    member_count: int
    last_seq: int
    is_professor_channel: bool
    settings: dict
    created_at: datetime
    updated_at: datetime
    avatar_id: UUID | None = None
    last_message_body: str | None = None
    last_message_at: datetime | None = None
    my_role: str | None = None
    last_read_seq: int = 0
    under_review: bool = False


class DmCreate(BaseModel):
    user_id: UUID


class GroupCreate(BaseModel):
    title: str = Field(min_length=1, max_length=180)
    description: str | None = Field(default=None, max_length=1000)
    visibility: Literal["public", "private"] = "private"
    handle: str | None = None
    member_ids: list[UUID] = Field(default_factory=list, max_length=200)


class ChannelCreate(BaseModel):
    title: str = Field(min_length=1, max_length=180)
    description: str | None = Field(default=None, max_length=1000)
    visibility: Literal["public", "private"] = "public"
    handle: str | None = None


class ConversationUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=180)
    description: str | None = Field(default=None, max_length=1000)
    visibility: Literal["public", "private"] | None = None
    handle: str | None = Field(default=None, max_length=32)
    avatar_id: UUID | None = None


class ConversationSettingsUpdate(BaseModel):
    slow_mode_seconds: int | None = Field(default=None, ge=0, le=86400)
    members_can_post: bool | None = None
    members_can_invite: bool | None = None
    comments_enabled: bool | None = None


class InviteCreate(BaseModel):
    expires_in_hours: int | None = Field(default=168, ge=1, le=2160)
    max_uses: int | None = Field(default=None, ge=1, le=10000)


class InviteOut(BaseModel):
    id: UUID
    token: str
    expires_at: datetime | None
    max_uses: int | None


class InviteSummary(ORMModel):
    id: UUID
    expires_at: datetime | None
    uses: int
    max_uses: int | None
    revoked_at: datetime | None
    created_at: datetime


class AddMember(BaseModel):
    user_id: UUID
    role: Literal["admin", "member"] = "member"


class MemberUpdate(BaseModel):
    role: Literal["admin", "member", "subscriber", "banned"]


class ConversationMemberOut(BaseModel):
    user: UserPublic
    role: str
    admin_rights: dict
    joined_at: datetime


class ReviewState(BaseModel):
    under_review: bool
    started_at: datetime | None = None


class ResolveOut(BaseModel):
    kind: Literal["user", "group", "channel"]
    id: UUID
    handle: str
    title: str
    avatar_id: UUID | None = None

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class UserPublic(ORMModel):
    id: UUID
    first_name: str | None
    last_name: str | None
    handle: str | None
    role: str
    avatar_id: UUID | None
    bio: str | None


class UserSelf(UserPublic):
    phone: str
    status: str
    correction_note: str | None
    created_at: datetime


class Page(BaseModel):
    items: list
    next_cursor: str | None = None

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field

from app.modules.common import ORMModel


class ReportCreate(BaseModel):
    target_type: Literal["message", "user", "group", "channel"]
    target_id: UUID
    conversation_id: UUID | None = None
    message_id: UUID | None = None
    reason: str = Field(min_length=2, max_length=80)
    note: str | None = Field(default=None, max_length=1000)


class ReportOut(ORMModel):
    id: UUID
    reporter_id: UUID
    target_type: str
    target_id: UUID
    conversation_id: UUID | None
    message_id: UUID | None
    reason: str
    note: str | None
    status: str
    assigned_to: UUID | None
    resolution: str | None
    created_at: datetime
    resolved_at: datetime | None


class ReportResolution(BaseModel):
    outcome: Literal["dismiss", "warn", "mute", "remove_content", "ban", "escalate"]
    note: str | None = Field(default=None, max_length=500)

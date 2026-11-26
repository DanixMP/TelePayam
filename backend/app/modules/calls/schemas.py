from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field, model_validator

from app.modules.common import ORMModel


class CallCreate(BaseModel):
    conversation_id: UUID
    client_call_id: str = Field(min_length=1, max_length=64)
    kind: Literal["audio", "video"] = "audio"


class CallParticipantOut(ORMModel):
    user_id: UUID
    status: str
    responded_at: datetime | None


class CallOut(ORMModel):
    id: UUID
    conversation_id: UUID
    caller_id: UUID
    client_call_id: str
    kind: str
    status: str
    started_at: datetime | None
    ended_at: datetime | None
    ended_by: UUID | None
    created_at: datetime
    participants: list[CallParticipantOut] = Field(default_factory=list)


class CallTokenRequest(BaseModel):
    call_session_id: UUID | None = None
    conversation_id: UUID | None = None

    @model_validator(mode="after")
    def require_session_or_conversation(self):
        if not self.call_session_id and not self.conversation_id:
            raise ValueError("call_session_id or conversation_id is required")
        return self


class CallTokenOut(BaseModel):
    url: str
    room: str
    token: str

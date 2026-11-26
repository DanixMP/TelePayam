from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field, model_validator


class PollCreate(BaseModel):
    question: str = Field(min_length=1, max_length=300)
    options: list[str] = Field(min_length=2, max_length=10)
    multiple_choice: bool = False

    @model_validator(mode="after")
    def validate_options(self):
        cleaned = [item.strip() for item in self.options]
        if any(not item or len(item) > 100 for item in cleaned):
            raise ValueError("Poll options must contain 1 to 100 characters")
        if len({item.casefold() for item in cleaned}) != len(cleaned):
            raise ValueError("Poll options must be unique")
        self.options = cleaned
        return self


class MessageCreate(BaseModel):
    client_msg_id: str = Field(min_length=1, max_length=64)
    type: str = Field(default="text", max_length=30)
    body: str | None = Field(default=None, max_length=20_000)
    entities: list[dict] = Field(default_factory=list)
    reply_to_id: UUID | None = None
    forward_from: dict | None = None
    attachment_ids: list[UUID] = Field(default_factory=list, max_length=10)
    silent: bool = False
    scheduled_for: datetime | None = None
    poll: PollCreate | None = None

    @model_validator(mode="after")
    def validate_type_payload(self):
        if self.type == "poll" and not self.poll and not self.forward_from:
            raise ValueError("Poll messages require poll data")
        if self.poll and self.type != "poll":
            raise ValueError("Poll data is only valid for poll messages")
        return self


class MessageEdit(BaseModel):
    body: str = Field(max_length=20_000)
    entities: list[dict] = Field(default_factory=list)


class ReactionCreate(BaseModel):
    emoji: str = Field(min_length=1, max_length=32)


class ReadUpdate(BaseModel):
    seq: int = Field(ge=0)


class PollVoteUpdate(BaseModel):
    option_indexes: list[int] = Field(min_length=1, max_length=10)


class PollOut(BaseModel):
    question: str
    options: list[str]
    multiple_choice: bool
    closed_at: datetime | None
    vote_counts: list[int]


class MessageOut(BaseModel):
    id: UUID
    conversation_id: UUID
    seq: int
    sender_id: UUID
    client_msg_id: str
    type: str
    body: str | None
    entities: list
    reply_to_id: UUID | None
    forward_from: dict | None
    silent: bool
    attachment_ids: list[UUID] = Field(default_factory=list)
    reactions: dict[str, int] = Field(default_factory=dict)
    poll: PollOut | None = None
    edited_at: datetime | None
    deleted_at: datetime | None
    created_at: datetime

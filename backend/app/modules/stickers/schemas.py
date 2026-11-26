from uuid import UUID

from pydantic import BaseModel, Field

from app.modules.common import ORMModel


class StickerOut(ORMModel):
    id: UUID
    media_id: UUID
    emoji: str
    position: int


class StickerPackOut(ORMModel):
    id: UUID
    handle: str
    title: str
    kind: str
    is_official: bool
    stickers: list[StickerOut] = []


class ReorderPacks(BaseModel):
    pack_ids: list[UUID]


class CustomSticker(BaseModel):
    media_id: UUID
    emoji: str = Field(default="⭐", min_length=1, max_length=32)

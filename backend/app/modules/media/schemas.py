from datetime import datetime
from uuid import UUID

from app.modules.common import ORMModel


class MediaOut(ORMModel):
    id: UUID
    kind: str
    mime: str
    size: int
    original_name: str | None
    width: int | None
    height: int | None
    duration: float | None
    thumb_path: str | None
    blurhash: str | None
    status: str
    created_at: datetime

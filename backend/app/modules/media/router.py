import hashlib
from pathlib import Path
from typing import Annotated
from uuid import UUID, uuid4

import aiofiles
from fastapi import APIRouter, Depends, File, UploadFile
from fastapi.responses import FileResponse

from app.core.config import Settings, get_settings
from app.core.deps import ActiveUser, Db
from app.core.errors import AppError
from app.db.models import Media
from app.modules.media.access import can_download
from app.modules.media.schemas import MediaOut
from app.modules.stickers.builtin import BUNDLED_FILES

router = APIRouter(prefix="/media", tags=["media"])

ALLOWED_TYPES = {
    "image/jpeg": "image",
    "image/png": "image",
    "image/webp": "image",
    "image/gif": "gif",
    "video/mp4": "video",
    "video/webm": "video",
    "audio/ogg": "voice",
    "audio/mpeg": "audio",
    "audio/mp4": "audio",
    "application/pdf": "document",
    "application/octet-stream": "file",
}


def valid_magic(mime: str, head: bytes) -> bool:
    checks = {
        "image/jpeg": head.startswith(b"\xff\xd8\xff"),
        "image/png": head.startswith(b"\x89PNG\r\n\x1a\n"),
        "image/webp": head.startswith(b"RIFF") and head[8:12] == b"WEBP",
        "image/gif": head.startswith((b"GIF87a", b"GIF89a")),
        "video/mp4": b"ftyp" in head[:32],
        "audio/mp4": b"ftyp" in head[:32],
        "video/webm": head.startswith(b"\x1aE\xdf\xa3"),
        "audio/ogg": head.startswith(b"OggS"),
        "audio/mpeg": head.startswith(b"ID3") or head.startswith(b"\xff"),
        "application/pdf": head.startswith(b"%PDF-"),
        "application/octet-stream": True,
    }
    return checks.get(mime, False)


@router.post("", response_model=MediaOut, status_code=201)
async def upload_media(
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
    file: Annotated[UploadFile, File()],
):
    mime = (file.content_type or "application/octet-stream").lower()
    if mime not in ALLOWED_TYPES:
        raise AppError(415, "unsupported_media_type", "This media type is not allowed")
    media_id = uuid4()
    extension = Path(file.filename or "upload").suffix.lower()[:10]
    relative = Path(str(user.id)) / f"{media_id}{extension}"
    destination = settings.media_root / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    size = 0
    digest = hashlib.sha256()
    head = b""
    try:
        async with aiofiles.open(destination, "wb") as output:
            while chunk := await file.read(1024 * 1024):
                size += len(chunk)
                if size > settings.max_upload_bytes:
                    raise AppError(413, "file_too_large", "Upload exceeds the size limit")
                if len(head) < 64:
                    head += chunk[: 64 - len(head)]
                digest.update(chunk)
                await output.write(chunk)
        if size == 0 or not valid_magic(mime, head):
            raise AppError(415, "invalid_file_content", "File content does not match its type")
    except Exception:
        destination.unlink(missing_ok=True)
        raise
    media = Media(
        id=media_id,
        owner_id=user.id,
        kind=ALLOWED_TYPES[mime],
        mime=mime,
        size=size,
        path=str(relative).replace("\\", "/"),
        original_name=Path(file.filename or "upload").name[:255],
        sha256=digest.hexdigest(),
        status="ready",
    )
    db.add(media)
    await db.commit()
    await db.refresh(media)
    return media


@router.get("/{media_id}")
async def download_media(
    media_id: UUID,
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    media = await db.get(Media, media_id)
    if not media or not await can_download(db, user, media):
        raise AppError(404, "media_not_found", "Media was not found")
    root = settings.media_root.resolve()
    path = BUNDLED_FILES.get(media.id) or (root / media.path).resolve()
    if (media.id not in BUNDLED_FILES and root not in path.parents) or not path.is_file():
        raise AppError(404, "media_not_found", "Media file was not found")
    return FileResponse(path, media_type=media.mime, filename=media.original_name)


@router.get("/{media_id}/metadata", response_model=MediaOut)
async def media_metadata(media_id: UUID, db: Db, user: ActiveUser):
    media = await db.get(Media, media_id)
    if not media or not await can_download(db, user, media):
        raise AppError(404, "media_not_found", "Media was not found")
    return media

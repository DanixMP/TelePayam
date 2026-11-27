from uuid import UUID, uuid5

from fastapi import APIRouter, Response
from sqlalchemy import delete, select

from app.core.deps import ActiveUser, Db
from app.core.errors import AppError
from app.core.security import utcnow
from app.db.models import (
    FavoriteSticker,
    Media,
    RecentSticker,
    SavedGif,
    Sticker,
    StickerPack,
    UserStickerPack,
)
from app.modules.media.access import can_download
from app.modules.stickers.builtin import FEATURED_GIFS, PACK_ID
from app.modules.stickers.schemas import CustomSticker, ReorderPacks, StickerOut, StickerPackOut

router = APIRouter(tags=["stickers"])


async def pack_out(db, pack: StickerPack) -> StickerPackOut:
    stickers = list(
        await db.scalars(
            select(Sticker).where(Sticker.pack_id == pack.id).order_by(Sticker.position)
        )
    )
    title_key = None
    if pack.id == PACK_ID:
        title_key = "campus_notes"
    elif pack.owner_id and pack.id == uuid5(pack.owner_id, "personal-stickers"):
        title_key = "my_stickers"
    return StickerPackOut(
        id=pack.id,
        handle=pack.handle,
        title=pack.title,
        title_key=title_key,
        kind=pack.kind,
        is_official=pack.is_official,
        stickers=[StickerOut.model_validate(item) for item in stickers],
    )


@router.post("/stickers/custom", response_model=StickerOut, status_code=201)
async def add_custom_sticker(payload: CustomSticker, db: Db, user: ActiveUser):
    media = await db.get(Media, payload.media_id)
    if not media or media.owner_id != user.id or media.kind != "image" or media.status != "ready":
        raise AppError(422, "invalid_sticker", "Choose one of your uploaded images")
    pack_id = uuid5(user.id, "personal-stickers")
    sticker_id = uuid5(pack_id, media.id.hex)
    existing = await db.get(Sticker, sticker_id)
    if existing:
        return existing
    if not await db.get(StickerPack, pack_id):
        db.add(
            StickerPack(
                id=pack_id,
                handle=f"s{pack_id.hex[:31]}",
                title="My stickers",
                kind="static",
                owner_id=user.id,
                is_official=False,
            )
        )
        await db.flush()
    if not await db.get(UserStickerPack, (user.id, pack_id)):
        db.add(UserStickerPack(user_id=user.id, pack_id=pack_id, position=0))
    sticker = Sticker(
        id=sticker_id,
        media_id=media.id,
        pack_id=pack_id,
        emoji=payload.emoji,
        position=int(utcnow().timestamp()),
    )
    db.add(sticker)
    await db.commit()
    return sticker


@router.get("/stickers/packs", response_model=list[StickerPackOut])
async def installed_packs(db: Db, user: ActiveUser):
    packs = list(
        await db.scalars(
            select(StickerPack)
            .join(UserStickerPack, UserStickerPack.pack_id == StickerPack.id)
            .where(UserStickerPack.user_id == user.id)
            .order_by(UserStickerPack.position)
        )
    )
    if not any(pack.id == PACK_ID for pack in packs):
        starter = await db.get(StickerPack, PACK_ID)
        if starter:
            packs.insert(0, starter)
    return [await pack_out(db, pack) for pack in packs]


@router.get("/stickers/packs/{handle}", response_model=StickerPackOut)
async def sticker_pack(handle: str, db: Db, _: ActiveUser):
    pack = await db.scalar(select(StickerPack).where(StickerPack.handle == handle.lower()))
    if not pack:
        raise AppError(404, "sticker_pack_not_found", "Sticker pack was not found")
    return await pack_out(db, pack)


@router.put("/stickers/packs/{pack_id}/install", status_code=204)
async def install_pack(pack_id: UUID, db: Db, user: ActiveUser) -> Response:
    if not await db.get(StickerPack, pack_id):
        raise AppError(404, "sticker_pack_not_found", "Sticker pack was not found")
    if not await db.get(UserStickerPack, (user.id, pack_id)):
        count = len(
            list(
                await db.scalars(select(UserStickerPack).where(UserStickerPack.user_id == user.id))
            )
        )
        db.add(UserStickerPack(user_id=user.id, pack_id=pack_id, position=count))
        await db.commit()
    return Response(status_code=204)


@router.delete("/stickers/packs/{pack_id}", status_code=204)
async def remove_pack(pack_id: UUID, db: Db, user: ActiveUser) -> Response:
    await db.execute(
        delete(UserStickerPack).where(
            UserStickerPack.user_id == user.id, UserStickerPack.pack_id == pack_id
        )
    )
    await db.commit()
    return Response(status_code=204)


@router.put("/stickers/packs/reorder", status_code=204)
async def reorder_packs(payload: ReorderPacks, db: Db, user: ActiveUser) -> Response:
    installed = list(
        await db.scalars(select(UserStickerPack).where(UserStickerPack.user_id == user.id))
    )
    if set(payload.pack_ids) != {item.pack_id for item in installed}:
        raise AppError(422, "invalid_pack_order", "Order must contain every installed pack")
    by_id = {item.pack_id: item for item in installed}
    for position, pack_id in enumerate(payload.pack_ids):
        by_id[pack_id].position = position
    await db.commit()
    return Response(status_code=204)


@router.put("/stickers/{sticker_id}/favorite", status_code=204)
async def favorite_sticker(sticker_id: UUID, db: Db, user: ActiveUser) -> Response:
    if not await db.get(Sticker, sticker_id):
        raise AppError(404, "sticker_not_found", "Sticker was not found")
    if not await db.get(FavoriteSticker, (user.id, sticker_id)):
        db.add(FavoriteSticker(user_id=user.id, sticker_id=sticker_id, created_at=utcnow()))
        await db.commit()
    return Response(status_code=204)


@router.get("/stickers/favorites", response_model=list[StickerOut])
async def favorite_stickers(db: Db, user: ActiveUser):
    return list(
        await db.scalars(
            select(Sticker)
            .join(FavoriteSticker, FavoriteSticker.sticker_id == Sticker.id)
            .where(FavoriteSticker.user_id == user.id)
            .order_by(FavoriteSticker.created_at.desc())
        )
    )


@router.put("/stickers/media/{media_id}/favorite", status_code=204)
async def favorite_received_sticker(media_id: UUID, db: Db, user: ActiveUser):
    sticker_id = await db.scalar(select(Sticker.id).where(Sticker.media_id == media_id).limit(1))
    if not sticker_id:
        raise AppError(404, "sticker_not_found", "Sticker was not found")
    return await favorite_sticker(sticker_id, db, user)


@router.delete("/stickers/{sticker_id}/favorite", status_code=204)
async def remove_favorite(sticker_id: UUID, db: Db, user: ActiveUser) -> Response:
    await db.execute(
        delete(FavoriteSticker).where(
            FavoriteSticker.user_id == user.id, FavoriteSticker.sticker_id == sticker_id
        )
    )
    await db.commit()
    return Response(status_code=204)


@router.put("/stickers/{sticker_id}/recent", status_code=204)
async def recent_sticker(sticker_id: UUID, db: Db, user: ActiveUser) -> Response:
    if not await db.get(Sticker, sticker_id):
        raise AppError(404, "sticker_not_found", "Sticker was not found")
    recent = await db.get(RecentSticker, (user.id, sticker_id))
    if recent:
        recent.used_at = utcnow()
    else:
        db.add(RecentSticker(user_id=user.id, sticker_id=sticker_id, used_at=utcnow()))
    await db.commit()
    return Response(status_code=204)


@router.get("/stickers/recents", response_model=list[StickerOut])
async def recent_stickers(db: Db, user: ActiveUser):
    return list(
        await db.scalars(
            select(Sticker)
            .join(RecentSticker, RecentSticker.sticker_id == Sticker.id)
            .where(RecentSticker.user_id == user.id)
            .order_by(RecentSticker.used_at.desc())
            .limit(100)
        )
    )


@router.delete("/stickers/{sticker_id}/recent", status_code=204)
async def remove_recent(sticker_id: UUID, db: Db, user: ActiveUser) -> Response:
    await db.execute(
        delete(RecentSticker).where(
            RecentSticker.user_id == user.id, RecentSticker.sticker_id == sticker_id
        )
    )
    await db.commit()
    return Response(status_code=204)


@router.get("/stickers/suggest", response_model=list[StickerOut])
async def suggest_stickers(emoji: str, db: Db, _: ActiveUser):
    return list(
        await db.scalars(
            select(Sticker).where(Sticker.emoji == emoji).order_by(Sticker.position).limit(50)
        )
    )


@router.put("/gifs/{media_id}", status_code=204)
async def save_gif(media_id: UUID, db: Db, user: ActiveUser) -> Response:
    media = await db.get(Media, media_id)
    if not media or media.kind not in {"gif", "video"} or not await can_download(db, user, media):
        raise AppError(404, "gif_not_found", "GIF media was not found")
    if not await db.get(SavedGif, (user.id, media_id)):
        db.add(SavedGif(user_id=user.id, media_id=media_id, created_at=utcnow()))
        await db.commit()
    return Response(status_code=204)


@router.get("/gifs", response_model=list[UUID])
async def saved_gifs(db: Db, user: ActiveUser):
    return list(
        await db.scalars(
            select(SavedGif.media_id)
            .where(SavedGif.user_id == user.id)
            .order_by(SavedGif.created_at.desc())
        )
    )


@router.get("/gifs/featured", response_model=list[UUID])
async def featured_gifs(db: Db, _: ActiveUser):
    return list(
        await db.scalars(
            select(Media.id).where(Media.id.in_(FEATURED_GIFS)).order_by(Media.original_name)
        )
    )


@router.delete("/gifs/{media_id}", status_code=204)
async def remove_saved_gif(media_id: UUID, db: Db, user: ActiveUser) -> Response:
    await db.execute(
        delete(SavedGif).where(SavedGif.user_id == user.id, SavedGif.media_id == media_id)
    )
    await db.commit()
    return Response(status_code=204)

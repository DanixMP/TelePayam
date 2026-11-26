"""Install the bundled Campus Notes sticker pack and featured GIFs."""

import hashlib

import sqlalchemy as sa
from alembic import op

from app.modules.stickers.builtin import BUNDLED_FILES, PACK_ID, STICKER_ART, asset_id

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade():
    db = op.get_bind()
    metadata = sa.MetaData()
    users, media, packs, stickers = [
        sa.Table(name, metadata, autoload_with=db)
        for name in ("users", "media", "sticker_packs", "stickers")
    ]

    # Reflected SQLite UUID columns are CHAR(32); PostgreSQL uses native UUIDs.
    def key(value):
        return value.hex if db.dialect.name == "sqlite" else value

    owner = db.scalar(sa.select(users.c.id).where(users.c.phone == "+989981080891"))

    def insert(table, **values):
        if not db.scalar(sa.select(table.c.id).where(table.c.id == values["id"])):
            db.execute(table.insert().values(**values))

    insert(
        packs,
        id=key(PACK_ID),
        handle="campus_notes",
        title="Campus Notes",
        kind="static",
        owner_id=owner,
        is_official=True,
    )
    for pos, (identifier, path) in enumerate(BUNDLED_FILES.items()):
        data = path.read_bytes()
        gif = path.suffix == ".gif"
        insert(
            media,
            id=key(identifier),
            owner_id=owner,
            kind="gif" if gif else "image",
            mime="image/gif" if gif else "image/png",
            size=len(data),
            path=f"builtin/{path.name}",
            original_name=path.name,
            status="ready",
            sha256=hashlib.sha256(data).hexdigest(),
        )
        if not gif:
            insert(
                stickers,
                id=key(asset_id(f"sticker:{path.name}")),
                pack_id=key(PACK_ID),
                media_id=key(identifier),
                emoji=STICKER_ART[path.name],
                position=pos,
            )


def downgrade():
    # Messages, favorites and saved GIFs may already reference these rows.
    pass

"""Provision the designated super admin and retire administrator TOTP."""

from uuid import uuid4

import sqlalchemy as sa
from alembic import op

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None

phone = "+989981080891"
users = sa.table(
    "users",
    sa.column("id", sa.Uuid()),
    sa.column("phone", sa.String()),
    sa.column("role", sa.String()),
    sa.column("status", sa.String()),
    sa.column("first_name", sa.String()),
    sa.column("last_name", sa.String()),
    sa.column("totp_enabled", sa.Boolean()),
    sa.column("totp_secret_enc", sa.Text()),
)
tokens = sa.table("refresh_tokens", sa.column("user_id", sa.Uuid()), sa.column("revoked_at"))


def upgrade():
    existing = sa.select(users.c.id).where(users.c.phone == phone)
    # Sessions issued before promotion must not acquire super-admin permissions.
    op.execute(
        tokens.update()
        .where(tokens.c.user_id.in_(existing), tokens.c.revoked_at.is_(None))
        .values(revoked_at=sa.func.now())
    )
    op.execute(
        users.update()
        .where(users.c.role == "admin")
        .values(totp_enabled=False, totp_secret_enc=None)
    )
    op.execute(
        users.update()
        .where(users.c.phone == phone)
        .values(role="super_admin", status="active", totp_enabled=False, totp_secret_enc=None)
    )
    op.execute(
        users.insert().from_select(
            ["id", "phone", "role", "status", "first_name", "last_name", "totp_enabled"],
            sa.select(
                sa.literal(uuid4(), type_=sa.Uuid()),
                sa.literal(phone),
                sa.literal("super_admin"),
                sa.literal("active"),
                sa.literal("University"),
                sa.literal("Admin"),
                sa.false(),
            ).where(~existing.exists()),
        )
    )


def downgrade():
    # Preserve the account and audit history. Old versions need fresh TOTP enrollment.
    op.execute(users.update().where(users.c.role == "super_admin").values(role="admin"))

import os
import sqlite3
import subprocess
import sys
from uuid import uuid4

import pytest

from app.core.enums import SUPER_ADMIN_PHONE


@pytest.mark.parametrize("legacy", [False, True])
def test_migration_provisions_one_super_admin(tmp_path, legacy):
    path = tmp_path / "upgrade.db"
    env = {**os.environ, "DATABASE_URL": f"sqlite+aiosqlite:///{path.as_posix()}"}

    def upgrade(revision):
        subprocess.run([sys.executable, "-m", "alembic", "upgrade", revision], env=env, check=True)

    upgrade("0002")
    old_id = uuid4().hex
    if legacy:
        with sqlite3.connect(path) as db:
            db.executemany(
                "INSERT INTO users(id,phone,role,status,totp_enabled,totp_secret_enc) "
                "VALUES (?,?,?,'active',1,'old')",
                [
                    (old_id, SUPER_ADMIN_PHONE, "admin"),
                    (uuid4().hex, "+989900000001", "admin"),
                    (uuid4().hex, "+989900000002", "moderator"),
                ],
            )
            db.execute(
                "INSERT INTO refresh_tokens(id,user_id,family_id,token_hash,created_at,expires_at) "
                "VALUES (?,?,?,'old-token',CURRENT_TIMESTAMP,'2099-01-01')",
                (uuid4().hex, old_id, uuid4().hex),
            )
    upgrade("head")
    with sqlite3.connect(path) as db:
        rows = db.execute(
            "SELECT phone,status,totp_enabled,totp_secret_enc FROM users WHERE role='super_admin'"
        ).fetchall()
        assert rows == [(SUPER_ADMIN_PHONE, "active", 0, None)]
        if legacy:
            assert db.execute("SELECT id FROM users WHERE role='super_admin'").fetchone() == (
                old_id,
            )
            assert db.execute("SELECT revoked_at FROM refresh_tokens").fetchone()[0] is not None
            assert db.execute(
                "SELECT totp_secret_enc FROM users WHERE role='admin'"
            ).fetchone() == (None,)
            assert db.execute(
                "SELECT totp_secret_enc FROM users WHERE role='moderator'"
            ).fetchone() == ("old",)

import asyncio
from uuid import UUID

import pyotp
from sqlalchemy import select

from app.core.config import get_settings
from app.core.enums import SUPER_ADMIN_PHONE, UserRole
from app.core.security import encrypt_text
from app.core.store import MemoryStore
from app.db.models import AuditLog, StudentProfile, User

API = "/api/v1"


async def login(client, phone, **fields):
    sent = await client.post(f"{API}/auth/otp/request", json={"phone": phone})
    assert sent.status_code == 202
    return await client.post(
        f"{API}/auth/otp/verify",
        json={"phone": phone, "code": sent.json()["development_code"], **fields},
    )


async def test_admin_reviews_student_registration(client, db, monkeypatch):
    monkeypatch.setattr("app.core.store._store", MemoryStore())
    root = User(phone=SUPER_ADMIN_PHONE, role=UserRole.SUPER_ADMIN, status="active")
    db.add(root)
    await db.commit()
    root_login = await login(client, "09981080891")
    assert root_login.json()["user"]["role"] == "super_admin"
    root_auth = {"Authorization": f"Bearer {root_login.json()['access_token']}"}
    create = f"{API}/admin/admins"
    payload = {"phone": "09900000001"}
    created = await client.post(create, headers=root_auth, json=payload)
    assert created.status_code == 201
    assert created.json()["role"] == "admin" and created.json()["phone"] == "+989900000001"
    assert (await client.post(create, headers=root_auth, json=payload)).status_code == 409
    assert (await client.post(create, headers=root_auth, json={"phone": "no"})).status_code == 422
    escalation = await client.post(
        create, headers=root_auth, json={**payload, "role": "super_admin"}
    )
    assert escalation.status_code == 422
    assert (await client.post(create, json=payload)).status_code == 401
    admin = await db.get(User, UUID(created.json()["id"]))
    audit = await db.scalar(select(AuditLog).where(AuditLog.action == "admin.create"))
    assert audit.actor_id == root.id and audit.target == str(admin.id)
    assert not admin.totp_enabled and admin.totp_secret_enc is None
    signed_in = await login(client, "09900000001")
    assert signed_in.status_code == 200
    admin_auth = {"Authorization": f"Bearer {signed_in.json()['access_token']}"}
    assert (await client.post(create, headers=admin_auth, json=payload)).status_code == 403

    student = (await login(client, "09900000002")).json()
    student_auth = {"Authorization": f"Bearer {student['access_token']}"}
    student_id = student["user"]["id"]
    submitted = await client.post(
        f"{API}/users/me/student-profile",
        headers=student_auth,
        json={
            "first_name": "Sara",
            "last_name": "Ahmadi",
            "national_id": "0084575948",
            "degree": "MSc",
            "department": "Engineering",
            "university_id": "40310001",
        },
    )
    assert submitted.json()["status"] == "pending_approval"

    queue = f"{API}/admin/approvals"
    decision = f"{queue}/{student_id}"
    for headers, status in [({}, 401), (student_auth, 403)]:
        assert (await client.get(queue, headers=headers)).status_code == status
        denied = await client.post(decision, headers=headers, json={"action": "approve"})
        assert denied.status_code == status

    pending = await client.get(queue, headers=admin_auth)
    assert (await client.get(queue, headers=root_auth)).json() == pending.json()
    assert [(row["id"], row["national_id_masked"]) for row in pending.json()] == [
        (student_id, "******5948")
    ]
    assert "0084575948" not in pending.text

    # Two open panels can submit the same decision; only one may activate and audit it.
    responses = await asyncio.gather(
        *(client.post(decision, headers=admin_auth, json={"action": "approve"}) for _ in range(2))
    )
    assert sorted(response.status_code for response in responses) == [200, 404]
    assert (await client.get(queue, headers=admin_auth)).json() == []
    assert (await client.get(f"{API}/users/me", headers=student_auth)).json()["status"] == "active"
    assert (await client.get(queue, headers=student_auth)).status_code == 403
    assert (await client.post(create, headers=student_auth, json=payload)).status_code == 403
    profile = await db.get(StudentProfile, UUID(student_id))
    assert profile.reviewed_by == admin.id and profile.reviewed_at is not None
    audits = await db.scalars(select(AuditLog).where(AuditLog.target == student_id))
    assert [(entry.action, entry.actor_id) for entry in audits] == [("student.approve", admin.id)]


async def test_moderator_still_requires_authenticator(client, db, monkeypatch):
    monkeypatch.setattr("app.core.store._store", MemoryStore())
    secret = pyotp.random_base32()
    moderator = User(
        phone="+989900000003",
        role="moderator",
        status="active",
        totp_enabled=True,
        totp_secret_enc=encrypt_text(secret, get_settings()),
    )
    db.add(moderator)
    await db.commit()
    assert (await login(client, moderator.phone)).json()["error"]["code"] == "totp_invalid"
    assert (
        await login(client, moderator.phone, totp_code=pyotp.TOTP(secret).now())
    ).status_code == 200

from sqlalchemy import select

from app.core.config import get_settings
from app.core.enums import AccountStatus, UserRole
from app.core.security import create_access_token
from app.db.models import Message, User


async def active_user(db, phone: str, name: str) -> User:
    user = User(
        phone=phone,
        role=UserRole.STUDENT.value,
        status=AccountStatus.ACTIVE.value,
        first_name=name,
        last_name="Student",
        handle=name.lower() + "_student",
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def test_idempotent_messages_and_conversation_sequences(client, db):
    sender = await active_user(db, "+989555555555", "Sender")
    recipient = await active_user(db, "+989666666666", "Recipient")
    token = create_access_token(sender.id, sender.role, get_settings())
    headers = {"Authorization": f"Bearer {token}"}

    dm_response = await client.post(
        "/api/v1/conversations/dm", headers=headers, json={"user_id": str(recipient.id)}
    )
    assert dm_response.status_code == 201
    conversation_id = dm_response.json()["id"]

    payload = {"client_msg_id": "local-1", "type": "text", "body": "secret text"}
    first = await client.post(
        f"/api/v1/conversations/{conversation_id}/messages", headers=headers, json=payload
    )
    duplicate = await client.post(
        f"/api/v1/conversations/{conversation_id}/messages", headers=headers, json=payload
    )
    second = await client.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=headers,
        json={"client_msg_id": "local-2", "type": "text", "body": "next"},
    )

    assert first.status_code == 201
    assert first.json()["id"] == duplicate.json()["id"]
    assert first.json()["seq"] == 1
    assert second.json()["seq"] == 2

    db.expire_all()
    stored = await db.scalar(select(Message).where(Message.client_msg_id == "local-1"))
    assert "secret text" not in stored.body_enc

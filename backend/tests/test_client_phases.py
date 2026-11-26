from uuid import UUID

import jwt

from app.core.config import get_settings
from app.core.enums import AccountStatus, UserRole
from app.core.security import create_access_token, utcnow
from app.db.models import (
    ConversationMember,
    Media,
    Message,
    ServiceRequest,
    ServiceType,
    StaffProfile,
    Sticker,
    StickerPack,
    User,
)
from app.modules.realtime.manager import manager


async def make_user(db, phone: str, role: str = UserRole.STUDENT.value) -> User:
    user = User(
        phone=phone,
        role=role,
        status=AccountStatus.ACTIVE.value,
        first_name=role.title(),
        last_name="User",
        handle=f"{role}_{phone[-4:]}",
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


def auth(user: User) -> dict[str, str]:
    token = create_access_token(user.id, user.role, get_settings())
    return {"Authorization": f"Bearer {token}"}


async def create_dm(client, sender: User, recipient: User) -> str:
    response = await client.post(
        "/api/v1/conversations/dm",
        headers=auth(sender),
        json={"user_id": str(recipient.id)},
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


async def test_group_channel_management_and_professor_visibility(client, db):
    owner = await make_user(db, "+989100000001")
    member = await make_user(db, "+989100000002")
    professor = await make_user(db, "+989100000003", UserRole.PROFESSOR.value)

    group = await client.post(
        "/api/v1/conversations/groups",
        headers=auth(owner),
        json={
            "title": "Students",
            "visibility": "public",
            "handle": "students_public",
            "member_ids": [str(member.id)],
        },
    )
    assert group.status_code == 201, group.text
    group_id = UUID(group.json()["id"])

    # Even corrupt/legacy membership cannot expose student groups to professors.
    db.add(
        ConversationMember(
            conversation_id=group_id,
            user_id=professor.id,
            role="member",
            joined_at=utcnow(),
        )
    )
    await db.commit()
    professor_list = await client.get("/api/v1/conversations", headers=auth(professor))
    assert str(group_id) not in {item["id"] for item in professor_list.json()}

    updated = await client.patch(
        f"/api/v1/conversations/{group_id}",
        headers=auth(owner),
        json={"description": "Official student group"},
    )
    assert updated.status_code == 200
    assert updated.json()["description"] == "Official student group"

    promoted = await client.patch(
        f"/api/v1/conversations/{group_id}/members/{member.id}",
        headers=auth(owner),
        json={"role": "admin"},
    )
    assert promoted.status_code == 204
    members = await client.get(f"/api/v1/conversations/{group_id}/members", headers=auth(owner))
    assert any(
        item["user"]["id"] == str(member.id) and item["role"] == "admin" for item in members.json()
    )

    invite = await client.post(
        f"/api/v1/conversations/{group_id}/invites", headers=auth(owner), json={}
    )
    assert invite.status_code == 201
    invites = await client.get(f"/api/v1/conversations/{group_id}/invites", headers=auth(owner))
    assert invites.json()[0]["id"] == invite.json()["id"]
    revoked = await client.delete(
        f"/api/v1/conversations/{group_id}/invites/{invite.json()['id']}",
        headers=auth(owner),
    )
    assert revoked.status_code == 204

    channel = await client.post(
        "/api/v1/conversations/channels",
        headers=auth(professor),
        json={
            "title": "Professor Updates",
            "visibility": "public",
            "handle": "professor_updates",
        },
    )
    assert channel.status_code == 201, channel.text
    assert channel.json()["is_professor_channel"] is True
    discovery = await client.get(
        "/api/v1/conversations/discover?professor_channels=true", headers=auth(owner)
    )
    assert channel.json()["id"] in {item["id"] for item in discovery.json()}


async def test_polls_pins_and_reactions_are_idempotent(client, db):
    sender = await make_user(db, "+989200000001")
    recipient = await make_user(db, "+989200000002")
    conversation_id = await create_dm(client, sender, recipient)
    payload = {
        "client_msg_id": "poll-1",
        "type": "poll",
        "poll": {"question": "Choose", "options": ["A", "B"]},
    }
    sent = await client.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=auth(sender),
        json=payload,
    )
    duplicate = await client.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=auth(sender),
        json=payload,
    )
    assert sent.status_code == 201, sent.text
    assert duplicate.json()["id"] == sent.json()["id"]
    message_id = sent.json()["id"]

    vote = await client.put(
        f"/api/v1/messages/{message_id}/poll-vote",
        headers=auth(recipient),
        json={"option_indexes": [1]},
    )
    assert vote.json()["poll"]["vote_counts"] == [0, 1]
    repeated_vote = await client.put(
        f"/api/v1/messages/{message_id}/poll-vote",
        headers=auth(recipient),
        json={"option_indexes": [1]},
    )
    assert repeated_vote.json()["poll"]["vote_counts"] == [0, 1]

    assert (
        await client.put(f"/api/v1/messages/{message_id}/pin", headers=auth(sender))
    ).status_code == 204
    assert (
        await client.put(f"/api/v1/messages/{message_id}/pin", headers=auth(sender))
    ).status_code == 204
    pinned = await client.get(
        f"/api/v1/conversations/{conversation_id}/pinned", headers=auth(recipient)
    )
    assert [item["id"] for item in pinned.json()] == [message_id]

    for _ in range(2):
        reaction = await client.put(
            f"/api/v1/messages/{message_id}/reactions",
            headers=auth(recipient),
            json={"emoji": "ok"},
        )
        assert reaction.json()["reactions"] == {"ok": 1}
    removed = await client.delete(
        f"/api/v1/messages/{message_id}/reactions/ok", headers=auth(recipient)
    )
    assert removed.json()["reactions"] == {}


async def test_rest_message_mutations_broadcast_realtime(client, db, monkeypatch):
    sender = await make_user(db, "+989200000003")
    recipient = await make_user(db, "+989200000004")
    conversation_id = await create_dm(client, sender, recipient)
    events = []

    async def capture(_users, event, _store):
        events.append(event)

    monkeypatch.setattr(manager, "fanout", capture)
    sent = await client.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=auth(sender),
        json={"client_msg_id": "broadcast-1", "body": "first"},
    )
    message_id = sent.json()["id"]
    await client.patch(
        f"/api/v1/messages/{message_id}",
        headers=auth(sender),
        json={"body": "edited"},
    )
    await client.put(
        f"/api/v1/messages/{message_id}/reactions",
        headers=auth(recipient),
        json={"emoji": "ok"},
    )
    await client.delete(f"/api/v1/messages/{message_id}", headers=auth(sender))
    assert [event["type"] for event in events] == [
        "msg.new",
        "msg.edited",
        "msg.reactions",
        "msg.deleted",
    ]


async def test_report_review_state_and_content_removal(client, db):
    sender = await make_user(db, "+989300000001")
    reporter = await make_user(db, "+989300000002")
    moderator = await make_user(db, "+989300000003", UserRole.MODERATOR.value)
    conversation_id = await create_dm(client, sender, reporter)
    sent = await client.post(
        f"/api/v1/conversations/{conversation_id}/messages",
        headers=auth(sender),
        json={"client_msg_id": "reported", "body": "remove me"},
    )
    message_id = sent.json()["id"]
    mismatched = await client.post(
        "/api/v1/reports",
        headers=auth(reporter),
        json={
            "target_type": "group",
            "target_id": conversation_id,
            "conversation_id": conversation_id,
            "reason": "wrong type",
        },
    )
    assert mismatched.status_code == 422
    assert mismatched.json()["error"]["code"] == "invalid_report_target"
    report = await client.post(
        "/api/v1/reports",
        headers=auth(reporter),
        json={
            "target_type": "message",
            "target_id": message_id,
            "conversation_id": conversation_id,
            "message_id": message_id,
            "reason": "abuse",
        },
    )
    assert report.status_code == 201, report.text
    claim = await client.post(
        f"/api/v1/moderation/reports/{report.json()['id']}/claim",
        headers=auth(moderator),
    )
    assert claim.status_code == 200, claim.text
    state = await client.get(
        f"/api/v1/conversations/{conversation_id}/review-state", headers=auth(reporter)
    )
    assert state.json()["under_review"] is True

    resolved = await client.post(
        f"/api/v1/moderation/reports/{report.json()['id']}/resolve",
        headers=auth(moderator),
        json={"outcome": "remove_content", "note": "confirmed"},
    )
    assert resolved.status_code == 200, resolved.text
    state = await client.get(
        f"/api/v1/conversations/{conversation_id}/review-state", headers=auth(reporter)
    )
    assert state.json()["under_review"] is False
    db.expire_all()
    assert (await db.get(Message, UUID(message_id))).deleted_at is not None


async def test_service_detail_result_timeline_and_safe_cancel(client, db):
    student = await make_user(db, "+989400000001")
    staff = await make_user(db, "+989400000002", UserRole.STAFF.value)
    db.add(StaffProfile(user_id=staff.id, department="records", permissions={}))
    service_type = ServiceType(
        name="Transcript",
        required_fields={},
        required_documents=[],
        assignee_dept="records",
        active=True,
    )
    db.add(service_type)
    await db.commit()
    await db.refresh(service_type)

    created = await client.post(
        "/api/v1/services/requests",
        headers=auth(student),
        json={"service_type_id": str(service_type.id), "data": {}},
    )
    assert created.status_code == 201, created.text
    request_id = created.json()["id"]
    claimed = await client.post(
        f"/api/v1/services/requests/{request_id}/claim", headers=auth(staff)
    )
    assert claimed.status_code == 200, claimed.text

    media = Media(
        owner_id=staff.id,
        kind="document",
        mime="application/pdf",
        size=10,
        path="result.pdf",
        original_name="result.pdf",
        sha256="a" * 64,
        status="ready",
    )
    db.add(media)
    await db.commit()
    await db.refresh(media)
    result = await client.post(
        f"/api/v1/services/requests/{request_id}/result",
        headers=auth(staff),
        json={"media_id": str(media.id)},
    )
    assert result.status_code == 201, result.text
    detail = await client.get(f"/api/v1/services/requests/{request_id}", headers=auth(student))
    assert detail.json()["result_document"]["media_id"] == str(media.id)
    assert {item["kind"] for item in detail.json()["timeline"]} >= {
        "submitted",
        "claimed",
        "result_uploaded",
    }

    cancellable = await client.post(
        "/api/v1/services/requests",
        headers=auth(student),
        json={"service_type_id": str(service_type.id), "data": {}},
    )
    cancelled = await client.post(
        f"/api/v1/services/requests/{cancellable.json()['id']}/cancel",
        headers=auth(student),
    )
    assert cancelled.json()["status"] == "cancelled"
    db.expire_all()
    stored = await db.get(ServiceRequest, UUID(cancellable.json()["id"]))
    assert stored.status == "cancelled"


async def test_persisted_call_lifecycle_and_token_scope(client, db):
    caller = await make_user(db, "+989500000001")
    callee = await make_user(db, "+989500000002")
    conversation_id = await create_dm(client, caller, callee)
    payload = {
        "conversation_id": conversation_id,
        "client_call_id": "device-call-1",
        "kind": "video",
    }
    created = await client.post("/api/v1/calls", headers=auth(caller), json=payload)
    duplicate = await client.post("/api/v1/calls", headers=auth(caller), json=payload)
    assert created.status_code == 201, created.text
    assert duplicate.json()["id"] == created.json()["id"]
    call_id = created.json()["id"]

    premature = await client.post(
        "/api/v1/calls/token",
        headers=auth(caller),
        json={"call_session_id": call_id},
    )
    assert premature.status_code == 403
    accepted = await client.post(f"/api/v1/calls/{call_id}/accept", headers=auth(callee))
    assert accepted.status_code == 200, accepted.text
    assert accepted.json()["status"] == "active"

    token_response = await client.post(
        "/api/v1/calls/token",
        headers=auth(caller),
        json={"conversation_id": conversation_id},
    )
    assert token_response.status_code == 200, token_response.text
    assert token_response.json()["room"] == f"call-{call_id}"
    claims = jwt.decode(
        token_response.json()["token"],
        get_settings().livekit_api_secret,
        algorithms=["HS256"],
        options={"verify_aud": False},
    )
    assert claims["video"]["room"] == f"call-{call_id}"

    history = await client.get("/api/v1/calls", headers=auth(callee))
    assert history.json()[0]["id"] == call_id
    ended = await client.post(f"/api/v1/calls/{call_id}/end", headers=auth(caller))
    assert ended.json()["status"] == "ended"
    expired = await client.post(
        "/api/v1/calls/token",
        headers=auth(callee),
        json={"call_session_id": call_id},
    )
    assert expired.status_code == 403


async def test_media_metadata_saved_gifs_and_sticker_collections(client, db):
    user = await make_user(db, "+989600000001")
    media = Media(
        owner_id=user.id,
        kind="gif",
        mime="image/gif",
        size=10,
        path="saved.gif",
        original_name="saved.gif",
        width=20,
        height=10,
        sha256="b" * 64,
        status="ready",
    )
    db.add(media)
    pack = StickerPack(
        handle="official_test",
        title="Official Test",
        kind="static",
        owner_id=user.id,
        is_official=True,
    )
    db.add(pack)
    await db.flush()
    sticker = Sticker(pack_id=pack.id, media_id=media.id, emoji="ok", position=0)
    db.add(sticker)
    await db.commit()

    metadata = await client.get(f"/api/v1/media/{media.id}/metadata", headers=auth(user))
    assert metadata.status_code == 200
    assert metadata.json()["width"] == 20

    assert (await client.put(f"/api/v1/gifs/{media.id}", headers=auth(user))).status_code == 204
    assert str(media.id) in (await client.get("/api/v1/gifs", headers=auth(user))).json()
    assert (await client.delete(f"/api/v1/gifs/{media.id}", headers=auth(user))).status_code == 204
    assert str(media.id) not in (await client.get("/api/v1/gifs", headers=auth(user))).json()

    assert (
        await client.put(f"/api/v1/stickers/{sticker.id}/favorite", headers=auth(user))
    ).status_code == 204
    assert (
        await client.put(f"/api/v1/stickers/{sticker.id}/recent", headers=auth(user))
    ).status_code == 204
    favorites = await client.get("/api/v1/stickers/favorites", headers=auth(user))
    recents = await client.get("/api/v1/stickers/recents", headers=auth(user))
    assert favorites.json()[0]["id"] == str(sticker.id)
    assert recents.json()[0]["id"] == str(sticker.id)
    assert (
        await client.delete(f"/api/v1/stickers/{sticker.id}/favorite", headers=auth(user))
    ).status_code == 204
    assert (
        await client.delete(f"/api/v1/stickers/{sticker.id}/recent", headers=auth(user))
    ).status_code == 204

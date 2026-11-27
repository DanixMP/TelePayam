from uuid import uuid4

from app.core.config import get_settings
from app.core.security import create_access_token
from app.db.models import User
from app.modules.stickers.builtin import ASSET_DIR

API = "/api/v1"


async def test_profile_directory_and_rich_messages_between_accounts(
    client, db, tmp_path, monkeypatch
):
    monkeypatch.setattr(get_settings(), "media_root", tmp_path)
    users = [
        User(
            phone=f"+98977660000{i}",
            role="student",
            status="active",
            first_name=name,
            last_name="Example",
            handle=f"{name.lower()}_example",
        )
        for i, name in enumerate(["Mina", "Sara", "Arman", "Parsa"])
    ]
    db.add_all(users)
    await db.commit()
    a, b, c, outsider = users

    def auth(user):
        return {
            "Authorization": "Bearer " + create_access_token(user.id, user.role, get_settings())
        }

    async def upload(name, mime, data):
        r = await client.post(API + "/media", headers=auth(a), files={"file": (name, data, mime)})
        assert r.status_code == 201, r.text
        return r.json()["id"]

    async def dm(user, peer):
        r = await client.post(
            API + "/conversations/dm", json={"user_id": str(peer.id)}, headers=auth(user)
        )
        assert r.status_code == 201, r.text
        return r.json()

    async def send(user, chat, **payload):
        return await client.post(
            f"{API}/conversations/{chat}/messages",
            headers=auth(user),
            json={"client_msg_id": uuid4().hex, **payload},
        )

    png = (ASSET_DIR / "book.png").read_bytes()
    photo = await upload("photo.png", "image/png", png)
    assert (await client.get(f"{API}/media/{photo}", headers=auth(b))).status_code == 404
    assert (
        await client.patch(API + "/users/me", headers=auth(b), json={"avatar_id": photo})
    ).status_code == 422
    await client.patch(API + "/users/me", headers=auth(a), json={"bio": "University member"})
    updated = await client.patch(API + "/users/me", headers=auth(a), json={"avatar_id": photo})
    assert updated.json()["avatar_id"] == photo and updated.json()["bio"] == "University member"
    for query in ("@mina_", str(a.id)):
        results = (await client.get(API + "/search", headers=auth(b), params={"q": query})).json()
        assert [(r["handle"], r["avatar_id"]) for r in results] == [("mina_example", photo)]
    assert (await client.get(f"{API}/media/{photo}", headers=auth(b))).content == png
    ab = await dm(b, a)
    assert ab["title"] == "Mina Example" and ab["avatar_id"] == photo
    assert ab["is_saved_messages"] is False
    assert (await dm(a, a))["is_saved_messages"] is True
    assert (await dm(a, b))["id"] == ab["id"]
    ab = ab["id"]
    bc = (await dm(b, c))["id"]
    pdf = b"%PDF-1.7\nexample attachment"
    file = await upload("notes.pdf", "application/pdf", pdf)
    first = await send(a, ab, type="file", body="Lecture notes", attachment_ids=[file])
    assert first.status_code == 201
    mid = first.json()["id"]
    reply = await send(b, ab, body="Thanks!", reply_to_id=mid)
    assert reply.json()["reply_to_id"] == mid
    assert (await client.get(f"{API}/messages/{mid}", headers=auth(b))).json()[
        "body"
    ] == "Lecture notes"
    assert (await send(b, bc, body="Wrong chat", reply_to_id=mid)).status_code == 422
    assert (await client.get(f"{API}/messages/{mid}", headers=auth(c))).status_code == 404
    assert (await send(c, bc, forward_from={"message_id": mid})).status_code == 404
    assert (await send(c, bc, type="file", attachment_ids=[file])).status_code == 422
    forwarded = await send(b, bc, body="Client caption", forward_from={"message_id": mid})
    assert forwarded.status_code == 201, forwarded.text
    forward = forwarded.json()
    assert (forward["type"], forward["body"], forward["attachment_ids"]) == (
        "file",
        "Lecture notes",
        [file],
    )
    assert forward["forward_from"]["sender_id"] == str(a.id)
    assert (await client.get(f"{API}/media/{file}", headers=auth(c))).content == pdf
    assert (await client.get(f"{API}/media/{file}", headers=auth(outsider))).status_code == 404

    gif_data = (ASSET_DIR / "flight.gif").read_bytes()
    gif = await upload("flight.gif", "image/gif", gif_data)
    assert (await client.put(f"{API}/gifs/{gif}", headers=auth(b))).status_code == 404
    assert (await send(a, ab, type="animation", attachment_ids=[gif])).status_code == 201
    assert (await client.put(f"{API}/gifs/{gif}", headers=auth(b))).status_code == 204
    assert gif in (await client.get(f"{API}/gifs", headers=auth(b))).json()
    assert (await send(b, bc, type="animation", attachment_ids=[gif])).status_code == 201
    assert (await client.get(f"{API}/media/{gif}", headers=auth(c))).content == gif_data

    sticker = await client.post(
        API + "/stickers/custom", headers=auth(a), json={"media_id": photo, "emoji": "📖"}
    )
    assert sticker.status_code == 201, sticker.text
    assert (await send(a, ab, type="sticker", attachment_ids=[photo])).status_code == 201
    assert (
        await client.put(f"{API}/stickers/media/{photo}/favorite", headers=auth(b))
    ).status_code == 204
    assert (await client.get(API + "/stickers/favorites", headers=auth(b))).json()[0][
        "id"
    ] == sticker.json()["id"]
    assert (await send(b, bc, type="sticker", attachment_ids=[photo])).status_code == 201
    history = (await client.get(f"{API}/conversations/{bc}/messages", headers=auth(c))).json()
    assert [item["type"] for item in history] == ["file", "animation", "sticker"]

    async def preview():
        return (await client.get(f"{API}/conversations/{bc}", headers=auth(c))).json()

    latest = await preview()
    assert (latest["last_message_body"], latest["last_message_type"]) == ("Sticker", "sticker")
    authored = await send(b, bc, body="Sticker")
    assert authored.status_code == 201
    message_url = f"{API}/messages/{authored.json()['id']}"
    latest = await preview()
    assert (latest["last_message_body"], latest["last_message_type"]) == ("Sticker", None)
    assert latest["last_message_edited_at"] is None
    edit = await client.patch(message_url, headers=auth(b), json={"body": "Revised"})
    assert edit.status_code == 200
    revised = await preview()
    assert revised["last_seq"] == latest["last_seq"]
    assert revised["last_message_body"] == "Revised"
    assert revised["last_message_edited_at"] == edit.json()["edited_at"]
    assert (await client.delete(message_url, headers=auth(b))).status_code == 204
    latest = await preview()
    assert latest["last_message_body"] == "Message deleted"
    assert latest["last_message_type"] == "deleted"
    outsider.status = "pending_approval"
    await db.commit()
    assert (await client.get(API + "/search", headers=auth(a), params={"q": "parsa"})).json() == []

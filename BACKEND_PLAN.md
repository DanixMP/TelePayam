# Backend Plan: University Messenger (Telegram-style)

**Main stack:** FastAPI (modular monolith) · PostgreSQL · Redis · LiveKit · Nginx
**Target:** 1k users at launch, up to 2k. Server: 8 cores / 8 GB / 400 Mbps.
**Principle:** one codebase, one deployable, async everywhere. Split only when load tests prove a need.

---

## 1. Roles & Permissions

| Role | How they join | Can do |
|---|---|---|
| **Student** | Phone OTP, then profile form, then **admin approval** | Full messaging, create unlimited groups (public/private), subscribe to channels, open staff service requests, report content |
| **Professor** | **Separate registration flow** (invite / admin-verified, not the student form) | Messaging with students in DMs, own **auto-created channel**, no access to student groups |
| **Staff** | Created by admin | Handle paperwork/service requests, chat with students inside request tickets only |
| **Moderator** | Appointed by admin | Review reports, see *only* reported chats during an open report |
| **Admin** | Created by the super admin | Approve students, manage professors and staff, resolve escalations, audit log access |
| **Super admin** | Provisioned for 09981080891 by the database migration | Admin capabilities plus creating new admin accounts |

Account status: `pending_profile` → `pending_approval` → `active` → (`suspended` | `banned`) (`rejected` is also terminal).

---

## 2. Architecture

```
Flutter ──HTTPS/WSS──► Nginx ──► FastAPI (4 Uvicorn workers, systemd)
                                   │  ├── REST (auth, users, groups, channels, media, services, reports)
                                   │  └── WebSocket gateway (realtime)
                                   ├──► PostgreSQL 16
                                   ├──► Redis (pub/sub, presence, rate limits, OTP, arq queue)
                                   ├──► arq worker (push, thumbnails, ffmpeg, cleanup)
                                   ├──► MinIO or disk (media, served via Nginx)
                                   └──► LiveKit (separate process/box) ◄── FastAPI issues tokens
```

### Module layout

```
app/
  core/            config, security, deps, errors, logging
  modules/
    auth/          OTP, tokens, sessions, devices
    users/         profiles, handles, privacy settings
    approvals/     student approval queue
    professors/    professor registration, auto-channel
    conversations/ dm, group, channel (one table family, type-based)
    messages/      send, edit, delete, reactions, pins, replies, forwards
    realtime/      WS gateway, fan-out, presence, typing
    media/         uploads, thumbnails, voice, video notes
    stickers/      packs, GIFs, favorites, recents
    calls/         LiveKit tokens, call logs
    reports/       report flow, access grants, audit
    services/      staff paperwork (tickets, documents)
    notifications/ FCM, in-app, preferences
    admin/         SQLAdmin + admin REST
    search/        users, public groups, channels
  workers/         arq jobs
  migrations/      Alembic
```

Each module = `router.py`, `service.py`, `models.py`, `schemas.py`, `repo.py`. Modules talk through service functions, never through each other's tables.

---

## 3. Authentication & Registration

### 3.1 OTP login (all roles)
1. `POST /auth/otp/request {phone}` → Redis key `otp:{phone}` (hashed code, TTL 2 min), SMS via a local SMS provider (abstract behind `SmsProvider` interface).
2. `POST /auth/otp/verify {phone, code}` → returns access token (15 min) + refresh token (30 days, hashed in DB, rotated on use).
3. Rate limits: 3 OTPs / 10 min / phone, 10 / hour / IP, lockout after 5 wrong codes. Constant-time compare.

### 3.2 Student registration
After first OTP, status = `pending_profile`. Required fields:
- first name, family name
- **National ID** (10 digits, validate the Iranian checksum)
- degree (BSc / MSc / PhD / other), field/department
- **University student ID**

On submit → `pending_approval`. Admin sees a queue: approve / reject (with reason) / request correction. Optional cross-check against a university roster CSV import to auto-flag mismatches.

**Sensitive data handling:** National ID stored **encrypted at rest** (app-level AES-GCM, key outside DB) plus a **HMAC hash** column for uniqueness checks. Never returned by public APIs, masked in admin UI (`******1234`), full view is an audited action.

### 3.3 Professor registration (different path)
- Admin creates a professor invite (name, phone, department, title) or approves a professor self-request verified against a faculty list.
- Professor completes OTP, confirms name/department. **No student fields** (no student ID, no degree).
- On activation, **auto-create a channel** named after the professor (see §6.3).

### 3.4 Sessions & devices
`devices` table (FCM token, platform, last_seen). Users can list and terminate sessions. Refresh token reuse detection revokes the whole family.

---

## 4. Data Model (core tables)

```
users(id, phone, role, status, first_name, last_name, handle, avatar_id, bio, created_at, ...)
student_profiles(user_id, national_id_enc, national_id_hash, degree, department, university_id, reviewed_by, reviewed_at, reject_reason)
professor_profiles(user_id, department, title, channel_id)
staff_profiles(user_id, department, permissions)

conversations(id, type[dm|group|channel], visibility[public|private], handle, title, description, avatar_id,
              owner_id, created_at, member_count, is_professor_channel, settings jsonb)
conversation_members(conversation_id, user_id, role[owner|admin|member|subscriber|banned], last_read_seq, muted_until, joined_at)
messages(id, conversation_id, seq, sender_id, client_msg_id, type, body, entities jsonb,
         reply_to_id, forward_from, edited_at, deleted_at, created_at)
   UNIQUE(sender_id, client_msg_id)   INDEX(conversation_id, seq DESC)
message_reactions, message_pins, message_attachments, polls, poll_votes
invite_links(conversation_id, token, expires_at, uses, max_uses)

media(id, owner_id, kind, mime, size, path, width, height, duration, thumb_path, blurhash, sha256)
sticker_packs(id, handle, title, kind[static|animated|video], owner_id, is_official)
stickers(id, pack_id, media_id, emoji, position)
user_sticker_packs(user_id, pack_id, position)
saved_gifs(user_id, media_id, created_at)
recent_stickers(user_id, sticker_id, used_at)

reports(id, reporter_id, target_type, target_id, conversation_id, message_id, reason, status, created_at, resolved_at, resolved_by, resolution)
report_access_grants(id, report_id, conversation_id, granted_to, scope, expires_at, revoked_at)
audit_log(id, actor_id, action, target, metadata, ip, created_at)

service_types(id, name, description, required_fields jsonb, required_documents jsonb, assignee_dept)
service_requests(id, student_id, service_type_id, status, assigned_staff_id, data jsonb, created_at, updated_at)
service_request_events(id, request_id, actor_id, kind, note, created_at)
service_request_messages(id, request_id, sender_id, body, attachment_id, created_at)
service_request_documents(id, request_id, media_id, kind, uploaded_by)

devices(id, user_id, platform, fcm_token, last_seen)
refresh_tokens(id, user_id, family_id, token_hash, expires_at, revoked_at)
```

**Per-conversation `seq`** is the backbone: ordering, pagination, unread counts, and reconnect sync are all integer comparisons. Allocate it inside the insert transaction (counter row `conversations.last_seq` updated with `RETURNING`), keeping writes serialized per conversation only.

---

## 5. Handles / ID System (design now, finalize later)

Requirement: finding users and channels by ID, **strict**, derived from the user's name, not free-form.

Build the system behind one interface so the rule can change later:

```python
class HandlePolicy(Protocol):
    def generate(self, user: User) -> str: ...
    def validate(self, handle: str) -> bool: ...
```

- Table column `handle` (unique, case-insensitive, immutable by users; changes only via admin).
- Resolve endpoint: `GET /resolve/{handle}` → user, group, or channel.
- Placeholder rule for development: `normalized(first)_normalized(last)` + collision suffix. **The real scheme is deferred**; nothing else in the codebase may assume its shape.
- Handle search by exact match and prefix, ranked; rate-limited to prevent directory scraping.

---

## 6. Messaging Feature Set (Telegram parity)

### 6.1 Conversation types
- **DM:** two members, exactly one per pair (unique pair constraint).
- **Group:** unlimited creation per student. Public (has handle, searchable, join directly) or private (invite link only, not searchable). Roles: owner/admin/member with granular admin rights, slow mode, member limits, join-approval option, topics (later).
- **Channel:** one-to-many; admins post, subscribers read, optional comments via linked discussion group, view counters.

### 6.2 Message features
Text with entities (bold, italic, code, links, mentions, spoilers) · replies · forwards · edit · delete (for me / for everyone) · reactions · pins · polls · voice messages · video notes · photos/videos/files/albums · location (optional) · contacts (optional) · link previews (server-side fetch with SSRF protection) · typing / recording indicators · read receipts (seq-based) · drafts (sync) · scheduled messages · silent messages · saved messages (self-DM) · message search (Postgres FTS or Meilisearch later) · mentions & unread-mention counters.

### 6.3 Professor auto-channel
On professor activation, a job creates a channel:
- Title from name (e.g. "Dr. Name Family"), handle from the strict ID policy, `is_professor_channel = true`.
- Professor = owner; students subscribe. Admins can reassign or archive if the professor leaves.
- Optional per-channel comment group for Q&A, still obeying the visibility rules below.

### 6.4 Stickers & GIFs (Telegram-style)
- **Sticker packs:** static (WebP), animated (Lottie JSON, served gzip), video (WebM VP9). Official packs seeded by admins; user-made packs allowed later behind moderation.
- Endpoints: installed packs, pack detail, add/remove/reorder, recents, favorites, emoji-to-sticker suggestions.
- **GIFs:** no dependency on Giphy/Tenor. Users upload GIF/MP4, the worker converts to looping muted MP4/WebM + poster; "saved GIFs" per user; optional curated GIF library seeded by admins.
- Processing in arq with ffmpeg, with size/duration limits and concurrency cap (so conversions don't starve the chat workers).

### 6.5 Media pipeline
Direct multipart or chunked resumable upload → validate (magic bytes, size, MIME) → store → worker creates thumbnails, blurhash, video poster, waveform for voice → message references `media_id`. Nginx serves files with signed, expiring URLs (`secure_link`). Images compressed client-side before upload.

---

## 7. Realtime Protocol (write this as a spec first)

Single WS endpoint `/ws` with token auth. JSON frames (switch to MessagePack later if needed).

| Client → Server | Purpose |
|---|---|
| `msg.send {conv, client_msg_id, type, body, reply_to, ...}` | send |
| `msg.edit`, `msg.delete`, `msg.react` | mutate |
| `read {conv, seq}` | read receipt |
| `typing {conv, action}` | typing / recording / uploading |
| `sync {conv: last_seen_seq, ...}` | reconnect catch-up |
| `call.invite / accept / decline / end` | call signaling |
| `ping` | heartbeat (~25 s) |

| Server → Client | Purpose |
|---|---|
| `msg.ack {client_msg_id, seq, id}` | idempotent ack |
| `msg.new / edited / deleted / reaction` | updates |
| `read.update`, `typing`, `presence` | ephemeral |
| `conv.updated`, `member.updated` | metadata |
| `call.incoming / ...` | calls |
| `account.status` | approval status change pushed live |

**Flow:** validate → permission check → write (idempotent by `client_msg_id`) → ack sender → publish to Redis `conv:{id}` → workers forward to local sockets → offline members get an arq push job. Reconnect uses `sync` with last-seen seq per conversation; also a global update cursor for membership and metadata changes.

Fan-out for large channels: batch deliveries, use per-user personal channels `user:{id}` rather than per-member loops inside the request path.

---

## 8. Privacy & Visibility Rules (hard requirements)

These are enforced in **one policy layer** (`can(user, action, resource)`), with tests, not scattered across routes.

### 8.1 Professors never see student groups
- Student-created groups carry `created_by_role = student` and `audience = students`.
- **Search / resolve / suggestions:** professors never get student groups or student-only public groups in results. Querying a student group handle as a professor returns `404`, not `403` (no existence leak).
- **Membership:** professors cannot join, be invited to, or be added to student groups. Add-member and invite-link join endpoints reject professor accounts.
- **Linked data:** group names, member counts, and messages never appear in any professor-facing API, notification, or analytics.
- Professors may DM students and publish to their own channel, where students subscribe.
- **Edge case to decide:** can a student forward a professor's message into a student group? (Recommended: yes, it is the student's content once forwarded, but the forward link back to the professor channel stays allowed.)

### 8.2 Personal chats are private
- DMs and private groups are **inaccessible to admins, staff, moderators, and the DB-facing admin UI**. The admin panel has no message browse feature at all.
- Message bodies encrypted at rest (envelope encryption with per-deployment master key kept outside the DB, rotated periodically), so a raw DB dump or backup doesn't expose chats. This is not end-to-end encryption; the server can decrypt to deliver, search, and handle reports. State this honestly in the privacy policy.
- Optional later: **Secret chats** (E2E, device-bound, no server history, not reportable by the standard flow). Decide before launch whether you want this; it changes the data model.

### 8.3 Report system, the only door
1. User reports a message, user, group, or channel (`reason`, optional note).
2. System snapshots the reported message(s) + surrounding context into `reports` (immutable evidence, so deleting the message can't erase it).
3. A **moderator is assigned** and a `report_access_grant` is created: scoped to *that conversation only*, bound to that report, **expires automatically** (e.g. 7 days) and **revoked on resolution**.
4. While the grant is active, the moderator can read the conversation (read-only). Every access is written to `audit_log`.
5. Moderator resolves with an outcome (dismiss / warn / mute / remove content / ban / escalate to admin). On resolve, access is revoked immediately.
6. The reporter and the reported party are notified of the outcome.

Safeguards: a moderator cannot moderate a report involving themselves, admin reviews a random sample of audit logs, abuse of the report system (false mass-reports) is detectable and penalized. Policy question to settle: should conversation access cover the **whole chat** or a **window around the reported messages**? Recommended: default to a window (e.g. ±50 messages) with an "request wider access" action that needs a second approver.

---

## 9. Staff Services: Paperwork Without Visiting Campus

A ticketing-style module:
- **Service catalog** (admin-defined): enrollment certificate, transcript request, leave of absence, document correction, ID card issue, etc. Each type defines required fields and documents.
- **Student flow:** pick service → fill form → upload documents → submit → track status.
- **Statuses:** `submitted → in_review → needs_info → approved|rejected → completed` (+ `ready_for_pickup` or `delivered_digitally`).
- **Staff flow:** department queues, assignment, internal notes, request more info, upload the **result document** (signed PDF with QR verification code).
- **Per-request chat:** student and staff talk inside the ticket thread only; staff never get access to the student's other chats.
- **Notifications:** push + in-app on every status change, with SLA timers and reminders.
- **Verification:** issued documents carry a QR/verification URL (`/verify/{code}`) so third parties can validate them.
- Audit trail: every status change and document view is logged.

---

## 10. Calls (LiveKit)

- Self-host LiveKit (separate machine if possible), with built-in TURN over TLS on 443/5349 for campus networks.
- `POST /calls/token {conversation_id}` → permission check → short-lived LiveKit JWT. Room = call ID.
- Signaling over the chat WS (`call.*`). LiveKit webhooks → call start/end/duration written as a service message in the chat.
- Incoming calls while the app is closed: FCM high-priority data push + native call UI on the client.
- Limits: 720p cap, group call size cap (e.g. 8) for the MVP. Load-test with `lk load-test`.

---

## 11. Notifications
FCM (and a fallback self-hosted channel if Google services are unreliable from your network, to check early, e.g. UnifiedPush or a persistent foreground-service socket on Android). Per-conversation mute, quiet hours, preview toggle, badge counts computed from `last_read_seq`. Push payloads contain **no message text** by default (the app fetches after wake) for privacy.

---

## 12. Admin Panel
SQLAdmin (or a small Flutter Web/React panel) with:
- Student approval queue (approve / reject / request correction), bulk actions, roster CSV import
- Professor and staff management, role assignment
- Official sticker pack management
- Report dashboard (for moderators; conversation view appears **only** inside an active grant)
- Service catalog management, SLA dashboard
- Audit log viewer, platform stats (no message content)

All admin actions are logged. Admins and the super admin sign in with a phone OTP. Moderators also require TOTP.

---

## 13. Security Checklist
- TLS everywhere, HSTS; secure headers; CORS locked down
- Argon2/HMAC for secrets; JWT short-lived; refresh rotation + reuse detection
- Rate limiting in Redis (OTP, search, messages/sec per user, uploads)
- Input validation with Pydantic; upload scanning (type/size, optional ClamAV); SSRF-safe link previews
- National ID and message encryption keys outside the DB, with rotation procedure
- Row-level checks in a single policy module, plus tests for every visibility rule in §8
- Backups: nightly `pg_dump` + WAL archiving if possible, encrypted, copied off-server; restore drill before launch
- Legal/compliance: confirm Iranian data-protection and university policy requirements for storing National IDs and for the report/moderation process

---

## 14. Infrastructure & Ops (single 8-core / 8 GB box)

| Component | Budget |
|---|---|
| Postgres | ~2 GB RAM (`shared_buffers` ~1 GB), tuned for the box |
| Redis | ~512 MB |
| FastAPI | 4 workers, ~1.5 GB total |
| arq worker | 1-2 processes (cap ffmpeg concurrency) |
| Nginx + media | page cache does the rest |
| LiveKit | own machine preferred; otherwise cap video |

Systemd units per service, Alembic migrations in deploy script, `/health` and `/ready` endpoints, structured JSON logs, Prometheus + Grafana later. Staging environment mirrors prod. Load test the realtime path (e.g. Locust or a custom WS script, target 2k concurrent sockets) before launch.

---

## 15. Testing
- Unit tests for services and the **policy layer** (every row of §8)
- Integration tests with a real Postgres + Redis (testcontainers)
- WS protocol tests: idempotent send, ack, reconnect sync, ordering
- Load tests: 2k sockets, bursty group sends, large-channel fan-out
- Privacy regression suite: "professor can never see X", "admin can't read DM without grant", "grant expires and revokes"

---

## 16. Roadmap

| Phase | Scope |
|---|---|
| **0. Foundations** (wk 1) | Repo, config, Docker/dev env, Alembic, CI, handle-policy stub, WS protocol spec |
| **1. Identity** (wk 2-3) | OTP, tokens, student form, approval queue, professor flow, roles, policy layer |
| **2. Core chat** (wk 3-6) | DMs, `seq`, WS gateway, ack/sync, unread, presence, typing, push |
| **3. Groups & channels** (wk 6-8) | Public/private groups, invite links, roles, channels, professor auto-channel, visibility rules + tests |
| **4. Rich media** (wk 8-10) | Uploads, thumbnails, voice, albums, stickers, GIFs, reactions, replies, forwards, pins, polls |
| **5. Reports & moderation** (wk 10-11) | Report flow, grants, audit log, moderator tooling |
| **6. Staff services** (wk 11-13) | Catalog, tickets, documents, notifications, verification QR |
| **7. Calls** (wk 13-15) | LiveKit, tokens, call signaling, call logs, native ring |
| **8. Hardening** (wk 15-16) | Load tests, security review, backup drill, pilot with a small cohort |

Timeline is a rough solo-developer estimate; phases 2 and 7 (realtime and incoming-call push) are the usual overruns.

---

## 17. Open Decisions
1. Final **handle/ID scheme** (deferred by you; the `HandlePolicy` interface keeps it isolated)
2. Report access scope: whole chat vs window, and the second-approver rule
3. Secret (E2E) chats: yes or no for v1
4. Can students forward professor-channel posts into student groups?
5. Push fallback if FCM is unreliable on the university network
6. Roster source for auto-verifying students and professors
7. Message retention policy and account deletion rules

## 18. Other Stacks (kept as options)
- **Go:** rewrite the realtime gateway only, if load tests demand it (the WS spec stays identical).
- **Node/Socket.io:** only if rooms/ack convenience outweighs adding a third language.
- **Elixir/Phoenix:** reconsider if chat becomes the long-term multi-university product.
- **Matrix/Nakama:** fallback if time-to-launch beats UX control.

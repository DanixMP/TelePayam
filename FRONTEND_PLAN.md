# Frontend Plan: University Messenger (Flutter, Telegram replica)

**Stack:** Flutter (Dart 3) · Riverpod · go_router · Drift (SQLite) · web_socket_channel · dio · livekit_client
**Platforms:** Android first, then Windows desktop, then iOS if needed.
**Goal:** a Telegram-faithful experience: same layouts, gestures, speed, and polish, adapted for Persian/RTL and university roles.

---

## 1. Principles
1. **Offline-first:** the local DB is the source of truth for the UI; the network syncs into it. Opening a chat is instant.
2. **Optimistic UI:** sent messages appear immediately (`sending → sent → delivered → read`), reconciled by `client_msg_id`.
3. **Protocol-driven:** the client implements the backend WS spec exactly, so backend swaps never touch the app.
4. **Role-aware:** one app, UI shaped by `role` and `status` (student / professor / staff / moderator / admin).
5. **60/120 fps:** lists are virtualized, heavy work (image decode, waveform, Lottie) is cached or off the UI thread.
6. **RTL-first:** Persian is a primary language, with English supported, mixed-direction text handled properly.

---

## 2. Architecture

Feature-first clean architecture.

```
lib/
  main.dart
  app/            router, theme, localization, app shell, DI (Riverpod providers)
  core/
    network/      dio client, interceptors (auth refresh), ws client, protocol models
    storage/      Drift database, secure storage (tokens), prefs
    sync/         sync engine (seq-based), outbox queue, update cursor
    media/        upload manager (resumable), cache manager, thumbnails
    utils/        jalali dates, formatters, debouncers, permissions
    widgets/      shared UI kit
  features/
    onboarding/   splash, welcome, phone, otp
    registration/ student form, professor completion, approval-pending screen
    chats/        chat list, folders, archive, search
    chat/         message list, bubbles, composer, selection, reply, forward
    media_viewer/ photos, videos, gifs, files
    stickers/     panel, packs, search, favorites, recents, animated renderer
    groups/       create, info, members, admin tools, invite links
    channels/     channel view, subscribe, comments, professor channels
    contacts/     user search by ID, profile view
    calls/        incoming/outgoing UI, in-call, callkit integration
    reports/      report flow
    services/     staff paperwork: catalog, request form, tracker, ticket chat
    settings/     profile, privacy, notifications, devices/sessions, language, theme, storage
    admin/        approval queue and tools (Flutter, role-gated; or web build)
```

Each feature: `data/` (api + repo + dto), `domain/` (entities, usecases), `presentation/` (screens, widgets, providers/notifiers).

### Key libraries
| Need | Package |
|---|---|
| State | `flutter_riverpod` (+ `riverpod_generator`) |
| Routing | `go_router` (role/status redirect guards) |
| Local DB | `drift` + `sqlite3` (FTS5 for local search) |
| HTTP | `dio` |
| WebSocket | `web_socket_channel` (own reconnect/heartbeat wrapper) |
| Secure storage | `flutter_secure_storage` |
| Images | `cached_network_image` or custom cache, `blurhash` |
| Animated stickers | `lottie` (JSON), `video_player` / WebM for video stickers |
| GIFs | looping muted MP4 via `video_player` (lighter than real GIF decoding) |
| Voice | `record`, `just_audio`, waveform painter |
| Camera / picker | `camera`, `image_picker`, `photo_manager` (custom gallery sheet) |
| Calls | `livekit_client`, `flutter_callkit_incoming` |
| Push | `firebase_messaging` (+ fallback plan, see §14) |
| Links | `flutter_linkify`, custom entity renderer |
| i18n | `flutter_localizations`, `intl`, `shamsi_date` / `jalali` |
| Models | `freezed` + `json_serializable` |

---

## 3. Navigation & Flow Gating

`go_router` with a single redirect function driven by an `authStateProvider`:

```
no token                 → /welcome → /phone → /otp
status = pending_profile → /register/student  (role=student)
                           /register/professor (role=professor)
status = pending_approval→ /pending   (live-updates via WS `account.status`)
status = rejected        → /rejected  (reason + resubmit)
status = suspended|banned→ /blocked
status = active          → /home shell
```

Home shell (Telegram-like):
- **Mobile:** chat list as root, drawer (profile, new group, new channel, contacts, services, saved messages, settings), search bar, FAB (new message). Bottom tabs optional: Chats · Services · Settings.
- **Desktop / wide:** two-pane (list left, chat right) via `LayoutBuilder` breakpoints, with a third pane for chat info.

---

## 4. Screens (Telegram parity checklist)

### 4.1 Onboarding & registration
- Splash, welcome, phone input (country code, +98 default), OTP input (auto-read SMS on Android, resend timer, error shake)
- **Student form:** first name, family name, National ID (10 digits, live checksum validation), degree picker, department, university ID. Review screen, submit.
- **Professor completion:** name/department confirmation; no student fields.
- **Pending approval screen:** friendly status card, live update when an admin approves (WS), "edit submission" if correction was requested.

### 4.2 Chat list
Rows: avatar (with online dot), title, last-message preview (typed icon for media/sticker/voice), time (Jalali/Gregorian by setting), unread badge (muted = gray), pin, mute icon, delivery ticks, typing indicator in row, draft preview. Swipe actions (archive, pin, mute, delete), long-press multi-select, folders (tabs: All, Groups, Channels, Unread, custom), archive, global search (chats, messages, people by ID).

### 4.3 Chat screen
- App bar: avatar, title, status (online / last seen / typing / member count), call buttons, menu.
- **Message list:** reverse `ListView` with sliver anchoring, date separators, unread divider ("New messages"), jump-to-bottom button with unread count, jump-to-message with highlight, pagination by `seq`, scroll-position restore.
- **Bubbles:** text with entities (bold, italic, code, pre, links, mentions, spoilers), reply preview, forwarded header, edited label, reactions row, ticks, view counts (channels), link preview card, photo/album grid, video with duration, file card, voice message with waveform + speed toggle, video note (round), location (optional), poll, stickers (no bubble), GIF/animation, service messages ("X joined", call logs), pinned message bar.
- **Gestures:** swipe-to-reply, long-press menu (reply, copy, forward, pin, edit, delete, react, select, report), double-tap quick reaction, tap-to-open media, drag to select.
- **Composer:** multi-line input with emoji/sticker/GIF toggle, attach sheet (gallery, camera, file, poll, location, contact), hold-to-record voice with slide-to-cancel and lock, tap-to-switch video note, reply/edit/forward bars, draft autosave, `@mention` and `/command` suggestions, schedule send, silent send.
- Per-chat settings: mute, search in chat, clear history, block, report.

### 4.4 Stickers, emoji & GIFs
- Bottom panel with tabs: **Emoji · Stickers · GIFs**, keyboard-height-matched swap (no layout jump).
- Sticker tab: recents, favorites, installed packs strip, pack detail sheet with Add button, emoji-triggered sticker suggestions above the keyboard.
- Renderers: static WebP, Lottie (animated, paused when off-screen), WebM video stickers; in-memory LRU cache + disk cache.
- GIF tab: saved GIFs and the campus curated library, search, long-press preview, "save GIF" from any message.
- Custom emoji reactions (reaction picker is a compact emoji strip).

### 4.5 Groups & channels
- Create group (name, avatar, members), **public/private toggle**, handle input for public.
- Group info: members list, roles, add members, invite link (copy/share/revoke), admin rights editor, slow mode, permissions, media/files/links tabs, leave/delete.
- Unlimited groups are fine for the UI; list and search remain paginated.
- **Channels:** feed-style layout, subscribe/unsubscribe, view counters, comment button (linked discussion).
- **Professor channels:** auto-created, shown with a "Professor" badge, discoverable in a dedicated section; students subscribe.
- **Visibility rules in UI:** professor accounts never get "create group", "student groups", or student-group search surfaces; the backend enforces it, and the client simply never renders those entry points for `role=professor`.

### 4.6 Contacts & search
Search by **ID/handle** (strict system, shown as `@id`), by name for already-known people, results grouped (people, groups, channels, messages). Profile view: avatar, name, ID, role badge, bio, shared media, message / call buttons, block, report.

### 4.7 Calls
Outgoing/incoming screens, in-call UI (mute, speaker, camera flip, video toggle, end), picture-in-picture, call logs as service messages. Native ringing via CallKit/ConnectionService when the app is closed. Group call grid later.

### 4.8 Reports
"Report" in message menu, profile, and group menu, with reason picker, optional note, confirmation. After reporting, the user sees a neutral notice: "The reported conversation may be reviewed by a moderator until the report is resolved." Outcome notification when resolved. Transparency matters: the user always knows when a conversation is under review (banner on the chat while a grant is active).

### 4.9 Staff services (paperwork)
- **Services tab:** catalog grid (certificates, transcripts, leave, corrections, ID card...).
- Request wizard from the service's required fields and documents (camera scan / gallery / file upload with preview).
- **My requests:** list with status chips and timeline; detail page with timeline, documents, issued result download (PDF viewer with QR), and a **ticket chat** with staff (reuses the chat message components).
- Push on every status change.

### 4.10 Settings
Profile (photo, name, bio; National ID shown masked, read-only), privacy (last seen, who can add me, who can call), notifications (per type, sounds, preview), devices/sessions, chat settings (text size, bubble style, wallpaper, animations), language (Persian/English), theme, data & storage (cache manager, auto-download rules), about.

### 4.11 Staff / moderator / admin screens
Gated by role. Staff: queue, assigned tickets, ticket chat, result upload. Moderator: reports list; the conversation viewer opens **only** when an active access grant exists and shows a "Reviewing under report #id" banner. Admin: approval queue (card swipe approve/reject), user lookup, stats. Heavy admin tooling may live in a Flutter Web build or the backend admin panel instead.

---

## 5. Design System

- **Telegram-like look:** blue accent (configurable), clean list rows, rounded bubbles with tails, soft wallpapers, subtle ripple/spring animations.
- **Themes:** light, dark, AMOLED black, accent color picker, chat wallpapers (solid, gradient, pattern).
- **Typography:** Persian-first font (e.g. Vazirmatn) bundled, with Latin fallback; text scale setting.
- **Tokens:** colors, spacing, radii, elevations, durations in a `ThemeExtension`.
- **Components:** `AppAvatar`, `ChatTile`, `MessageBubble` variants, `Composer`, `ReactionBar`, `StickerView`, `VoiceBubble`, `MediaGrid`, `BottomSheetMenu`, `ContextMenu`, `StatusChip`, skeleton loaders.
- **Motion:** page transitions, bubble send animation, reaction burst, typing dots, smooth keyboard/panel transition.
- **Accessibility:** semantic labels, large text, contrast checks, screen reader order in bubbles.

---

## 6. Local Database (Drift)

Tables: `users`, `conversations`, `members`, `messages` (indexed by `conversation_id, seq`), `message_media`, `reactions`, `drafts`, `outbox` (pending sends), `stickers`, `sticker_packs`, `saved_gifs`, `service_requests`, `settings`, `sync_cursors`. FTS5 table for local message search.

- UI reads from DB via Drift **streams**, wrapped in Riverpod `StreamProvider`s.
- The sync engine and WS handler write to the DB; the UI never reads from the network directly.
- Message bodies on device are protected by OS file-level encryption; optional SQLCipher with the key in secure storage.
- Cache eviction policy for media (size cap, LRU), with a cache-clear UI.

---

## 7. Realtime & Sync Engine

- **WS client wrapper:** connect, auth, heartbeat (~25 s ping), exponential backoff with jitter, network-change listener (`connectivity_plus`), app lifecycle handling (pause/resume).
- **Outbox:** unsent messages persisted; retried with the same `client_msg_id` (idempotent server-side); ordering preserved per conversation.
- **Reconnect:** send `sync {conv: last_seen_seq}` for active conversations plus the global update cursor; apply missed messages/edits/deletes in order.
- **Dedup:** by `(conversation_id, seq)` and `client_msg_id`.
- **Typing / presence:** debounced sends, auto-expiring indicators.
- **Account status events** (`account.status`) route the user live (approval granted → home).
- Background: foreground-friendly; closed-app delivery through push.

---

## 8. Media Handling
- Compress images and videos before upload; show blurhash instantly, progressive thumbnail → full.
- Resumable chunked uploads with progress, cancel, retry; background upload continuation on Android.
- Voice: record AAC/Opus, waveform generation on-device, playback with speed and continuous play of consecutive voice notes.
- Viewer: pinch zoom, swipe between media, share/save/forward, video scrubber, GIF loop controls.
- Auto-download rules (Wi-Fi / mobile / roaming per media type).

---

## 9. Calls Integration
`livekit_client` with simulcast, adaptive stream, dynacast on. Fetch token from the backend → connect to the room. Signaling via WS `call.*`. `flutter_callkit_incoming` + FCM high-priority data message for the ringing UI. Test on restrictive campus Wi-Fi early.

---

## 10. Localization & RTL
Persian and English; `Directionality` per message (detect text direction per bubble, so mixed Persian/English renders correctly); Persian digits option; Jalali calendar for dates with a Gregorian toggle; pluralization rules; bidirectional-safe inputs for IDs and numbers (force LTR for IDs).

---

## 11. Performance Targets
- Cold start to chat list < 2 s (from local DB), chat open < 150 ms
- Smooth scroll in 10k-message chats (windowed queries, not full loads)
- Image/Lottie memory caps, off-screen animation pausing
- Profile on a low-end Android device (not only the dev laptop); track jank with DevTools and `--profile` builds

---

## 12. Testing
- Unit: repositories, sync engine, outbox, protocol parsing
- Widget/golden tests: bubble variants (LTR/RTL, all media types), chat list rows, composer states
- Integration: onboarding gating flow, send/receive with a mock WS server, reconnect catch-up
- Role matrix tests: each role sees only its entry points (esp. **professor never sees student-group UI**)
- Manual device matrix: low-end Android, Android 8-14, Windows, slow/flaky network

---

## 13. Security & Privacy (client side)
- Tokens in secure storage; auto-refresh interceptor with single-flight refresh
- Screenshot blocking option (Android `FLAG_SECURE`) for sensitive screens; app lock (PIN/biometric)
- National ID masked everywhere; never logged
- No message text in push payloads; notification content fetched after wake
- Certificate pinning (optional) for your own domain
- Clear local data on logout and on session termination from another device
- Honest reporting UX: users are always shown when a chat is under review

---

## 14. Risks & Open Decisions
1. **Push without Google services:** test FCM reachability early, with a fallback (persistent socket / UnifiedPush) if needed
2. Desktop (Windows) scope: full parity vs companion
3. Secret chats (E2E): v1 or later
4. Admin UI inside the Flutter app vs a separate web panel
5. Animated stickers: Lottie-only first, WebM later
6. Final ID/handle format (displayed as `@id`; keep it a plain string in the client so the format can change)
7. Apple platform: only if a university-wide iOS audience needs it (CallKit/PushKit adds work)

---

## 15. Roadmap

| Phase | Scope |
|---|---|
| **0. Setup** (wk 1) | Project, flavors (dev/prod), theme + design tokens, router, Riverpod structure, Drift schema, WS protocol client skeleton, CI |
| **1. Identity** (wk 2-3) | Splash, phone, OTP, student form (National ID validation), professor completion, pending/rejected screens, status-based routing |
| **2. Chat core** (wk 3-6) | Chat list, DM screen, bubbles (text), composer, outbox, sync engine, read/typing/presence, local search |
| **3. Groups & channels** (wk 6-8) | Create/join groups (public/private), info screens, roles, invite links, channels, professor channel UX, role-based entry points |
| **4. Rich messaging** (wk 8-11) | Photos/video/files/albums, voice, replies, forwards, edit/delete, reactions, pins, polls, link previews, stickers, GIFs, emoji panel |
| **5. Reports & moderation** (wk 11-12) | Report flow, under-review banners, moderator viewer (grant-gated) |
| **6. Services** (wk 12-14) | Catalog, request wizard, tracker, ticket chat, document viewer |
| **7. Calls** (wk 14-16) | LiveKit audio then video, CallKit ringing, call logs, PiP |
| **8. Polish & launch** (wk 16-18) | Performance pass, accessibility, RTL audit, theming, desktop layout, beta cohort, crash reporting |

Timeline is a rough solo estimate. The biggest time sinks are the message list (scroll anchoring + pagination), composer/keyboard/panel transitions, and incoming-call push.

---

## 16. Definition of "Telegram replica" for v1
**Must feel the same:** chat list, bubble layout, swipe-to-reply, sticker/GIF panel, voice recording gesture, media viewer, channel and group info pages, smooth animations.
**Deliberately different:** phone-OTP + admin-approved identity, strict ID system, role-based surfaces (professor channels, staff services), report-gated privacy model.
**Later:** secret chats, bots, stories, premium-style extras, multi-account.

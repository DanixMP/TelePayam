---
version: 1
slug: "chat-core"
primary_target: "frontend/lib/features/chats"
related_targets: ["frontend/lib/core/network/realtime_client.dart", "frontend/lib/core/storage/app_database.dart"]
---

# Chat Core

Mode: Operate

Scope: Phase 2 local-first chat list, local search, sequence-paginated text conversations, optimistic composer, outbox retry, typing, read markers, and reconnect sync on Android and Windows.

Constraints: Inherit the established Telegram-familiar Material system. The backend does not expose presence or message-content search, so presence is omitted and message search remains local. Conversation APIs omit peer/avatar/preview fields; the client uses available metadata and locally cached message previews without inventing network claims.

## Direction contract

THESIS: Conversation state should be understood before decoration. The interface refuses dashboard cards and keeps the list, message history, and composer in their familiar messenger positions.

OWN-WORLD: Semantic Telegram blue, cool surface containers, circular identity markers, 14dp controls, directional 16/4dp bubbles, and verified professor markers extend the identity system into messaging.

STORY: Cached conversations appear immediately, search narrows local titles and message bodies, a conversation restores its history, and a sent message enters instantly before delivery reconciliation.

FIRST VIEWPORT: Compact screens show a full-width inbox with a 72dp identity/search bar. At 900dp, a 390dp inbox remains visible beside the selected conversation; the composer is pinned to the bottom while history owns the field.

FORM: Established Telegram-faithful native messenger world, extended rather than replaced. `seed:6579ec02d090585c`.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

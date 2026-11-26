# WebSocket Protocol v1

Connect to `/ws?token=<access-token>`. Frames are JSON objects with `type` and `data`.

## Client Events

- `ping`
- `msg.send`: `data` contains `conv`, `client_msg_id`, `type`, `body`, `entities`, optional `reply_to_id`, `attachment_ids`, `silent`.
- `read`: `data` contains `conv` and `seq`.
- `typing`: `data` contains `conv` and `action` (`typing`, `recording`, or `uploading`).
- `sync`: `data.conv` maps conversation UUIDs to the client's last stored sequence.
- `call.invite`: `data` contains `conv`, `client_call_id`, and `kind` (`audio` or `video`).
- `call.accept`, `call.decline`, `call.end`: `data` contains `call_id`.

## Server Events

- `pong`
- `msg.ack`: confirms the idempotency ID and assigned message ID/sequence.
- `msg.new`: a committed message.
- `read.update`
- `typing`
- `sync.result`: ordered missing messages, capped at 500 per conversation per request.
- `msg.edited`, `msg.deleted`, `msg.reactions`, `msg.pinned`, `msg.unpinned`, `poll.updated`.
- `report.review_started`, `report.review_resolved`, `report.resolved`.
- `service.created`, `service.claimed`, `service.status`, `service.result`,
  `service.cancelled`, `ticket.message`.
- `call.invite`, `call.accept`, `call.decline`, `call.end`: persisted call session state.
- `error`: stable `code` plus a safe `detail`.

Clients retry sends with the same `client_msg_id`. Events are ordered within one conversation by `seq`; ordering across conversations is intentionally undefined. Clients should reconnect with exponential backoff and send `sync` after reconnecting.

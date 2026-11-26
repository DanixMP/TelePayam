# University Messenger Backend

The API supports frontend Phases 0–7: verified identity, local-first chat sync, group/channel administration, rich-message mutations and polls, scoped moderation, service workflows, and persisted LiveKit call signaling.

FastAPI modular monolith implementing the identity, chat, moderation, service-ticket, media, sticker/GIF, realtime, and LiveKit authorization flows in `BACKEND_PLAN.md`.

## Local Development

```bash
python -m venv .venv
.venv/Scripts/pip install -e ".[dev]"
copy .env.example .env
alembic upgrade head
uvicorn app.main:app --reload
```

The default configuration uses SQLite, an in-process OTP/rate-limit store, and a console SMS provider. With `DEBUG=true`, `/api/v1/auth/otp/request` includes `development_code`. These development fallbacks are rejected or disabled in production.

Run PostgreSQL, Redis, the API, arq worker, and Nginx with:

```bash
docker compose up --build
```

The proxied API is at `http://localhost:8080`, the admin panel at `/admin/`, OpenAPI at `/docs`, and the WebSocket gateway at `/ws`.

## Bootstrap

Run `alembic upgrade head` from `backend/`. Migration `0003` makes **09981080891** (`+989981080891`) the sole super admin, preserving the existing account and review history. Sign in again with the SMS code after upgrading. Docker Compose applies the same migration to its own database.

Only the super admin can select **Add admin** in the messenger or web panel. Enter an unregistered mobile number to create an active ordinary admin. The server enforces this on `POST /api/v1/admin/admins` and audits who granted access. Both admin roles use SMS only; moderators still require TOTP.

## Review student registrations

1. Open [the FastAPI admin panel](http://localhost:8000/admin/) (port `8080` through Docker Compose).
2. Enter the admin mobile number, request an SMS code, and sign in with that code. The local console SMS provider prints the code in the backend terminal; with development debugging enabled, the form also displays it.
3. Under **Student requests**, review the name, university ID, program, and masked National ID, then select **Approve**. The account becomes active immediately. The decision records the reviewer and time and removes the registration from the queue.

Use **Refresh list** to see new submissions. The panel keeps its credentials in memory; reloading or closing the tab signs you out.

## Operations

Run `alembic upgrade head` to install the Campus Notes starter sticker pack and featured GIFs (revision `0004`). Its packaged assets are served through the authenticated media endpoints. Profile images must be owned image uploads; message attachment downloads require access to a referencing conversation or an explicitly saved/shared item. Forwarding checks access to both chats and copies the message content on the server.

- Development/test startup creates missing tables; production requires `alembic upgrade head` before startup.
- Set independent high-entropy `JWT_SECRET`, `DATA_HMAC_KEY`, and `DATA_ENCRYPTION_KEY` values in production.
- `DATA_ENCRYPTION_KEY` is a Fernet key. Generate one with `Fernet.generate_key()` and keep it outside the database.
- Message bodies, ticket messages, National IDs, report snapshots, and TOTP secrets are encrypted at rest.
- `/health` is process liveness; `/ready` checks the database.
- Multi-worker WebSocket fan-out uses Redis pub/sub. Offline push and media processing are arq extension points in `app/workers/settings.py`.

## Verification

```bash
ruff check app tests
pytest
```

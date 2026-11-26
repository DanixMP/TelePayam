# TelePayam (University Messenger)

University-verified messenger for students, professors, and staff. This repository is a monorepo containing a FastAPI backend and a Flutter client.

This README is the technical reference for contributors. Product and design context lives in [`PRODUCT.md`](PRODUCT.md), [`DESIGN.md`](DESIGN.md), [`BACKEND_PLAN.md`](BACKEND_PLAN.md), and [`FRONTEND_PLAN.md`](FRONTEND_PLAN.md). Component notes are in [`backend/README.md`](backend/README.md) and [`frontend/README.md`](frontend/README.md).

## Contents

- [Architecture](#architecture)
- [Repository layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Running the app](#running-the-app)
- [Configuration](#configuration)
- [Database and migrations](#database-and-migrations)
- [API and realtime](#api-and-realtime)
- [Audio and video calls](#audio-and-video-calls)
- [Testing and quality](#testing-and-quality)
- [Localization and code generation](#localization-and-code-generation)
- [Security notes](#security-notes)
- [Troubleshooting](#troubleshooting)

## Architecture

| Layer | Technology | Location |
| --- | --- | --- |
| REST API | FastAPI, SQLAlchemy 2 (async), Pydantic Settings | `backend/app` |
| Realtime gateway | WebSocket (`/ws`) with in-process or Redis pub/sub fan-out | `backend/app/modules/realtime` |
| Database | SQLite (local default) or PostgreSQL (Docker/production) via async drivers | `backend/app/db`, `backend/app/migrations` |
| Background jobs | arq worker (push and media processing extension points) | `backend/app/workers` |
| Admin panel | Static HTML/CSS/JS served by FastAPI | `backend/app/admin_panel` |
| Media | Local filesystem under `MEDIA_ROOT`, served through authenticated endpoints | `backend/app/modules/media` |
| Calls | LiveKit token issuance plus persisted call sessions | `backend/app/modules/calls` |
| Client | Flutter (web, Windows, Android), Riverpod, go_router, Dio | `frontend/lib` |
| Client storage | Drift/SQLite for app data, `flutter_secure_storage` for tokens | `frontend/lib/core/storage` |

The backend is a modular monolith. Each domain under `backend/app/modules` owns its router, models, and service logic. Shared infrastructure lives in `backend/app/core` (settings, security, policy, SMS, store, logging, errors).

### Backend modules

`auth`, `users`, `approvals`, `conversations`, `messages`, `search`, `reports`, `services`, `media`, `stickers`, `calls`, `realtime`.

### Frontend features

`auth`, `onboarding`, `registration`, `chats`, `communities`, `people`, `reports`, `services`, `calls`, `admin`. Shared code lives in `lib/core` (config, media, network, storage, utils, widgets), `lib/app` (app shell, router, providers, theme), and `lib/l10n` (English and Persian ARB files).

## Repository layout

```text
.
├── backend/
│   ├── app/
│   │   ├── admin_panel/        # Static admin UI at /admin/
│   │   ├── core/               # Config, security, policy, SMS, store
│   │   ├── db/                 # Async engine, session, base
│   │   ├── migrations/         # Alembic environment and revisions
│   │   ├── modules/            # Domain routers and services
│   │   ├── workers/            # arq worker settings
│   │   └── main.py             # FastAPI application factory
│   ├── docs/                   # WebSocket protocol reference
│   ├── tests/                  # pytest suite
│   ├── tools/                  # Utility scripts
│   ├── alembic.ini
│   ├── docker-compose.yml      # Postgres, Redis, API, worker, Nginx
│   ├── Dockerfile
│   └── pyproject.toml
├── frontend/
│   ├── android/                # Android host project
│   ├── assets/                 # Bundled media and sticker assets
│   ├── lib/                    # Dart application code
│   ├── test/                   # Flutter tests
│   ├── web/                    # Web host project
│   ├── windows/                # Windows host project
│   ├── l10n.yaml
│   └── pubspec.yaml
├── setup.ps1                   # Dedicated setup (Windows)
├── setup.sh                    # Dedicated setup (macOS/Linux)
├── Rub.bat                     # One-command run (Windows, local dev)
└── *.md                        # Product, design, and plan documents
```

## Prerequisites

- Python 3.11+ (the Docker image uses 3.12).
- Flutter with Dart SDK `^3.10.8` (see `frontend/pubspec.yaml`).
- Git.
- Optional: Docker with Compose for the PostgreSQL/Redis/Nginx stack.
- Optional: `livekit-server` for audio and video calls.
- Android builds need access to Google's Maven repository. Calls need camera and microphone permissions on device.

## Setup

Use the dedicated setup entry point for your platform. It is idempotent and never overwrites an existing `backend/.env` or `backend/.venv`.

### Windows (PowerShell)

```powershell
.\setup.ps1
```

### macOS / Linux

```bash
chmod +x setup.sh
./setup.sh
```

The script performs the following:

1. Verifies Python 3.11+ is available.
2. Creates `backend/.venv` if missing.
3. Installs the backend in editable mode with dev extras (`pip install -e ".[dev]"`).
4. Creates `backend/.env` with a SQLite database and freshly generated `JWT_SECRET`, `DATA_HMAC_KEY`, and `DATA_ENCRYPTION_KEY` values.
5. Applies Alembic migrations (`alembic upgrade head`).
6. Runs `flutter pub get` when Flutter is on `PATH`.

Optional flags:

```powershell
.\setup.ps1 -SkipFlutter -SkipMigrations
```

```bash
./setup.sh --skip-flutter --skip-migrations
```

### Manual setup

```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env          # Windows: copy .env.example .env
alembic upgrade head

cd ../frontend
flutter pub get
```

If you copy `.env.example` manually, the development defaults use SQLite and an in-process store. Keep `DATA_ENCRYPTION_KEY` empty in development; set a real Fernet key in production.

## Running the app

### Windows all-in-one

`Rub.bat` applies migrations, starts the backend with reload on `http://localhost:8000`, starts `livekit-server --dev` when available, and launches the Flutter web client on `http://localhost:3000`.

```powershell
.\Rub.bat
```

### Backend only

```powershell
cd backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

```bash
cd backend
.venv/bin/python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Useful endpoints:

| Endpoint | Purpose |
| --- | --- |
| `http://localhost:8000/docs` | OpenAPI/Swagger UI |
| `http://localhost:8000/openapi.json` | OpenAPI schema |
| `http://localhost:8000/health` | Process liveness |
| `http://localhost:8000/ready` | Database readiness |
| `http://localhost:8000/admin/` | Student registration admin panel |
| `ws://localhost:8000/ws?token=<access-token>` | WebSocket gateway |

### Frontend only

```powershell
cd frontend
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8000/api/v1
flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8000/api/v1
flutter run -d <android-device> --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

`DEMO_MODE=true` runs the client against deterministic local data. The demo OTP is `123456`; a phone ending in `99` follows the professor flow.

### Docker Compose

```bash
cd backend
docker compose up --build
```

| Service | Role | Host port |
| --- | --- | --- |
| `nginx` | Reverse proxy for the API, admin panel, and WebSocket | `8080` |
| `api` | FastAPI (4 workers, internal `8000`) | via `8080` |
| `migrate` | One-shot `alembic upgrade head` | — |
| `worker` | arq worker | — |
| `postgres` | PostgreSQL 16 | internal |
| `redis` | Redis 7 for pub/sub and shared state | internal |

With Compose, the API is at `http://localhost:8080`, the admin panel at `/admin/`, and the WebSocket at `/ws`.

## Configuration

Backend settings come from environment variables and `backend/.env` (`app/core/config.py`).

| Variable | Default | Notes |
| --- | --- | --- |
| `ENVIRONMENT` | `development` | `production` enables strict secret validation. |
| `DEBUG` | `false` | With `true`, OTP requests return `development_code`. |
| `DATABASE_URL` | `sqlite+aiosqlite:///./messenger.db` | `postgres://` and `postgresql://` are normalized to asyncpg. |
| `REDIS_URL` | empty | Empty uses the in-process store. Required in production. |
| `JWT_SECRET` | dev placeholder | Must be 32+ characters and must not contain `development-only` in production. |
| `JWT_ISSUER` | `university-messenger` | JWT `iss` claim. |
| `ACCESS_TOKEN_MINUTES` | `15` | Access token lifetime. |
| `REFRESH_TOKEN_DAYS` | `30` | Refresh token lifetime. |
| `DATA_ENCRYPTION_KEY` | empty | Fernet key. Empty derives a key from `JWT_SECRET` in development; required in production. |
| `DATA_HMAC_KEY` | dev placeholder | Keyed hashing for lookup values. |
| `SMS_PROVIDER` | `console` | Console provider prints OTP codes to the backend terminal. |
| `MEDIA_ROOT` | `var/media` | Upload and packaged asset storage. |
| `MAX_UPLOAD_BYTES` | `26214400` | 25 MiB upload limit. |
| `PUBLIC_BASE_URL` | `http://localhost:8000` | Absolute media URLs. |
| `LIVEKIT_URL` | `ws://localhost:7880` | LiveKit signaling URL. |
| `LIVEKIT_API_KEY` | `devkey` | LiveKit key. |
| `LIVEKIT_API_SECRET` | `secret` | LiveKit secret. |
| `CORS_ORIGINS` | `[]` | JSON list, for example `["http://localhost:3000"]`. |
| `OTP_TTL_SECONDS` | `120` | OTP lifetime. |
| `REPORT_GRANT_DAYS` | `7` | Moderator access window. |
| `REPORT_CONTEXT_MESSAGES` | `50` | Context messages captured with a report. |

Development and test startup create missing tables automatically. Production requires migrations before startup and enforces strong secrets, a Fernet key, and `REDIS_URL`.

Frontend build-time configuration uses `--dart-define`:

| Define | Purpose |
| --- | --- |
| `API_BASE_URL` | REST base ending in `/api/v1`; the WebSocket URL is derived from the same origin. |
| `DEMO_MODE` | `true` uses deterministic local identity and chat data. |

## Database and migrations

Alembic lives in `backend/app/migrations`. Run commands from `backend/`.

```bash
alembic upgrade head
alembic revision --autogenerate -m "describe change"
alembic downgrade -1
```

Current revisions:

| Revision | Purpose |
| --- | --- |
| `0001_initial_schema` | Core identity, conversation, message, and moderation schema. |
| `0002_client_phase_3_7` | Client phases 3–7 contracts. |
| `0003_super_admin` | Makes `09981080891` (`+989981080891`) the sole super admin. |
| `0004_campus_notes` | Seeds the Campus Notes sticker pack and featured GIFs. |

SQLite is the local default and requires no services. To use PostgreSQL, set `DATABASE_URL=postgresql+asyncpg://...` and run migrations against it, or use Docker Compose. Re-run `alembic upgrade head` after pulling changes.

The super admin is the only role that can create admins. Admins approve student registrations and sign in with SMS; moderators require TOTP.

## API and realtime

- REST routes are mounted under `/api/v1`.
- The WebSocket gateway is mounted at `/ws` and authenticated with `?token=<access-token>`.
- The frame protocol is documented in [`backend/docs/websocket-protocol.md`](backend/docs/websocket-protocol.md): JSON frames with `type` and `data`, sequence-ordered messages per conversation, idempotent sends via `client_msg_id`, and sync-on-reconnect.
- OTP request/verification lives in `app/modules/auth`. With `DEBUG=true`, the request response includes `development_code`; the console SMS provider also prints the code.
- Media downloads require access to a referencing conversation or an explicitly saved/shared item. Profile images must be owned uploads.

## Audio and video calls

Calls use LiveKit for media transport; the backend issues tokens and persists call session state. Start a local server:

```bash
livekit-server --dev --bind 127.0.0.1
```

Keep `LIVEKIT_URL`, `LIVEKIT_API_KEY`, and `LIVEKIT_API_SECRET` aligned between the server and backend. Group calls and native closed-app incoming-call presentation are post-v1 work.

## Testing and quality

Backend:

```bash
cd backend
.venv/Scripts/python.exe -m pytest          # Windows
.venv/bin/python -m pytest                  # macOS/Linux
.venv/Scripts/python.exe -m ruff check app tests
```

Frontend:

```bash
cd frontend
dart format lib test
flutter analyze
flutter test
flutter gen-l10n
dart run build_runner build --force-jit
flutter build windows --debug
flutter build apk --debug
flutter build web --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

`--force-jit` avoids a Dart build-hook conflict when generating Drift code with the current package set. Generated Drift code (`*.g.dart`) and localization output are committed; regenerate them after changing schemas or ARB files.

## Localization and code generation

- ARB files: `frontend/lib/l10n/app_en.arb` and `app_fa.arb`.
- Configuration: `frontend/l10n.yaml` (output in `lib/l10n/generated`).
- Run `flutter gen-l10n` after editing ARB files.
- Run `dart run build_runner build --force-jit` after changing Drift tables.

## Security notes

- Never commit `backend/.env`, database files, or media uploads. They are ignored by `.gitignore` files.
- Set independent high-entropy `JWT_SECRET`, `DATA_HMAC_KEY`, and `DATA_ENCRYPTION_KEY` values in production.
- `DATA_ENCRYPTION_KEY` must be a Fernet key; keep it outside the database.
- Message bodies, ticket messages, National IDs, report snapshots, and TOTP secrets are encrypted at rest.
- The setup scripts generate development-only secrets. Do not reuse them in production.
- `gh`/CI secrets and production credentials must be injected through the deployment environment, not the repository.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `alembic upgrade head` cannot connect | Check `DATABASE_URL` in `backend/.env`. Remove the PostgreSQL line to use SQLite, or start Postgres/Compose. |
| `InvalidToken` or Fernet errors | `DATA_ENCRYPTION_KEY` is malformed. Use a 44-character Fernet key or leave it empty in development. |
| CORS errors in the browser | Add the frontend origin to `CORS_ORIGINS`, for example `["http://localhost:3000"]`. |
| No SMS code in development | Look at the backend terminal (console provider), or read `development_code` from the OTP response with `DEBUG=true`. |
| Calls fail to connect | Start `livekit-server --dev` and verify the three `LIVEKIT_*` settings. |
| Flutter Drift codegen fails | Use `dart run build_runner build --force-jit`. |
| Android build cannot resolve artifacts | Ensure Google's Maven repository is reachable. |

#!/usr/bin/env bash
# One-command development setup for TelePayam (University Messenger).
#
# Creates the backend virtual environment, installs dependencies, generates a
# local backend/.env with strong development secrets, applies database
# migrations, and fetches Flutter packages. Safe to re-run: an existing
# backend/.env and .venv are preserved.
#
# Usage:
#   ./setup.sh                 # full setup
#   ./setup.sh --skip-flutter  # backend only
#   ./setup.sh --skip-migrations

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND="$ROOT/backend"
FRONTEND="$ROOT/frontend"
VENV="$BACKEND/.venv"
ENV_FILE="$BACKEND/.env"

SKIP_FLUTTER=0
SKIP_MIGRATIONS=0
for arg in "$@"; do
  case "$arg" in
    --skip-flutter) SKIP_FLUTTER=1 ;;
    --skip-migrations) SKIP_MIGRATIONS=1 ;;
    -h|--help)
      sed -n '2,12p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

step() { printf '\033[36m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[33mWARNING: %s\033[0m\n' "$1"; }
fail() { printf '\033[31mERROR: %s\033[0m\n' "$1" >&2; exit 1; }

echo
echo "TelePayam development setup"
echo

# Python 3.11+
if command -v python3 >/dev/null 2>&1; then
  PYTHON=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON=python
else
  fail "Python was not found on PATH. Install Python 3.11+ and re-run."
fi

PY_VERSION="$("$PYTHON" -c 'import sys; print("%d.%d" % sys.version_info[:2])')" \
  || fail "Unable to run Python. Install Python 3.11+ and re-run."

if [ "$(printf '%s\n' "3.11" "$PY_VERSION" | sort -V | head -n1)" != "3.11" ]; then
  fail "Python 3.11+ is required (found $PY_VERSION)."
fi
step "Python $PY_VERSION detected"

# Virtual environment
if [ ! -x "$VENV/bin/python" ]; then
  step "Creating backend virtual environment at backend/.venv"
  "$PYTHON" -m venv "$VENV" || fail "Failed to create the virtual environment."
else
  step "Reusing backend virtual environment"
fi
VENV_PY="$VENV/bin/python"

# Backend dependencies
step "Installing backend dependencies (editable, with dev extras)"
(
  cd "$BACKEND"
  "$VENV_PY" -m pip install --upgrade pip --disable-pip-version-check \
    || warn "Could not upgrade pip; continuing with the bundled version."
  "$VENV_PY" -m pip install -e ".[dev]" --disable-pip-version-check
) || fail "Failed to install backend dependencies. Check network/proxy access to PyPI."

# Local environment file
if [ ! -f "$ENV_FILE" ]; then
  step "Creating backend/.env with generated development secrets"
  JWT_SECRET="$("$VENV_PY" -c 'import secrets; print(secrets.token_urlsafe(48))')"
  DATA_HMAC_KEY="$("$VENV_PY" -c 'import secrets; print(secrets.token_urlsafe(48))')"
  DATA_ENCRYPTION_KEY="$("$VENV_PY" -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())')"
  cat > "$ENV_FILE" <<EOF
ENVIRONMENT=development
DEBUG=true
DATABASE_URL=sqlite+aiosqlite:///./messenger.db
REDIS_URL=
JWT_SECRET=$JWT_SECRET
DATA_ENCRYPTION_KEY=$DATA_ENCRYPTION_KEY
DATA_HMAC_KEY=$DATA_HMAC_KEY
SMS_PROVIDER=console
MEDIA_ROOT=./var/media
PUBLIC_BASE_URL=http://localhost:8000
LIVEKIT_URL=ws://localhost:7880
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
CORS_ORIGINS=["http://localhost:3000"]
EOF
  chmod 600 "$ENV_FILE" 2>/dev/null || true
else
  step "Keeping existing backend/.env"
fi

# Database migrations
if [ "$SKIP_MIGRATIONS" -eq 0 ]; then
  step "Applying database migrations"
  (cd "$BACKEND" && "$VENV_PY" -m alembic upgrade head) \
    || fail "Database migration failed."
else
  step "Skipping migrations (--skip-migrations)"
fi

# Flutter packages
if [ "$SKIP_FLUTTER" -eq 0 ]; then
  if command -v flutter >/dev/null 2>&1; then
    step "Fetching Flutter packages"
    (cd "$FRONTEND" && flutter pub get) || fail "flutter pub get failed."
  else
    warn "Flutter was not found on PATH. Install Flutter (Dart 3.10.8+) and run 'flutter pub get' in frontend/."
  fi
else
  step "Skipping Flutter packages (--skip-flutter)"
fi

if ! command -v livekit-server >/dev/null 2>&1; then
  warn "livekit-server was not found on PATH. Messaging works, but audio/video calls need LiveKit on ws://localhost:7880."
fi

cat <<'EOF'

Setup complete.

Run everything (Windows):   .\Rub.bat
Backend only:               cd backend && .venv/bin/python -m uvicorn app.main:app --reload
Frontend only:              cd frontend && flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8000/api/v1
API docs:                   http://localhost:8000/docs
Admin panel:                http://localhost:8000/admin/

EOF

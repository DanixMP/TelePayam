@echo off
setlocal

set "ROOT=%~dp0"
set "BACKEND=%ROOT%backend"
set "FRONTEND=%ROOT%frontend"
set "PYTHON=python"

if exist "%BACKEND%\.venv\Scripts\python.exe" set "PYTHON=%BACKEND%\.venv\Scripts\python.exe"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter was not found on PATH.
  exit /b 1
)

"%PYTHON%" --version >nul 2>nul
if errorlevel 1 (
  echo Python was not found. Create backend\.venv or add Python to PATH.
  exit /b 1
)

set "DEBUG=true"
set CORS_ORIGINS=["http://localhost:3000"]

echo Applying backend migrations...
pushd "%BACKEND%"
"%PYTHON%" -m alembic upgrade head
if errorlevel 1 (
  popd
  echo Backend migration failed.
  exit /b 1
)
popd

echo Starting backend at http://localhost:8000 ...
echo Student registration admin panel: http://localhost:8000/admin/
start "University Messenger Backend" /D "%BACKEND%" "%PYTHON%" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

where livekit-server >nul 2>nul
if not errorlevel 1 (
  echo Starting LiveKit in development mode at ws://localhost:7880 ...
  start "University Messenger LiveKit" livekit-server --dev --bind 127.0.0.1
) else (
  echo LiveKit server was not found on PATH. Messaging works, but calls need LiveKit on port 7880.
)

echo Starting Flutter frontend in Chrome at http://localhost:3000 ...
start "University Messenger Frontend" /D "%FRONTEND%" flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8000/api/v1

echo Backend and frontend launch commands were started in separate windows.
endlocal

#Requires -Version 5.1
<#
.SYNOPSIS
    One-command development setup for TelePayam (University Messenger).

.DESCRIPTION
    Creates the backend virtual environment, installs dependencies, generates a
    local backend/.env with strong development secrets, applies database
    migrations, and fetches Flutter packages. Safe to re-run: existing
    backend/.env and .venv are preserved.

.PARAMETER SkipFlutter
    Do not run "flutter pub get" in frontend/.

.PARAMETER SkipMigrations
    Do not apply Alembic migrations.

.EXAMPLE
    .\setup.ps1

.EXAMPLE
    .\setup.ps1 -SkipFlutter
#>
[CmdletBinding()]
param(
    [switch]$SkipFlutter,
    [switch]$SkipMigrations
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Backend = Join-Path $Root "backend"
$Frontend = Join-Path $Root "frontend"
$Venv = Join-Path $Backend ".venv"
$VenvPython = Join-Path $Venv "Scripts\python.exe"
$EnvFile = Join-Path $Backend ".env"

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Stop-Setup([string]$Message) {
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

function New-RandomSecret {
    param([int]$ByteCount = 48)
    $bytes = New-Object byte[] $ByteCount
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }
    return [Convert]::ToBase64String($bytes).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}

function New-FernetKey {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }
    return [Convert]::ToBase64String($bytes).Replace("+", "-").Replace("/", "_")
}

Write-Host ""
Write-Host "TelePayam development setup" -ForegroundColor White
Write-Host ""

# Python 3.11+
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Stop-Setup "Python was not found on PATH. Install Python 3.11+ and re-run."
}

$pythonVersion = & python -c "import sys; print('%d.%d' % sys.version_info[:2])"
if ($LASTEXITCODE -ne 0) {
    Stop-Setup "Unable to run Python. Install Python 3.11+ and re-run."
}
if ([version]$pythonVersion -lt [version]"3.11") {
    Stop-Setup "Python 3.11+ is required (found $pythonVersion)."
}
Write-Step "Python $pythonVersion detected"

# Virtual environment
if (-not (Test-Path -LiteralPath $VenvPython)) {
    Write-Step "Creating backend virtual environment at backend\.venv"
    & python -m venv $Venv
    if ($LASTEXITCODE -ne 0) {
        Stop-Setup "Failed to create the virtual environment."
    }
} else {
    Write-Step "Reusing backend virtual environment"
}

# Backend dependencies
Write-Step "Installing backend dependencies (editable, with dev extras)"
Push-Location $Backend
try {
    & $VenvPython -m pip install --upgrade pip --disable-pip-version-check
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: Could not upgrade pip; continuing with the bundled version." -ForegroundColor Yellow
    }
    & $VenvPython -m pip install -e ".[dev]"
    if ($LASTEXITCODE -ne 0) {
        Stop-Setup "Failed to install backend dependencies. Check network/proxy access to PyPI."
    }
} finally {
    Pop-Location
}

# Local environment file
if (-not (Test-Path -LiteralPath $EnvFile)) {
    Write-Step "Creating backend\.env with generated development secrets"
    $envLines = @(
        "ENVIRONMENT=development",
        "DEBUG=true",
        "DATABASE_URL=sqlite+aiosqlite:///./messenger.db",
        "REDIS_URL=",
        "JWT_SECRET=$(New-RandomSecret)",
        "DATA_ENCRYPTION_KEY=$(New-FernetKey)",
        "DATA_HMAC_KEY=$(New-RandomSecret)",
        "SMS_PROVIDER=console",
        "MEDIA_ROOT=./var/media",
        "PUBLIC_BASE_URL=http://localhost:8000",
        "LIVEKIT_URL=ws://localhost:7880",
        "LIVEKIT_API_KEY=devkey",
        "LIVEKIT_API_SECRET=secret",
        'CORS_ORIGINS=["http://localhost:3000"]'
    )
    Set-Content -LiteralPath $EnvFile -Value $envLines -Encoding ASCII
} else {
    Write-Step "Keeping existing backend\.env"
}

# Database migrations
if (-not $SkipMigrations) {
    Write-Step "Applying database migrations"
    Push-Location $Backend
    try {
        & $VenvPython -m alembic upgrade head
        if ($LASTEXITCODE -ne 0) {
            Stop-Setup "Database migration failed."
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Step "Skipping migrations (-SkipMigrations)"
}

# Flutter packages
if (-not $SkipFlutter) {
    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if ($flutter) {
        Write-Step "Fetching Flutter packages"
        Push-Location $Frontend
        try {
            & flutter pub get
            if ($LASTEXITCODE -ne 0) {
                Stop-Setup "flutter pub get failed."
            }
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "WARNING: Flutter was not found on PATH. Install Flutter (Dart 3.10.8+) and run 'flutter pub get' in frontend\." -ForegroundColor Yellow
    }
} else {
    Write-Step "Skipping Flutter packages (-SkipFlutter)"
}

if (-not (Get-Command livekit-server -ErrorAction SilentlyContinue)) {
    Write-Host "NOTE: livekit-server was not found on PATH. Messaging works, but audio/video calls need LiveKit on ws://localhost:7880." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setup complete." -ForegroundColor Green
Write-Host ""
Write-Host "Run everything (Windows):   .\Rub.bat"
Write-Host "Backend only:               cd backend; .\.venv\Scripts\python.exe -m uvicorn app.main:app --reload"
Write-Host "Frontend only:              cd frontend; flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8000/api/v1"
Write-Host "API docs:                   http://localhost:8000/docs"
Write-Host "Admin panel:                http://localhost:8000/admin/"
Write-Host ""

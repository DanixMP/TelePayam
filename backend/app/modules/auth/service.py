import hashlib
from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pyotp
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.enums import AccountStatus, UserRole
from app.core.errors import AppError
from app.core.security import (
    create_access_token,
    decrypt_text,
    hash_otp,
    normalize_phone,
    opaque_token,
    otp_matches,
    random_otp,
    utcnow,
)
from app.core.sms import SmsProvider
from app.core.store import KeyValueStore
from app.db.models import Device, ProfessorInvite, RefreshToken, User


def token_digest(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


async def request_otp(
    phone_input: str,
    ip: str,
    store: KeyValueStore,
    sms: SmsProvider,
    settings: Settings,
) -> tuple[str, str]:
    try:
        phone = normalize_phone(phone_input)
    except ValueError as exc:
        raise AppError(422, "invalid_phone", str(exc)) from exc
    if await store.increment(f"otp-rate:phone:{phone}", 600) > 3:
        raise AppError(429, "otp_rate_limited", "Too many codes requested for this phone")
    if await store.increment(f"otp-rate:ip:{ip}", 3600) > 10:
        raise AppError(429, "otp_rate_limited", "Too many codes requested from this address")
    code = random_otp()
    await store.set(f"otp:{phone}", hash_otp(phone, code, settings), settings.otp_ttl_seconds)
    await store.delete(f"otp-wrong:{phone}")
    await sms.send_otp(phone, code)
    return phone, code


async def verify_otp(
    db: AsyncSession,
    phone_input: str,
    code: str,
    platform: str,
    device_name: str | None,
    fcm_token: str | None,
    totp_code: str | None,
    store: KeyValueStore,
    settings: Settings,
) -> tuple[str, str, User]:
    try:
        phone = normalize_phone(phone_input)
    except ValueError as exc:
        raise AppError(422, "invalid_phone", str(exc)) from exc
    expected = await store.get(f"otp:{phone}")
    if not expected:
        raise AppError(400, "otp_expired", "The code is invalid or expired")
    if not otp_matches(phone, code, expected, settings):
        wrong = await store.increment(f"otp-wrong:{phone}", settings.otp_ttl_seconds)
        if wrong >= 5:
            await store.delete(f"otp:{phone}")
            raise AppError(429, "otp_locked", "Too many incorrect attempts")
        raise AppError(400, "otp_invalid", "The code is invalid or expired")
    await store.delete(f"otp:{phone}")

    user = await db.scalar(select(User).where(User.phone == phone))
    if not user:
        invite = await db.scalar(
            select(ProfessorInvite)
            .where(ProfessorInvite.phone == phone, ProfessorInvite.used_at.is_(None))
            .order_by(ProfessorInvite.created_at.desc())
        )
        if invite:
            user = User(
                phone=phone,
                role=UserRole.PROFESSOR.value,
                status=AccountStatus.PENDING_PROFILE.value,
                first_name=invite.first_name,
                last_name=invite.last_name,
            )
            invite.used_at = utcnow()
        else:
            user = User(phone=phone)
        db.add(user)
        await db.flush()
    if user.status in {AccountStatus.BANNED.value, AccountStatus.SUSPENDED.value}:
        raise AppError(403, "account_blocked", f"Account is {user.status}")
    if user.role == UserRole.MODERATOR.value:
        if not user.totp_enabled or not user.totp_secret_enc:
            raise AppError(403, "totp_setup_required", "Privileged account TOTP is not configured")
        secret = decrypt_text(user.totp_secret_enc, settings)
        if not totp_code or not pyotp.TOTP(secret).verify(totp_code, valid_window=1):
            raise AppError(401, "totp_invalid", "A valid authenticator code is required")

    now = utcnow()
    device = None
    if fcm_token:
        device = await db.scalar(
            select(Device).where(Device.user_id == user.id, Device.fcm_token == fcm_token)
        )
    if device:
        device.platform = platform
        device.name = device_name
        device.last_seen = now
        device.revoked_at = None
    else:
        db.add(
            Device(
                user_id=user.id,
                platform=platform,
                name=device_name,
                fcm_token=fcm_token,
                last_seen=now,
            )
        )
    refresh, _ = await issue_refresh_token(db, user, settings)
    access = create_access_token(user.id, user.role, settings)
    await db.commit()
    return access, refresh, user


async def issue_refresh_token(
    db: AsyncSession,
    user: User,
    settings: Settings,
    family_id: UUID | None = None,
) -> tuple[str, RefreshToken]:
    plain = opaque_token()
    model = RefreshToken(
        user_id=user.id,
        family_id=family_id or uuid4(),
        token_hash=token_digest(plain),
        expires_at=utcnow() + timedelta(days=settings.refresh_token_days),
        created_at=utcnow(),
    )
    db.add(model)
    await db.flush()
    return plain, model


def _aware(value: datetime) -> datetime:
    return value if value.tzinfo else value.replace(tzinfo=UTC)


async def rotate_refresh_token(
    db: AsyncSession, plain: str, settings: Settings
) -> tuple[str, str, User]:
    current = await db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == token_digest(plain))
    )
    if not current:
        raise AppError(401, "invalid_refresh_token", "Refresh token is invalid")
    if current.revoked_at:
        await db.execute(
            update(RefreshToken)
            .where(RefreshToken.family_id == current.family_id)
            .values(revoked_at=utcnow())
        )
        await db.commit()
        raise AppError(401, "refresh_reuse_detected", "The token family has been revoked")
    if _aware(current.expires_at) <= utcnow():
        raise AppError(401, "refresh_expired", "Refresh token has expired")
    user = await db.get(User, current.user_id)
    if not user or user.status in {AccountStatus.BANNED.value, AccountStatus.SUSPENDED.value}:
        raise AppError(401, "invalid_refresh_token", "Account is unavailable")
    replacement_plain, replacement = await issue_refresh_token(
        db, user, settings, current.family_id
    )
    current.revoked_at = utcnow()
    current.replaced_by_id = replacement.id
    access = create_access_token(user.id, user.role, settings)
    await db.commit()
    return access, replacement_plain, user


async def revoke_refresh_token(db: AsyncSession, plain: str, user: User) -> None:
    token = await db.scalar(
        select(RefreshToken).where(
            RefreshToken.token_hash == token_digest(plain), RefreshToken.user_id == user.id
        )
    )
    if token and not token.revoked_at:
        token.revoked_at = utcnow()
        await db.commit()

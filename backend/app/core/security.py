import base64
import hashlib
import hmac
import os
import re
import secrets
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
from argon2 import PasswordHasher
from cryptography.fernet import Fernet, InvalidToken

from app.core.config import Settings

password_hasher = PasswordHasher()


def utcnow() -> datetime:
    return datetime.now(UTC)


def normalize_phone(phone: str) -> str:
    digits = re.sub(r"\D", "", phone)
    if digits.startswith("0098"):
        digits = digits[4:]
    elif digits.startswith("98"):
        digits = digits[2:]
    elif digits.startswith("0"):
        digits = digits[1:]
    if len(digits) != 10 or not digits.startswith("9"):
        raise ValueError("A valid Iranian mobile number is required")
    return "+98" + digits


def valid_iranian_national_id(value: str) -> bool:
    if not re.fullmatch(r"\d{10}", value) or len(set(value)) == 1:
        return False
    check = int(value[-1])
    remainder = sum(int(value[i]) * (10 - i) for i in range(9)) % 11
    expected = remainder if remainder < 2 else 11 - remainder
    return check == expected


def _fernet(settings: Settings) -> Fernet:
    if settings.data_encryption_key:
        key = settings.data_encryption_key.encode()
    else:
        digest = hashlib.sha256(settings.jwt_secret.encode()).digest()
        key = base64.urlsafe_b64encode(digest)
    return Fernet(key)


def encrypt_text(value: str, settings: Settings) -> str:
    return _fernet(settings).encrypt(value.encode()).decode()


def decrypt_text(value: str, settings: Settings) -> str:
    try:
        return _fernet(settings).decrypt(value.encode()).decode()
    except InvalidToken as exc:
        raise ValueError("Encrypted data cannot be decrypted with the configured key") from exc


def keyed_hash(value: str, settings: Settings) -> str:
    return hmac.new(settings.data_hmac_key.encode(), value.encode(), hashlib.sha256).hexdigest()


def hash_secret(value: str) -> str:
    return password_hasher.hash(value)


def verify_secret(value: str, encoded: str) -> bool:
    try:
        return password_hasher.verify(encoded, value)
    except Exception:
        return False


def opaque_token() -> str:
    return secrets.token_urlsafe(48)


def create_access_token(user_id: uuid.UUID, role: str, settings: Settings) -> str:
    now = utcnow()
    payload = {
        "sub": str(user_id),
        "role": role,
        "type": "access",
        "iat": now,
        "exp": now + timedelta(minutes=settings.access_token_minutes),
        "iss": settings.jwt_issuer,
        "jti": str(uuid.uuid4()),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")


def decode_access_token(token: str, settings: Settings) -> dict[str, Any]:
    return jwt.decode(
        token,
        settings.jwt_secret,
        algorithms=["HS256"],
        issuer=settings.jwt_issuer,
    )


def random_otp() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def hash_otp(phone: str, code: str, settings: Settings) -> str:
    return hmac.new(
        settings.data_hmac_key.encode(), f"{phone}:{code}".encode(), hashlib.sha256
    ).hexdigest()


def otp_matches(phone: str, code: str, expected: str, settings: Settings) -> bool:
    return hmac.compare_digest(hash_otp(phone, code, settings), expected)


def generate_verification_code() -> str:
    return base64.urlsafe_b64encode(os.urandom(18)).decode().rstrip("=")

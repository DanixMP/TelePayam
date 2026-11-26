from app.core.config import get_settings
from app.core.security import (
    decrypt_text,
    encrypt_text,
    normalize_phone,
    valid_iranian_national_id,
)


def test_iranian_national_id_checksum():
    assert valid_iranian_national_id("0084575948")
    assert not valid_iranian_national_id("0084575949")
    assert not valid_iranian_national_id("1111111111")


def test_phone_normalization():
    assert normalize_phone("0912 123 4567") == "+989121234567"
    assert normalize_phone("+98 912 123 4567") == "+989121234567"


def test_encryption_round_trip_does_not_contain_plaintext():
    settings = get_settings()
    encrypted = encrypt_text("private message", settings)
    assert "private message" not in encrypted
    assert decrypt_text(encrypted, settings) == "private message"

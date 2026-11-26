import logging
from typing import Protocol

logger = logging.getLogger(__name__)


class SmsProvider(Protocol):
    async def send_otp(self, phone: str, code: str) -> None: ...


class ConsoleSmsProvider:
    async def send_otp(self, phone: str, code: str) -> None:
        logger.warning("Development OTP for %s: %s", phone, code)


def get_sms_provider() -> SmsProvider:
    # Provider-specific credentials and HTTP clients stay behind this interface.
    return ConsoleSmsProvider()

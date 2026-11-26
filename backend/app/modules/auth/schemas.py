from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.modules.common import ORMModel, UserSelf


class OtpRequest(BaseModel):
    phone: str


class OtpRequested(BaseModel):
    retry_after: int = 120
    development_code: str | None = None


class OtpVerify(BaseModel):
    phone: str
    code: str = Field(min_length=6, max_length=6)
    platform: str = Field(default="unknown", max_length=30)
    device_name: str | None = Field(default=None, max_length=100)
    fcm_token: str | None = Field(default=None, max_length=500)
    totp_code: str | None = Field(default=None, min_length=6, max_length=6)


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserSelf


class DeviceOut(ORMModel):
    id: UUID
    platform: str
    name: str | None
    last_seen: datetime | None
    created_at: datetime

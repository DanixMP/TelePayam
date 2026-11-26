from functools import lru_cache
from pathlib import Path

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "University Messenger"
    environment: str = "development"
    debug: bool = False
    database_url: str = "sqlite+aiosqlite:///./messenger.db"
    redis_url: str | None = None
    jwt_secret: str = "development-only-jwt-secret-change-me"
    jwt_issuer: str = "university-messenger"
    access_token_minutes: int = 15
    refresh_token_days: int = 30
    data_encryption_key: str = ""
    data_hmac_key: str = "development-only-hmac-key-change-me"
    sms_provider: str = "console"
    media_root: Path = Path("var/media")
    max_upload_bytes: int = 25 * 1024 * 1024
    public_base_url: str = "http://localhost:8000"
    livekit_url: str = "ws://localhost:7880"
    livekit_api_key: str = "devkey"
    livekit_api_secret: str = "secret"
    cors_origins: list[str] = Field(default_factory=list)
    otp_ttl_seconds: int = 120
    report_grant_days: int = 7
    report_context_messages: int = 50

    @field_validator("database_url")
    @classmethod
    def normalize_postgres_scheme(cls, value: str) -> str:
        if value.startswith("postgres://"):
            return value.replace("postgres://", "postgresql+asyncpg://", 1)
        if value.startswith("postgresql://"):
            return value.replace("postgresql://", "postgresql+asyncpg://", 1)
        return value

    @model_validator(mode="after")
    def reject_development_secrets_in_production(self) -> "Settings":
        if self.environment == "production":
            if "development-only" in self.jwt_secret or len(self.jwt_secret) < 32:
                raise ValueError("JWT_SECRET must be a strong production secret")
            if not self.data_encryption_key:
                raise ValueError("DATA_ENCRYPTION_KEY is required in production")
            if not self.redis_url:
                raise ValueError("REDIS_URL is required in production")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Request, Response
from sqlalchemy import select

from app.core.config import Settings, get_settings
from app.core.deps import CurrentUser, Db
from app.core.errors import AppError
from app.core.sms import SmsProvider, get_sms_provider
from app.core.store import KeyValueStore, get_store
from app.db.models import Device
from app.modules.auth import service
from app.modules.auth.schemas import (
    DeviceOut,
    OtpRequest,
    OtpRequested,
    OtpVerify,
    RefreshRequest,
    TokenPair,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/otp/request", response_model=OtpRequested, status_code=202)
async def otp_request(
    payload: OtpRequest,
    request: Request,
    settings: Annotated[Settings, Depends(get_settings)],
    store: Annotated[KeyValueStore, Depends(get_store)],
    sms: Annotated[SmsProvider, Depends(get_sms_provider)],
) -> OtpRequested:
    ip = request.client.host if request.client else "unknown"
    _, code = await service.request_otp(payload.phone, ip, store, sms, settings)
    return OtpRequested(
        retry_after=settings.otp_ttl_seconds,
        development_code=code if settings.debug and settings.environment != "production" else None,
    )


@router.post("/otp/verify", response_model=TokenPair)
async def otp_verify(
    payload: OtpVerify,
    db: Db,
    settings: Annotated[Settings, Depends(get_settings)],
    store: Annotated[KeyValueStore, Depends(get_store)],
) -> TokenPair:
    access, refresh, user = await service.verify_otp(
        db,
        payload.phone,
        payload.code,
        payload.platform,
        payload.device_name,
        payload.fcm_token,
        payload.totp_code,
        store,
        settings,
    )
    return TokenPair(
        access_token=access,
        refresh_token=refresh,
        expires_in=settings.access_token_minutes * 60,
        user=user,
    )


@router.post("/refresh", response_model=TokenPair)
async def refresh(
    payload: RefreshRequest,
    db: Db,
    settings: Annotated[Settings, Depends(get_settings)],
) -> TokenPair:
    access, refresh_token, user = await service.rotate_refresh_token(
        db, payload.refresh_token, settings
    )
    return TokenPair(
        access_token=access,
        refresh_token=refresh_token,
        expires_in=settings.access_token_minutes * 60,
        user=user,
    )


@router.post("/logout", status_code=204)
async def logout(payload: RefreshRequest, db: Db, user: CurrentUser) -> Response:
    await service.revoke_refresh_token(db, payload.refresh_token, user)
    return Response(status_code=204)


@router.get("/devices", response_model=list[DeviceOut])
async def devices(db: Db, user: CurrentUser) -> list[Device]:
    return list(
        await db.scalars(
            select(Device).where(Device.user_id == user.id, Device.revoked_at.is_(None))
        )
    )


@router.delete("/devices/{device_id}", status_code=204)
async def terminate_device(device_id: UUID, db: Db, user: CurrentUser) -> Response:
    device = await db.get(Device, device_id)
    if not device or device.user_id != user.id:
        raise AppError(404, "device_not_found", "Device was not found")
    from app.core.security import utcnow

    device.revoked_at = utcnow()
    await db.commit()
    return Response(status_code=204)

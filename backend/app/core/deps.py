from typing import Annotated
from uuid import UUID

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.core.enums import SUPER_ADMIN_PHONE, AccountStatus, UserRole
from app.core.errors import AppError
from app.core.security import decode_access_token
from app.db.models import User
from app.db.session import get_db

bearer = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
    db: Annotated[AsyncSession, Depends(get_db)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> User:
    if credentials is None:
        raise AppError(401, "not_authenticated", "Authentication is required")
    try:
        payload = decode_access_token(credentials.credentials, settings)
        if payload.get("type") != "access":
            raise ValueError
        user_id = UUID(payload["sub"])
    except Exception as exc:
        raise AppError(401, "invalid_token", "Access token is invalid or expired") from exc
    user = await db.get(User, user_id)
    if not user:
        raise AppError(401, "invalid_token", "The account no longer exists")
    if payload.get("role") != user.role:
        raise AppError(401, "invalid_token", "Account permissions changed. Sign in again.")
    if user.status in {AccountStatus.BANNED.value, AccountStatus.SUSPENDED.value}:
        raise AppError(403, "account_blocked", f"Account is {user.status}")
    return user


async def get_active_user(user: Annotated[User, Depends(get_current_user)]) -> User:
    if user.status != AccountStatus.ACTIVE.value:
        raise AppError(403, "account_not_active", "Account approval is required")
    return user


def require_roles(*roles: UserRole):
    allowed = {role.value for role in roles}

    async def dependency(user: Annotated[User, Depends(get_active_user)]) -> User:
        if user.role not in allowed:
            raise AppError(403, "forbidden", "This role cannot perform the action")
        return user

    return dependency


Db = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]
ActiveUser = Annotated[User, Depends(get_active_user)]
AdminUser = Annotated[User, Depends(require_roles(UserRole.ADMIN, UserRole.SUPER_ADMIN))]


async def require_super_admin(user: AdminUser) -> User:
    if user.role != UserRole.SUPER_ADMIN or user.phone != SUPER_ADMIN_PHONE:
        raise AppError(403, "super_admin_required", "Only the super admin can add administrators")
    return user


SuperAdminUser = Annotated[User, Depends(require_super_admin)]

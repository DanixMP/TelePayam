from typing import Annotated
from uuid import UUID

import pyotp
from fastapi import APIRouter, Depends, Request
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError

from app.core.config import Settings, get_settings
from app.core.deps import AdminUser, Db, SuperAdminUser
from app.core.enums import SUPER_ADMIN_PHONE, AccountStatus, UserRole
from app.core.errors import AppError
from app.core.security import decrypt_text, encrypt_text, normalize_phone, utcnow
from app.db.models import AuditLog, ProfessorInvite, StaffProfile, StudentProfile, User
from app.modules.approvals.schemas import (
    AdminCreate,
    ApprovalDecision,
    ApprovalItem,
    ModeratorCreate,
    PrivilegedAccountCreated,
    ProfessorInviteCreate,
    StaffCreate,
)
from app.modules.common import UserSelf

router = APIRouter(prefix="/admin", tags=["admin"])


def audit(actor: User, action: str, target: str, request: Request, context: dict | None = None):
    return AuditLog(
        actor_id=actor.id,
        action=action,
        target=target,
        context=context or {},
        ip=request.client.host if request.client else None,
        created_at=utcnow(),
    )


@router.get("/approvals", response_model=list[ApprovalItem])
async def approvals(db: Db, _: AdminUser):
    rows = (
        await db.execute(
            select(User, StudentProfile)
            .join(StudentProfile, StudentProfile.user_id == User.id)
            .where(
                User.role == UserRole.STUDENT.value,
                User.status == AccountStatus.PENDING_APPROVAL.value,
            )
            .order_by(StudentProfile.updated_at, User.id)
        )
    ).all()
    return [
        ApprovalItem(
            **UserSelf.model_validate(user).model_dump(),
            degree=profile.degree,
            department=profile.department,
            university_id=profile.university_id,
            national_id_masked=f"******{profile.national_id_last4}",
        )
        for user, profile in rows
    ]


@router.post("/approvals/{user_id}", response_model=UserSelf)
async def decide_approval(
    user_id: UUID,
    payload: ApprovalDecision,
    request: Request,
    db: Db,
    admin: AdminUser,
):
    if payload.action != "approve" and not payload.reason:
        raise AppError(422, "reason_required", "A reason is required")
    status = {
        "approve": AccountStatus.ACTIVE,
        "reject": AccountStatus.REJECTED,
        "request_correction": AccountStatus.PENDING_PROFILE,
    }[payload.action]
    # Claim the pending registration once, even when two admins review the same row.
    user = await db.scalar(
        update(User)
        .where(
            User.id == user_id,
            User.role == UserRole.STUDENT.value,
            User.status == AccountStatus.PENDING_APPROVAL.value,
            User.student_profile.has(),
        )
        .values(
            status=status.value,
            correction_note=payload.reason if payload.action == "request_correction" else None,
        )
        .returning(User)
    )
    if user is None:
        raise AppError(404, "approval_not_found", "Pending approval was not found")
    profile = await db.get(StudentProfile, user_id)
    profile.reject_reason = payload.reason if payload.action == "reject" else None
    profile.reviewed_by = admin.id
    profile.reviewed_at = utcnow()
    db.add(audit(admin, f"student.{payload.action}", str(user.id), request))
    await db.commit()
    await db.refresh(user)
    return user


@router.post("/admins", response_model=UserSelf, status_code=201)
async def create_admin(payload: AdminCreate, request: Request, db: Db, actor: SuperAdminUser):
    try:
        phone = normalize_phone(payload.phone)
    except ValueError as exc:
        raise AppError(422, "invalid_phone", str(exc)) from exc
    if phone == SUPER_ADMIN_PHONE or await db.scalar(select(User.id).where(User.phone == phone)):
        raise AppError(409, "phone_exists", "Phone is already registered")
    user = User(phone=phone, role=UserRole.ADMIN.value, status=AccountStatus.ACTIVE.value)
    db.add(user)
    try:
        await db.flush()
    except IntegrityError as exc:
        await db.rollback()
        if await db.scalar(select(User.id).where(User.phone == phone)):
            raise AppError(409, "phone_exists", "Phone is already registered") from exc
        raise
    db.add(audit(actor, "admin.create", str(user.id), request))
    await db.commit()
    return user


@router.post("/professor-invites", status_code=201)
async def create_professor_invite(
    payload: ProfessorInviteCreate, request: Request, db: Db, admin: AdminUser
):
    try:
        phone = normalize_phone(payload.phone)
    except ValueError as exc:
        raise AppError(422, "invalid_phone", str(exc)) from exc
    invite = ProfessorInvite(
        phone=phone,
        first_name=payload.first_name,
        last_name=payload.last_name,
        department=payload.department,
        title=payload.title,
        created_by=admin.id,
    )
    db.add(invite)
    db.add(audit(admin, "professor.invite", phone, request))
    await db.commit()
    return {"id": str(invite.id), "phone": phone}


@router.post("/staff", response_model=UserSelf, status_code=201)
async def create_staff(payload: StaffCreate, request: Request, db: Db, admin: AdminUser):
    try:
        phone = normalize_phone(payload.phone)
    except ValueError as exc:
        raise AppError(422, "invalid_phone", str(exc)) from exc
    if await db.scalar(select(User).where(User.phone == phone)):
        raise AppError(409, "phone_exists", "Phone is already registered")
    user = User(
        phone=phone,
        role=UserRole.STAFF.value,
        status=AccountStatus.ACTIVE.value,
        first_name=payload.first_name,
        last_name=payload.last_name,
    )
    db.add(user)
    await db.flush()
    db.add(StaffProfile(user_id=user.id, department=payload.department, permissions={}))
    db.add(audit(admin, "staff.create", str(user.id), request))
    await db.commit()
    await db.refresh(user)
    return user


@router.post("/moderators", response_model=PrivilegedAccountCreated, status_code=201)
async def create_moderator(
    payload: ModeratorCreate,
    request: Request,
    db: Db,
    admin: AdminUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    try:
        phone = normalize_phone(payload.phone)
    except ValueError as exc:
        raise AppError(422, "invalid_phone", str(exc)) from exc
    if await db.scalar(select(User).where(User.phone == phone)):
        raise AppError(409, "phone_exists", "Phone is already registered")
    secret = pyotp.random_base32()
    user = User(
        phone=phone,
        role=UserRole.MODERATOR.value,
        status=AccountStatus.ACTIVE.value,
        first_name=payload.first_name,
        last_name=payload.last_name,
        totp_enabled=True,
        totp_secret_enc=encrypt_text(secret, settings),
    )
    db.add(user)
    await db.flush()
    db.add(audit(admin, "moderator.create", str(user.id), request))
    await db.commit()
    await db.refresh(user)
    return PrivilegedAccountCreated(user=UserSelf.model_validate(user), totp_secret=secret)


@router.get("/users/{user_id}/national-id")
async def view_national_id(
    user_id: UUID,
    request: Request,
    db: Db,
    admin: AdminUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    profile = await db.get(StudentProfile, user_id)
    if not profile:
        raise AppError(404, "student_profile_not_found", "Student profile was not found")
    db.add(audit(admin, "student.national_id_viewed", str(user_id), request))
    await db.commit()
    return {"user_id": str(user_id), "national_id": decrypt_text(profile.national_id_enc, settings)}


@router.get("/audit")
async def audit_log(db: Db, _: AdminUser, limit: int = 100):
    limit = min(max(limit, 1), 500)
    logs = list(
        await db.scalars(select(AuditLog).order_by(AuditLog.created_at.desc()).limit(limit))
    )
    return [
        {
            "id": str(item.id),
            "actor_id": str(item.actor_id) if item.actor_id else None,
            "action": item.action,
            "target": item.target,
            "context": item.context,
            "created_at": item.created_at,
        }
        for item in logs
    ]

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.enums import AccountStatus, ConversationType, MemberRole, UserRole, Visibility
from app.core.errors import AppError
from app.core.handles import handle_policy
from app.core.security import encrypt_text, keyed_hash, utcnow
from app.db.models import (
    Conversation,
    ConversationMember,
    ProfessorInvite,
    ProfessorProfile,
    StudentProfile,
    User,
)
from app.modules.users.schemas import ProfessorCompletion, StudentRegistration


async def available_handle(db: AsyncSession, user: User, suffix: str = "") -> str:
    base = handle_policy.generate(user)
    if suffix:
        base = f"{base[: 31 - len(suffix)]}_{suffix}"
    candidate = base
    number = 1
    while await db.scalar(
        select(User.id)
        .where(User.handle == candidate)
        .union(select(Conversation.id).where(Conversation.handle == candidate))
    ):
        number += 1
        ending = f"_{number}"
        candidate = base[: 32 - len(ending)] + ending
    return candidate


async def register_student(
    db: AsyncSession, user: User, payload: StudentRegistration, settings: Settings
) -> User:
    if user.role != UserRole.STUDENT.value:
        raise AppError(403, "wrong_registration_flow", "Use the professor registration flow")
    if user.status not in {
        AccountStatus.PENDING_PROFILE.value,
        AccountStatus.REJECTED.value,
    }:
        raise AppError(409, "profile_already_submitted", "The profile cannot be changed now")
    national_hash = keyed_hash(payload.national_id, settings)
    duplicate = await db.scalar(
        select(StudentProfile).where(
            or_(
                StudentProfile.national_id_hash == national_hash,
                StudentProfile.university_id == payload.university_id,
            ),
            StudentProfile.user_id != user.id,
        )
    )
    if duplicate:
        raise AppError(409, "student_identity_exists", "Student identity is already registered")
    user.first_name = payload.first_name.strip()
    user.last_name = payload.last_name.strip()
    user.handle = user.handle or await available_handle(db, user)
    user.status = AccountStatus.PENDING_APPROVAL.value
    user.correction_note = None
    profile = await db.get(StudentProfile, user.id)
    if not profile:
        profile = StudentProfile(
            user_id=user.id,
            national_id_enc="",
            national_id_hash="",
            national_id_last4="",
            degree="",
            department="",
            university_id=payload.university_id,
        )
        db.add(profile)
    profile.national_id_enc = encrypt_text(payload.national_id, settings)
    profile.national_id_hash = national_hash
    profile.national_id_last4 = payload.national_id[-4:]
    profile.degree = payload.degree
    profile.department = payload.department.strip()
    profile.university_id = payload.university_id.strip()
    profile.reject_reason = None
    await db.commit()
    await db.refresh(user)
    return user


async def complete_professor(
    db: AsyncSession, user: User, payload: ProfessorCompletion
) -> tuple[User, Conversation]:
    if user.role != UserRole.PROFESSOR.value:
        raise AppError(403, "wrong_registration_flow", "Use the student registration flow")
    if user.status != AccountStatus.PENDING_PROFILE.value:
        raise AppError(409, "profile_already_submitted", "The profile has already been completed")
    invite = await db.scalar(
        select(ProfessorInvite)
        .where(ProfessorInvite.phone == user.phone, ProfessorInvite.used_at.is_not(None))
        .order_by(ProfessorInvite.created_at.desc())
    )
    if not invite:
        raise AppError(403, "professor_invite_required", "A verified professor invite is required")
    user.first_name = payload.first_name.strip()
    user.last_name = payload.last_name.strip()
    user.handle = user.handle or await available_handle(db, user)
    user.status = AccountStatus.ACTIVE.value
    professor_name = f"{user.first_name} {user.last_name}"
    channel = Conversation(
        type=ConversationType.CHANNEL.value,
        visibility=Visibility.PUBLIC.value,
        title=f"{payload.title} {professor_name}",
        description=f"Official channel for {professor_name}",
        owner_id=user.id,
        member_count=1,
        is_professor_channel=True,
        created_by_role=UserRole.PROFESSOR.value,
        audience="students",
        settings={"official_description_name": professor_name},
    )
    channel.handle = await available_handle(db, user, "channel")
    db.add(channel)
    await db.flush()
    db.add(
        ConversationMember(
            conversation_id=channel.id,
            user_id=user.id,
            role=MemberRole.OWNER.value,
            joined_at=utcnow(),
        )
    )
    db.add(
        ProfessorProfile(
            user_id=user.id,
            department=payload.department.strip(),
            title=payload.title.strip(),
            channel_id=channel.id,
        )
    )
    await db.commit()
    await db.refresh(user)
    return user, channel

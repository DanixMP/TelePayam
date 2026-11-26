from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.config import Settings, get_settings
from app.core.deps import CurrentUser, Db
from app.core.enums import UserRole
from app.core.errors import AppError
from app.db.models import Media, StudentProfile
from app.modules.common import UserSelf
from app.modules.users import service
from app.modules.users.schemas import (
    ProfessorCompletion,
    ProfileUpdate,
    StudentRegistration,
    StudentSelf,
)

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserSelf)
async def me(user: CurrentUser):
    return user


@router.patch("/me", response_model=UserSelf)
async def update_me(payload: ProfileUpdate, db: Db, user: CurrentUser):
    if "avatar_id" in payload.model_fields_set:
        if payload.avatar_id is not None:
            media = await db.get(Media, payload.avatar_id)
            if (
                not media
                or media.owner_id != user.id
                or media.kind != "image"
                or media.status != "ready"
            ):
                raise AppError(422, "invalid_avatar", "Choose one of your uploaded photos")
        user.avatar_id = payload.avatar_id
    if "bio" in payload.model_fields_set:
        user.bio = payload.bio
    await db.commit()
    await db.refresh(user)
    return user


@router.post("/me/student-profile", response_model=UserSelf)
async def student_registration(
    payload: StudentRegistration,
    db: Db,
    user: CurrentUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    return await service.register_student(db, user, payload, settings)


@router.get("/me/student-profile", response_model=StudentSelf)
async def student_profile(db: Db, user: CurrentUser):
    if user.role != UserRole.STUDENT.value:
        raise AppError(404, "profile_not_found", "Student profile was not found")
    profile = await db.get(StudentProfile, user.id)
    if not profile:
        raise AppError(404, "profile_not_found", "Student profile was not found")
    return StudentSelf(
        **UserSelf.model_validate(user).model_dump(),
        degree=profile.degree,
        department=profile.department,
        university_id=profile.university_id,
        national_id_masked=f"******{profile.national_id_last4}",
    )


@router.post("/me/professor-profile", response_model=UserSelf)
async def professor_completion(payload: ProfessorCompletion, db: Db, user: CurrentUser):
    completed, _ = await service.complete_professor(db, user, payload)
    return completed

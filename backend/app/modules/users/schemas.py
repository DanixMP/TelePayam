from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field, field_validator

from app.core.security import valid_iranian_national_id
from app.modules.common import UserSelf


class StudentRegistration(BaseModel):
    first_name: str = Field(min_length=1, max_length=80)
    last_name: str = Field(min_length=1, max_length=80)
    national_id: str
    degree: Literal["BSc", "MSc", "PhD", "other"]
    department: str = Field(min_length=1, max_length=120)
    university_id: str = Field(min_length=1, max_length=50)

    @field_validator("national_id")
    @classmethod
    def validate_national_id(cls, value: str) -> str:
        if not valid_iranian_national_id(value):
            raise ValueError("Invalid Iranian National ID checksum")
        return value


class ProfessorCompletion(BaseModel):
    first_name: str = Field(min_length=1, max_length=80)
    last_name: str = Field(min_length=1, max_length=80)
    department: str = Field(min_length=1, max_length=120)
    title: str = Field(default="Professor", min_length=1, max_length=50)


class ProfileUpdate(BaseModel):
    bio: str | None = Field(default=None, max_length=500)
    avatar_id: UUID | None = None


class StudentSelf(UserSelf):
    degree: str
    department: str
    university_id: str
    national_id_masked: str

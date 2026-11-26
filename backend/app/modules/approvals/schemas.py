from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from app.modules.common import UserSelf


class ApprovalItem(UserSelf):
    degree: str
    department: str
    university_id: str
    national_id_masked: str


class ApprovalDecision(BaseModel):
    action: Literal["approve", "reject", "request_correction"]
    reason: str | None = Field(default=None, max_length=500)


class AdminCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    phone: str = Field(min_length=1, max_length=32)


class ProfessorInviteCreate(BaseModel):
    phone: str
    first_name: str = Field(min_length=1, max_length=80)
    last_name: str = Field(min_length=1, max_length=80)
    department: str = Field(min_length=1, max_length=120)
    title: str = Field(default="Professor", max_length=50)


class StaffCreate(BaseModel):
    phone: str
    first_name: str = Field(min_length=1, max_length=80)
    last_name: str = Field(min_length=1, max_length=80)
    department: str = Field(min_length=1, max_length=120)


class ModeratorCreate(BaseModel):
    phone: str
    first_name: str = Field(min_length=1, max_length=80)
    last_name: str = Field(min_length=1, max_length=80)


class PrivilegedAccountCreated(BaseModel):
    user: UserSelf
    totp_secret: str

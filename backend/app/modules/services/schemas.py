from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.modules.common import ORMModel


class ServiceTypeCreate(BaseModel):
    name: str = Field(min_length=1, max_length=150)
    description: str | None = Field(default=None, max_length=1000)
    required_fields: dict = Field(default_factory=dict)
    required_documents: list[str] = Field(default_factory=list)
    assignee_dept: str = Field(min_length=1, max_length=120)
    sla_hours: int | None = Field(default=None, ge=1, le=8760)


class ServiceTypeOut(ORMModel):
    id: UUID
    name: str
    description: str | None
    required_fields: dict
    required_documents: list
    assignee_dept: str
    sla_hours: int | None


class ServiceRequestCreate(BaseModel):
    service_type_id: UUID
    data: dict
    documents: dict[str, UUID] = Field(default_factory=dict)


class ServiceRequestOut(ORMModel):
    id: UUID
    student_id: UUID
    service_type_id: UUID
    status: str
    assigned_staff_id: UUID | None
    data: dict
    verification_code: str | None
    created_at: datetime
    updated_at: datetime


class ServiceRequestEventOut(ORMModel):
    id: UUID
    actor_id: UUID
    kind: str
    note: str | None
    created_at: datetime


class ServiceRequestDocumentOut(ORMModel):
    id: UUID
    media_id: UUID
    kind: str
    uploaded_by: UUID
    created_at: datetime


class ServiceRequestDetail(ServiceRequestOut):
    timeline: list[ServiceRequestEventOut] = Field(default_factory=list)
    documents: list[ServiceRequestDocumentOut] = Field(default_factory=list)
    result_document: ServiceRequestDocumentOut | None = None


class ResultDocumentCreate(BaseModel):
    media_id: UUID


class StatusChange(BaseModel):
    status: str
    note: str | None = Field(default=None, max_length=1000)


class TicketMessageCreate(BaseModel):
    body: str = Field(min_length=1, max_length=10_000)
    attachment_id: UUID | None = None


class TicketMessageOut(BaseModel):
    id: UUID
    sender_id: UUID
    body: str
    attachment_id: UUID | None
    created_at: datetime

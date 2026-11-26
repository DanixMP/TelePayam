from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import select

from app.core.config import Settings, get_settings
from app.core.deps import ActiveUser, AdminUser, Db, require_roles
from app.core.enums import ServiceRequestStatus, UserRole
from app.core.errors import AppError
from app.core.security import decrypt_text, encrypt_text, generate_verification_code, utcnow
from app.db.models import (
    Media,
    ServiceRequest,
    ServiceRequestDocument,
    ServiceRequestEvent,
    ServiceRequestMessage,
    ServiceType,
    StaffProfile,
    User,
)
from app.modules.realtime.events import broadcast_users
from app.modules.services.schemas import (
    ResultDocumentCreate,
    ServiceRequestCreate,
    ServiceRequestDetail,
    ServiceRequestDocumentOut,
    ServiceRequestEventOut,
    ServiceRequestOut,
    ServiceTypeCreate,
    ServiceTypeOut,
    StatusChange,
    TicketMessageCreate,
    TicketMessageOut,
)

router = APIRouter(tags=["services"])
Staff = Annotated[User, Depends(require_roles(UserRole.STAFF))]

TRANSITIONS = {
    ServiceRequestStatus.SUBMITTED.value: {ServiceRequestStatus.IN_REVIEW.value},
    ServiceRequestStatus.IN_REVIEW.value: {
        ServiceRequestStatus.NEEDS_INFO.value,
        ServiceRequestStatus.APPROVED.value,
        ServiceRequestStatus.REJECTED.value,
    },
    ServiceRequestStatus.NEEDS_INFO.value: {ServiceRequestStatus.IN_REVIEW.value},
    ServiceRequestStatus.APPROVED.value: {
        ServiceRequestStatus.READY_FOR_PICKUP.value,
        ServiceRequestStatus.DELIVERED_DIGITALLY.value,
        ServiceRequestStatus.COMPLETED.value,
    },
    ServiceRequestStatus.READY_FOR_PICKUP.value: {ServiceRequestStatus.COMPLETED.value},
    ServiceRequestStatus.DELIVERED_DIGITALLY.value: {ServiceRequestStatus.COMPLETED.value},
}


async def require_ticket_access(db, user: User, request_id: UUID) -> ServiceRequest:
    ticket = await db.get(ServiceRequest, request_id)
    if not ticket:
        raise AppError(404, "service_request_not_found", "Service request was not found")
    if user.role == UserRole.STUDENT.value and ticket.student_id == user.id:
        return ticket
    if user.role == UserRole.STAFF.value and ticket.assigned_staff_id == user.id:
        return ticket
    raise AppError(404, "service_request_not_found", "Service request was not found")


async def ticket_recipients(ticket: ServiceRequest) -> list[UUID]:
    return list({ticket.student_id, ticket.assigned_staff_id} - {None})


async def request_detail(db, ticket: ServiceRequest) -> ServiceRequestDetail:
    timeline = list(
        await db.scalars(
            select(ServiceRequestEvent)
            .where(ServiceRequestEvent.request_id == ticket.id)
            .order_by(ServiceRequestEvent.created_at)
        )
    )
    documents = list(
        await db.scalars(
            select(ServiceRequestDocument)
            .where(ServiceRequestDocument.request_id == ticket.id)
            .order_by(ServiceRequestDocument.created_at)
        )
    )
    document_outputs = [ServiceRequestDocumentOut.model_validate(item) for item in documents]
    result = next((item for item in reversed(document_outputs) if item.kind == "result"), None)
    return ServiceRequestDetail(
        **ServiceRequestOut.model_validate(ticket).model_dump(),
        timeline=[ServiceRequestEventOut.model_validate(item) for item in timeline],
        documents=document_outputs,
        result_document=result,
    )


@router.get("/services/catalog", response_model=list[ServiceTypeOut])
async def catalog(db: Db, _: ActiveUser):
    return list(
        await db.scalars(
            select(ServiceType).where(ServiceType.active.is_(True)).order_by(ServiceType.name)
        )
    )


@router.post("/admin/services/catalog", response_model=ServiceTypeOut, status_code=201)
async def create_service_type(payload: ServiceTypeCreate, db: Db, _: AdminUser):
    item = ServiceType(**payload.model_dump())
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return item


@router.post("/services/requests", response_model=ServiceRequestOut, status_code=201)
async def create_service_request(payload: ServiceRequestCreate, db: Db, user: ActiveUser):
    if user.role != UserRole.STUDENT.value:
        raise AppError(403, "forbidden", "Only students can submit service requests")
    service_type = await db.get(ServiceType, payload.service_type_id)
    if not service_type or not service_type.active:
        raise AppError(404, "service_type_not_found", "Service type was not found")
    missing_fields = set(service_type.required_fields) - set(payload.data)
    missing_documents = set(service_type.required_documents) - set(payload.documents)
    if missing_fields or missing_documents:
        raise AppError(
            422,
            "service_requirements_missing",
            f"Missing fields: {sorted(missing_fields)}; documents: {sorted(missing_documents)}",
        )
    media_ids = set(payload.documents.values())
    if media_ids:
        media = list(await db.scalars(select(Media).where(Media.id.in_(media_ids))))
        if len(media) != len(media_ids) or any(item.owner_id != user.id for item in media):
            raise AppError(422, "invalid_document", "One or more documents are unavailable")
    ticket = ServiceRequest(
        student_id=user.id,
        service_type_id=service_type.id,
        status=ServiceRequestStatus.SUBMITTED.value,
        data=payload.data,
    )
    db.add(ticket)
    await db.flush()
    db.add(
        ServiceRequestEvent(
            request_id=ticket.id,
            actor_id=user.id,
            kind="submitted",
            created_at=utcnow(),
        )
    )
    for kind, media_id in payload.documents.items():
        db.add(
            ServiceRequestDocument(
                request_id=ticket.id,
                media_id=media_id,
                kind=kind,
                uploaded_by=user.id,
                created_at=utcnow(),
            )
        )
    await db.commit()
    await db.refresh(ticket)
    staff_ids = list(
        await db.scalars(
            select(StaffProfile.user_id).where(
                StaffProfile.department == service_type.assignee_dept
            )
        )
    )
    await broadcast_users(
        [user.id, *staff_ids],
        "service.created",
        {"request_id": str(ticket.id), "status": ticket.status},
    )
    return ticket


@router.get("/services/requests", response_model=list[ServiceRequestOut])
async def list_my_service_requests(db: Db, user: ActiveUser):
    if user.role == UserRole.STUDENT.value:
        query = select(ServiceRequest).where(ServiceRequest.student_id == user.id)
    elif user.role == UserRole.STAFF.value:
        profile = await db.get(StaffProfile, user.id)
        if not profile:
            return []
        query = (
            select(ServiceRequest)
            .join(ServiceType, ServiceType.id == ServiceRequest.service_type_id)
            .where(
                ServiceType.assignee_dept == profile.department,
                (ServiceRequest.assigned_staff_id.is_(None))
                | (ServiceRequest.assigned_staff_id == user.id),
            )
        )
    else:
        raise AppError(403, "forbidden", "This role has no service queue")
    return list(await db.scalars(query.order_by(ServiceRequest.updated_at.desc())))


@router.get("/services/requests/{request_id}", response_model=ServiceRequestDetail)
async def get_service_request(request_id: UUID, db: Db, user: ActiveUser):
    ticket = await require_ticket_access(db, user, request_id)
    return await request_detail(db, ticket)


@router.get("/services/requests/{request_id}/timeline", response_model=list[ServiceRequestEventOut])
async def request_timeline(request_id: UUID, db: Db, user: ActiveUser):
    await require_ticket_access(db, user, request_id)
    return list(
        await db.scalars(
            select(ServiceRequestEvent)
            .where(ServiceRequestEvent.request_id == request_id)
            .order_by(ServiceRequestEvent.created_at)
        )
    )


@router.post("/services/requests/{request_id}/claim", response_model=ServiceRequestOut)
async def claim_service_request(request_id: UUID, db: Db, staff: Staff):
    ticket = await db.get(ServiceRequest, request_id)
    profile = await db.get(StaffProfile, staff.id)
    service_type = await db.get(ServiceType, ticket.service_type_id) if ticket else None
    if (
        not ticket
        or not profile
        or not service_type
        or service_type.assignee_dept != profile.department
    ):
        raise AppError(404, "service_request_not_found", "Service request was not found")
    if ticket.assigned_staff_id and ticket.assigned_staff_id != staff.id:
        raise AppError(409, "already_assigned", "Request is assigned to another staff member")
    ticket.assigned_staff_id = staff.id
    if ticket.status == ServiceRequestStatus.SUBMITTED.value:
        ticket.status = ServiceRequestStatus.IN_REVIEW.value
    db.add(
        ServiceRequestEvent(
            request_id=ticket.id,
            actor_id=staff.id,
            kind="claimed",
            created_at=utcnow(),
        )
    )
    await db.commit()
    await db.refresh(ticket)
    await broadcast_users(
        await ticket_recipients(ticket),
        "service.claimed",
        {
            "request_id": str(ticket.id),
            "status": ticket.status,
            "assigned_staff_id": str(staff.id),
        },
    )
    return ticket


@router.post("/services/requests/{request_id}/status", response_model=ServiceRequestOut)
async def change_status(request_id: UUID, payload: StatusChange, db: Db, staff: Staff):
    ticket = await require_ticket_access(db, staff, request_id)
    if payload.status not in TRANSITIONS.get(ticket.status, set()):
        raise AppError(409, "invalid_status_transition", "This status transition is not allowed")
    ticket.status = payload.status
    if (
        payload.status
        in {
            ServiceRequestStatus.READY_FOR_PICKUP.value,
            ServiceRequestStatus.DELIVERED_DIGITALLY.value,
            ServiceRequestStatus.COMPLETED.value,
        }
        and not ticket.verification_code
    ):
        ticket.verification_code = generate_verification_code()
    db.add(
        ServiceRequestEvent(
            request_id=ticket.id,
            actor_id=staff.id,
            kind=f"status:{payload.status}",
            note=payload.note,
            created_at=utcnow(),
        )
    )
    await db.commit()
    await db.refresh(ticket)
    await broadcast_users(
        await ticket_recipients(ticket),
        "service.status",
        {"request_id": str(ticket.id), "status": ticket.status, "note": payload.note},
    )
    return ticket


@router.post(
    "/services/requests/{request_id}/result",
    response_model=ServiceRequestDocumentOut,
    status_code=201,
)
async def associate_result(request_id: UUID, payload: ResultDocumentCreate, db: Db, staff: Staff):
    ticket = await require_ticket_access(db, staff, request_id)
    media = await db.get(Media, payload.media_id)
    if not media or media.owner_id != staff.id or media.kind not in {"document", "file"}:
        raise AppError(422, "invalid_result_document", "Result document is unavailable")
    result = await db.scalar(
        select(ServiceRequestDocument).where(
            ServiceRequestDocument.request_id == ticket.id,
            ServiceRequestDocument.kind == "result",
        )
    )
    if result:
        result.media_id = media.id
        result.uploaded_by = staff.id
        result.created_at = utcnow()
    else:
        result = ServiceRequestDocument(
            request_id=ticket.id,
            media_id=media.id,
            kind="result",
            uploaded_by=staff.id,
            created_at=utcnow(),
        )
        db.add(result)
    db.add(
        ServiceRequestEvent(
            request_id=ticket.id,
            actor_id=staff.id,
            kind="result_uploaded",
            created_at=utcnow(),
        )
    )
    await db.commit()
    await db.refresh(result)
    await broadcast_users(
        await ticket_recipients(ticket),
        "service.result",
        {
            "request_id": str(ticket.id),
            "document_id": str(result.id),
            "media_id": str(result.media_id),
        },
    )
    return result


@router.post("/services/requests/{request_id}/cancel", response_model=ServiceRequestOut)
async def cancel_request(request_id: UUID, db: Db, user: ActiveUser):
    ticket = await require_ticket_access(db, user, request_id)
    if user.role != UserRole.STUDENT.value:
        raise AppError(403, "forbidden", "Only the requesting student can cancel")
    if ticket.status != ServiceRequestStatus.SUBMITTED.value or ticket.assigned_staff_id:
        raise AppError(409, "request_not_cancellable", "Processing has already started")
    ticket.status = ServiceRequestStatus.CANCELLED.value
    db.add(
        ServiceRequestEvent(
            request_id=ticket.id,
            actor_id=user.id,
            kind="cancelled",
            created_at=utcnow(),
        )
    )
    await db.commit()
    await db.refresh(ticket)
    await broadcast_users(
        await ticket_recipients(ticket),
        "service.cancelled",
        {"request_id": str(ticket.id), "status": ticket.status},
    )
    return ticket


@router.get("/services/requests/{request_id}/messages", response_model=list[TicketMessageOut])
async def ticket_messages(
    request_id: UUID,
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    await require_ticket_access(db, user, request_id)
    messages = list(
        await db.scalars(
            select(ServiceRequestMessage)
            .where(ServiceRequestMessage.request_id == request_id)
            .order_by(ServiceRequestMessage.created_at)
        )
    )
    return [
        TicketMessageOut(
            id=item.id,
            sender_id=item.sender_id,
            body=decrypt_text(item.body_enc, settings),
            attachment_id=item.attachment_id,
            created_at=item.created_at,
        )
        for item in messages
    ]


@router.post(
    "/services/requests/{request_id}/messages",
    response_model=TicketMessageOut,
    status_code=201,
)
async def send_ticket_message(
    request_id: UUID,
    payload: TicketMessageCreate,
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    await require_ticket_access(db, user, request_id)
    if payload.attachment_id:
        media = await db.get(Media, payload.attachment_id)
        if not media or media.owner_id != user.id:
            raise AppError(422, "invalid_attachment", "Attachment is unavailable")
    message = ServiceRequestMessage(
        request_id=request_id,
        sender_id=user.id,
        body_enc=encrypt_text(payload.body, settings),
        attachment_id=payload.attachment_id,
        created_at=utcnow(),
    )
    db.add(message)
    await db.commit()
    await db.refresh(message)
    ticket = await db.get(ServiceRequest, request_id)
    event_data = {
        "request_id": str(request_id),
        "message_id": str(message.id),
        "sender_id": str(user.id),
        "attachment_id": str(message.attachment_id) if message.attachment_id else None,
        "created_at": message.created_at.isoformat(),
    }
    await broadcast_users(await ticket_recipients(ticket), "ticket.message", event_data)
    return TicketMessageOut(
        id=message.id,
        sender_id=message.sender_id,
        body=payload.body,
        attachment_id=message.attachment_id,
        created_at=message.created_at,
    )


@router.get("/verify/{code}")
async def verify_document(code: str, db: Db):
    ticket = await db.scalar(select(ServiceRequest).where(ServiceRequest.verification_code == code))
    if not ticket:
        raise AppError(404, "verification_not_found", "Verification code was not found")
    service_type = await db.get(ServiceType, ticket.service_type_id)
    return {
        "valid": True,
        "service": service_type.name,
        "status": ticket.status,
        "issued_at": ticket.updated_at,
    }

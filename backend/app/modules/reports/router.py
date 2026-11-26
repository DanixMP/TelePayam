from datetime import timedelta
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Request
from sqlalchemy import select

from app.core.config import Settings, get_settings
from app.core.deps import ActiveUser, Db, require_roles
from app.core.enums import AccountStatus, ReportStatus, UserRole
from app.core.errors import AppError
from app.core.policy import require_conversation
from app.core.security import utcnow
from app.db.models import (
    AuditLog,
    Conversation,
    Message,
    Report,
    ReportAccessGrant,
    User,
)
from app.modules.messages import service as message_service
from app.modules.messages.schemas import MessageOut
from app.modules.realtime.events import broadcast_conversation, broadcast_users
from app.modules.reports import service
from app.modules.reports.schemas import ReportCreate, ReportOut, ReportResolution

router = APIRouter(tags=["reports"])
Moderator = Annotated[User, Depends(require_roles(UserRole.MODERATOR))]


@router.post("/reports", response_model=ReportOut, status_code=201)
async def report(
    payload: ReportCreate,
    db: Db,
    user: ActiveUser,
    settings: Annotated[Settings, Depends(get_settings)],
):
    if payload.target_type == "user" and payload.target_id == user.id:
        raise AppError(422, "invalid_report_target", "You cannot report yourself")
    return await service.create_report(db, user, payload, settings)


@router.get("/reports/mine", response_model=list[ReportOut])
async def my_reports(db: Db, user: ActiveUser):
    return list(
        await db.scalars(
            select(Report).where(Report.reporter_id == user.id).order_by(Report.created_at.desc())
        )
    )


@router.get("/moderation/reports", response_model=list[ReportOut])
async def moderation_queue(db: Db, moderator: Moderator):
    return list(
        await db.scalars(
            select(Report)
            .where(
                (Report.assigned_to.is_(None)) | (Report.assigned_to == moderator.id),
                Report.status.in_([ReportStatus.OPEN.value, ReportStatus.ASSIGNED.value]),
            )
            .order_by(Report.created_at)
        )
    )


@router.post("/moderation/reports/{report_id}/claim", response_model=ReportOut)
async def claim_report(
    report_id: UUID,
    request: Request,
    db: Db,
    moderator: Moderator,
    settings: Annotated[Settings, Depends(get_settings)],
):
    report = await db.get(Report, report_id)
    if not report or report.status not in {ReportStatus.OPEN.value, ReportStatus.ASSIGNED.value}:
        raise AppError(404, "report_not_found", "Open report was not found")
    if report.reporter_id == moderator.id or report.target_id == moderator.id:
        raise AppError(403, "moderator_conflict", "A moderator cannot review their own case")
    if report.assigned_to and report.assigned_to != moderator.id:
        raise AppError(409, "report_already_assigned", "Report is assigned to another moderator")
    report.assigned_to = moderator.id
    report.status = ReportStatus.ASSIGNED.value
    if report.conversation_id:
        conversation = await db.get(Conversation, report.conversation_id)
        message = await db.get(Message, report.message_id) if report.message_id else None
        center = message.seq if message else conversation.last_seq
        existing_grant = await db.scalar(
            select(ReportAccessGrant).where(
                ReportAccessGrant.report_id == report.id,
                ReportAccessGrant.granted_to == moderator.id,
                ReportAccessGrant.revoked_at.is_(None),
            )
        )
        if not existing_grant:
            db.add(
                ReportAccessGrant(
                    report_id=report.id,
                    conversation_id=conversation.id,
                    granted_to=moderator.id,
                    min_seq=max(1, center - settings.report_context_messages),
                    max_seq=center + settings.report_context_messages,
                    expires_at=utcnow() + timedelta(days=settings.report_grant_days),
                )
            )
    db.add(
        AuditLog(
            actor_id=moderator.id,
            action="report.claim",
            target=str(report.id),
            context={},
            ip=request.client.host if request.client else None,
            created_at=utcnow(),
        )
    )
    await db.commit()
    await db.refresh(report)
    if report.conversation_id:
        await broadcast_conversation(
            db,
            report.conversation_id,
            "report.review_started",
            {"conversation_id": str(report.conversation_id), "under_review": True},
        )
    return report


@router.get("/moderation/reports/{report_id}/messages", response_model=list[MessageOut])
async def report_messages(
    report_id: UUID,
    request: Request,
    db: Db,
    moderator: Moderator,
    settings: Annotated[Settings, Depends(get_settings)],
):
    report = await db.get(Report, report_id)
    if not report or report.assigned_to != moderator.id or not report.conversation_id:
        raise AppError(404, "report_not_found", "Assigned report was not found")
    _, _ = await require_conversation(db, moderator, report.conversation_id, "moderate")
    grant = await db.scalar(
        select(ReportAccessGrant).where(
            ReportAccessGrant.report_id == report.id,
            ReportAccessGrant.granted_to == moderator.id,
            ReportAccessGrant.revoked_at.is_(None),
        )
    )
    if (
        not grant
        or grant.expires_at.replace(tzinfo=grant.expires_at.tzinfo or utcnow().tzinfo) <= utcnow()
    ):
        raise AppError(403, "report_grant_required", "Report access has expired")
    messages = list(
        await db.scalars(
            select(Message)
            .where(
                Message.conversation_id == report.conversation_id,
                Message.seq.between(grant.min_seq, grant.max_seq),
            )
            .order_by(Message.seq)
        )
    )
    db.add(
        AuditLog(
            actor_id=moderator.id,
            action="report.messages_viewed",
            target=str(report.id),
            context={"min_seq": grant.min_seq, "max_seq": grant.max_seq},
            ip=request.client.host if request.client else None,
            created_at=utcnow(),
        )
    )
    await db.commit()
    return [await message_service.serialize_message(db, item, settings) for item in messages]


@router.post("/moderation/reports/{report_id}/resolve", response_model=ReportOut)
async def resolve_report(
    report_id: UUID,
    payload: ReportResolution,
    request: Request,
    db: Db,
    moderator: Moderator,
):
    report = await db.get(Report, report_id)
    if not report or report.assigned_to != moderator.id:
        raise AppError(404, "report_not_found", "Assigned report was not found")
    if report.status != ReportStatus.ASSIGNED.value:
        raise AppError(409, "report_closed", "Report is already closed")
    if report.conversation_id:
        await require_conversation(db, moderator, report.conversation_id, "moderate")
    report.status = (
        ReportStatus.DISMISSED.value
        if payload.outcome == "dismiss"
        else ReportStatus.RESOLVED.value
    )
    report.resolved_at = utcnow()
    report.resolved_by = moderator.id
    report.resolution = f"{payload.outcome}: {payload.note or ''}".strip()
    removed_message: Message | None = None
    banned_user: User | None = None
    if payload.outcome == "remove_content":
        if not report.message_id:
            raise AppError(422, "message_required", "Content removal requires a reported message")
        removed_message = await db.get(Message, report.message_id)
        if not removed_message:
            raise AppError(404, "message_not_found", "Reported message was not found")
        if not removed_message.deleted_at:
            removed_message.deleted_at = utcnow()
            removed_message.body_enc = None
    elif payload.outcome == "ban":
        target_id = report.target_id
        if report.target_type == "message" and report.message_id:
            target_message = await db.get(Message, report.message_id)
            if target_message:
                target_id = target_message.sender_id
        banned_user = await db.get(User, target_id)
        if not banned_user or banned_user.role not in {
            UserRole.STUDENT.value,
            UserRole.PROFESSOR.value,
        }:
            raise AppError(422, "unsafe_ban_target", "This report target cannot be banned")
        banned_user.status = AccountStatus.BANNED.value
    grants = list(
        await db.scalars(
            select(ReportAccessGrant).where(
                ReportAccessGrant.report_id == report.id,
                ReportAccessGrant.revoked_at.is_(None),
            )
        )
    )
    for grant in grants:
        grant.revoked_at = utcnow()
    db.add(
        AuditLog(
            actor_id=moderator.id,
            action="report.resolve",
            target=str(report.id),
            context={"outcome": payload.outcome},
            ip=request.client.host if request.client else None,
            created_at=utcnow(),
        )
    )
    await db.commit()
    await db.refresh(report)
    event_data = {
        "report_id": str(report.id),
        "status": report.status,
        "outcome": payload.outcome,
        "conversation_id": str(report.conversation_id) if report.conversation_id else None,
    }
    await broadcast_users([report.reporter_id], "report.resolved", event_data)
    if report.conversation_id:
        await broadcast_conversation(
            db,
            report.conversation_id,
            "report.review_resolved",
            {**event_data, "under_review": False},
        )
    if removed_message:
        await broadcast_conversation(
            db,
            removed_message.conversation_id,
            "msg.deleted",
            {
                "id": str(removed_message.id),
                "conv": str(removed_message.conversation_id),
                "seq": removed_message.seq,
            },
        )
    if banned_user:
        await broadcast_users(
            [banned_user.id],
            "account.status",
            {"status": AccountStatus.BANNED.value, "reason": "moderation"},
        )
    return report

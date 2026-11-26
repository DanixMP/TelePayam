import json

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings
from app.core.errors import AppError
from app.core.policy import require_conversation
from app.core.security import encrypt_text, utcnow
from app.db.models import Conversation, Message, Report, User
from app.modules.messages import service as message_service
from app.modules.reports.schemas import ReportCreate


async def create_report(
    db: AsyncSession,
    reporter: User,
    payload: ReportCreate,
    settings: Settings,
) -> Report:
    evidence: dict = {
        "target_type": payload.target_type,
        "target_id": str(payload.target_id),
        "captured_at": utcnow().isoformat(),
        "messages": [],
    }
    conversation: Conversation | None = None
    center_seq = 0
    if payload.conversation_id:
        conversation, _ = await require_conversation(db, reporter, payload.conversation_id, "read")
    if payload.message_id:
        message = await db.get(Message, payload.message_id)
        if not message or not conversation or message.conversation_id != conversation.id:
            raise AppError(422, "invalid_report_target", "Reported message is unavailable")
        center_seq = message.seq
    if payload.target_type == "message" and not payload.message_id:
        raise AppError(422, "message_required", "A message ID is required")
    if payload.target_type in {"group", "channel"}:
        if not conversation or payload.target_id != conversation.id:
            raise AppError(422, "invalid_report_target", "Reported conversation is unavailable")
        if conversation.type != payload.target_type:
            raise AppError(422, "invalid_report_target", "Report type does not match conversation")
    if payload.target_type == "user" and not await db.get(User, payload.target_id):
        raise AppError(422, "invalid_report_target", "Reported user is unavailable")
    if conversation:
        if not center_seq:
            center_seq = conversation.last_seq
        minimum = max(1, center_seq - settings.report_context_messages)
        maximum = center_seq + settings.report_context_messages
        context = list(
            await db.scalars(
                select(Message)
                .where(
                    Message.conversation_id == conversation.id,
                    Message.seq.between(minimum, maximum),
                )
                .order_by(Message.seq)
            )
        )
        evidence["conversation"] = {
            "id": str(conversation.id),
            "type": conversation.type,
            "title": conversation.title,
        }
        evidence["messages"] = [
            (await message_service.serialize_message(db, item, settings)).model_dump(mode="json")
            for item in context
        ]
    report = Report(
        reporter_id=reporter.id,
        target_type=payload.target_type,
        target_id=payload.target_id,
        conversation_id=payload.conversation_id,
        message_id=payload.message_id,
        reason=payload.reason,
        note=payload.note,
        evidence_enc=encrypt_text(json.dumps(evidence), settings),
    )
    db.add(report)
    await db.commit()
    await db.refresh(report)
    return report

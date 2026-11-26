from datetime import timedelta

import pytest

from app.core.enums import AccountStatus, ConversationType, MemberRole, UserRole, Visibility
from app.core.errors import AppError
from app.core.policy import require_conversation
from app.core.security import utcnow
from app.db.models import (
    Conversation,
    ConversationMember,
    Report,
    ReportAccessGrant,
    User,
)


async def make_user(db, phone: str, role: str) -> User:
    user = User(
        phone=phone,
        role=role,
        status=AccountStatus.ACTIVE.value,
        first_name="Test",
        last_name=role,
    )
    db.add(user)
    await db.flush()
    return user


async def test_professor_cannot_discover_student_group_even_if_member(db):
    student = await make_user(db, "+989111111111", UserRole.STUDENT.value)
    professor = await make_user(db, "+989222222222", UserRole.PROFESSOR.value)
    group = Conversation(
        type=ConversationType.GROUP.value,
        visibility=Visibility.PUBLIC.value,
        handle="student_group",
        title="Hidden Group",
        owner_id=student.id,
        created_by_role=UserRole.STUDENT.value,
        audience="students",
        member_count=2,
    )
    db.add(group)
    await db.flush()
    db.add(
        ConversationMember(
            conversation_id=group.id,
            user_id=professor.id,
            role=MemberRole.MEMBER.value,
            joined_at=utcnow(),
        )
    )
    await db.commit()

    with pytest.raises(AppError) as error:
        await require_conversation(db, professor, group.id, "read")
    assert error.value.status_code == 404


async def test_admin_has_no_implicit_dm_access(db):
    student = await make_user(db, "+989333333333", UserRole.STUDENT.value)
    admin = await make_user(db, "+989444444444", UserRole.ADMIN.value)
    dm = Conversation(
        type=ConversationType.DM.value,
        visibility=Visibility.PRIVATE.value,
        owner_id=student.id,
        created_by_role=UserRole.STUDENT.value,
        audience="participants",
        member_count=1,
    )
    db.add(dm)
    await db.flush()
    db.add(
        ConversationMember(
            conversation_id=dm.id,
            user_id=admin.id,
            role=MemberRole.MEMBER.value,
            joined_at=utcnow(),
        )
    )
    await db.commit()

    with pytest.raises(AppError) as error:
        await require_conversation(db, admin, dm.id, "read")
    assert error.value.status_code == 404


async def test_moderator_access_is_scoped_and_revocable(db):
    student = await make_user(db, "+989777777777", UserRole.STUDENT.value)
    moderator = await make_user(db, "+989888888888", UserRole.MODERATOR.value)
    dm = Conversation(
        type=ConversationType.DM.value,
        visibility=Visibility.PRIVATE.value,
        owner_id=student.id,
        created_by_role=UserRole.STUDENT.value,
        audience="participants",
        member_count=1,
        last_seq=200,
    )
    db.add(dm)
    await db.flush()
    report = Report(
        reporter_id=student.id,
        target_type="user",
        target_id=student.id,
        conversation_id=dm.id,
        reason="test",
        evidence_enc="encrypted",
        assigned_to=moderator.id,
        status="assigned",
    )
    db.add(report)
    await db.flush()

    with pytest.raises(AppError):
        await require_conversation(db, moderator, dm.id, "moderate", seq=100)

    grant = ReportAccessGrant(
        report_id=report.id,
        conversation_id=dm.id,
        granted_to=moderator.id,
        min_seq=50,
        max_seq=150,
        expires_at=utcnow() + timedelta(days=1),
    )
    db.add(grant)
    await db.commit()

    conversation, _ = await require_conversation(db, moderator, dm.id, "moderate", seq=100)
    assert conversation.id == dm.id
    with pytest.raises(AppError):
        await require_conversation(db, moderator, dm.id, "moderate", seq=151)

    grant.revoked_at = utcnow()
    await db.commit()
    with pytest.raises(AppError):
        await require_conversation(db, moderator, dm.id, "moderate", seq=100)

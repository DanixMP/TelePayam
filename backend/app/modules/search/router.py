from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import or_, select

from app.core.deps import ActiveUser, Db
from app.core.enums import AccountStatus, ConversationType, UserRole, Visibility
from app.core.errors import AppError
from app.core.policy import is_hidden_student_group
from app.core.store import KeyValueStore, get_store
from app.db.models import Conversation, User
from app.modules.conversations.schemas import ResolveOut

router = APIRouter(tags=["search"])


@router.get("/resolve/{handle}", response_model=ResolveOut)
async def resolve(handle: str, db: Db, user: ActiveUser):
    normalized = handle.lower().removeprefix("@")
    found_user = await db.scalar(
        select(User).where(
            User.handle == normalized,
            User.status == AccountStatus.ACTIVE,
            User.role.in_([UserRole.STUDENT, UserRole.PROFESSOR]),
        )
    )
    if found_user:
        return ResolveOut(
            kind="user",
            id=found_user.id,
            handle=found_user.handle,
            avatar_id=found_user.avatar_id,
            title=" ".join(filter(None, [found_user.first_name, found_user.last_name])),
        )
    conversation = await db.scalar(select(Conversation).where(Conversation.handle == normalized))
    if (
        not conversation
        or conversation.visibility != Visibility.PUBLIC
        or conversation.archived_at
        or is_hidden_student_group(user, conversation)
    ):
        raise AppError(404, "handle_not_found", "Handle was not found")
    return ResolveOut(
        kind=conversation.type,
        id=conversation.id,
        handle=conversation.handle,
        title=conversation.title or conversation.handle,
    )


@router.get("/search", response_model=list[ResolveOut])
async def search(
    q: str,
    db: Db,
    user: ActiveUser,
    store: Annotated[KeyValueStore, Depends(get_store)],
):
    query = q.strip().lower().removeprefix("@")
    if len(query) < 2:
        raise AppError(422, "query_too_short", "Search requires at least two characters")
    if await store.increment(f"search-rate:{user.id}", 60) > 30:
        raise AppError(429, "search_rate_limited", "Too many searches")
    try:
        exact_id = UUID(query)
    except ValueError:
        exact_id = None
    people = list(
        await db.scalars(
            select(User)
            .where(
                User.handle.is_not(None),
                User.status == AccountStatus.ACTIVE,
                User.role.in_([UserRole.STUDENT, UserRole.PROFESSOR]),
                or_(
                    User.id == exact_id if exact_id else False,
                    User.handle.startswith(query, autoescape=True),
                ),
            )
            .order_by(User.handle)
            .limit(10)
        )
    )
    conversation_query = select(Conversation).where(
        Conversation.visibility == Visibility.PUBLIC.value,
        Conversation.archived_at.is_(None),
        Conversation.handle.is_not(None),
        or_(
            Conversation.id == exact_id if exact_id else False,
            Conversation.handle.startswith(query, autoescape=True),
        ),
    )
    if user.role == UserRole.PROFESSOR.value:
        conversation_query = conversation_query.where(
            Conversation.type != ConversationType.GROUP.value
        )
    conversations = list(
        await db.scalars(conversation_query.order_by(Conversation.handle).limit(10))
    )
    results = [
        ResolveOut(
            kind="user",
            id=item.id,
            handle=item.handle,
            avatar_id=item.avatar_id,
            title=" ".join(filter(None, [item.first_name, item.last_name])),
        )
        for item in people
    ]
    results.extend(
        ResolveOut(
            kind=item.type,
            id=item.id,
            handle=item.handle,
            title=item.title or item.handle,
        )
        for item in conversations
    )
    return results

from enum import StrEnum


class UserRole(StrEnum):
    STUDENT = "student"
    PROFESSOR = "professor"
    STAFF = "staff"
    MODERATOR = "moderator"
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"


SUPER_ADMIN_PHONE = "+989981080891"


class AccountStatus(StrEnum):
    PENDING_PROFILE = "pending_profile"
    PENDING_APPROVAL = "pending_approval"
    ACTIVE = "active"
    SUSPENDED = "suspended"
    BANNED = "banned"
    REJECTED = "rejected"


class ConversationType(StrEnum):
    DM = "dm"
    GROUP = "group"
    CHANNEL = "channel"


class Visibility(StrEnum):
    PUBLIC = "public"
    PRIVATE = "private"


class MemberRole(StrEnum):
    OWNER = "owner"
    ADMIN = "admin"
    MEMBER = "member"
    SUBSCRIBER = "subscriber"
    BANNED = "banned"


class ReportStatus(StrEnum):
    OPEN = "open"
    ASSIGNED = "assigned"
    RESOLVED = "resolved"
    DISMISSED = "dismissed"


class ServiceRequestStatus(StrEnum):
    DRAFT = "draft"
    SUBMITTED = "submitted"
    IN_REVIEW = "in_review"
    NEEDS_INFO = "needs_info"
    APPROVED = "approved"
    REJECTED = "rejected"
    READY_FOR_PICKUP = "ready_for_pickup"
    DELIVERED_DIGITALLY = "delivered_digitally"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class CallStatus(StrEnum):
    RINGING = "ringing"
    ACTIVE = "active"
    DECLINED = "declined"
    ENDED = "ended"


class CallParticipantStatus(StrEnum):
    INVITED = "invited"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    ENDED = "ended"

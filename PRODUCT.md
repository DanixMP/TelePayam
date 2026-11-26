# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Flutter (Dart 3), Riverpod, go_router, Drift/SQLite, Dio, and web_socket_channel. Android is the first shipping target, followed by Windows desktop; iOS remains optional.

## Users

University students, professors, staff, moderators, and administrators. The first delivery serves new students and invited professors completing phone-based identity and registration before entering the messenger.

## Product Purpose

University Messenger combines fast, familiar messaging with university-verified identities, role-specific capabilities, staff paperwork, professor channels, and privacy-aware moderation. Phase 0 + 1 succeeds when a user can authenticate by Iranian phone number, complete the correct role-specific profile, and be routed reliably through approval, rejection, blocked, and active account states.

## Positioning

The product uses one verified university identity and one messenger surface for conversation, academic channels, university services, and report-gated moderation rather than separating those workflows across unrelated systems.

## Operating Context

Users primarily operate the app on Android phones, often with mixed Persian and English content and intermittent networks. Students provide Iranian identity and university enrollment details for administrative approval. Invited professors confirm their profile and become active immediately. The local database is the UI source of truth and network changes reconcile into it.

## Capabilities and Constraints

- Phone OTP authentication uses the existing `/api/v1` backend contract and Iranian phone normalization.
- Roles are assigned by the backend and are never selected by the client.
- Account states are `pending_profile`, `pending_approval`, `active`, `suspended`, `banned`, and `rejected`.
- Student registration requires a valid ten-digit Iranian National ID checksum, degree, department, and university ID.
- Professor completion requires name, department, and title.
- Access and rotating refresh tokens must be stored securely and refreshed atomically.
- Persian and English are supported; RTL is a primary layout direction while identifiers and numbers remain LTR-safe.
- National IDs are masked outside the registration input and must never be logged.
- Approval updates currently require polling `/users/me`; no backend approval WebSocket event is implemented yet.

## Brand Commitments

The product is named University Messenger. Interaction and information architecture should feel Telegram-faithful: fast, direct, clean, and familiar, with a configurable blue accent. Vazirmatn is the preferred Persian-first type family. University verification and role-aware states should be unmistakable without making the app feel institutional or bureaucratic.

## Evidence on Hand

- `FRONTEND_PLAN.md` is the approved product and implementation brief.
- `BACKEND_PLAN.md` documents the service architecture.
- `backend/` contains the implemented FastAPI contracts and tests.
- No logo, production imagery, testimonials, usage metrics, or university-specific visual assets are supplied; future work must not fabricate them.

## Product Principles

- Make every state transition explicit and recoverable.
- Keep authentication and registration fast enough to feel like messaging, not paperwork.
- Treat the local database as UI truth and reconcile network state behind it.
- Show only capabilities allowed by the user's backend-assigned role.
- Build RTL, accessibility, and unreliable-network behavior into the default experience.

## Accessibility & Inclusion

Support screen-reader semantics, visible keyboard focus on desktop, large text, reduced motion, sufficient contrast, touch targets of at least 48 logical pixels, and correct mixed-direction rendering for Persian, English, phone numbers, IDs, and one-time codes.

---
version: 1
slug: "frontend"
primary_target: "frontend"
related_targets: ["FRONTEND_PLAN.md"]
---

# Frontend Phase 0 + 1

Mode: Operate

Scope: Android-first adaptive Flutter authentication, registration, and account-state flow. Students and invited professors authenticate by phone, complete their assigned profile, and understand what happens next. The backend owns roles and status.

Constraints: Material 3 interaction patterns, Telegram-familiar speed and hierarchy, Persian-first RTL, English support, mixed-direction inputs, dark mode, accessible scaling, unreliable networks, and Windows-ready responsive composition.

## Direction contract

THESIS: Identity setup should move with the directness of sending a message, not feel like an administrative portal. It refuses a stack of ornamental onboarding cards and keeps one clear action per screen.

OWN-WORLD: Telegram blue and university navy sit on cool paper-white and ink-tinted dark surfaces. Vazirmatn carries Persian and Latin UI roles. Native fields, buttons, sheets, and progress semantics stay recognizable. A thin verification thread connects completed, current, and upcoming identity stages.

STORY: Enter a phone number, verify the six-digit code, provide only the profile required by the backend-assigned role, review it, and see an honest live account state with clear recovery actions.

FIRST VIEWPORT: On phones, a calm blue field occupies the upper third with a compact messenger mark and verification thread; the active form rises from the lower surface without a floating card. The primary action remains reachable above the keyboard. Wide screens use one centered task column beside a restrained identity-status panel.

FORM: Telegram-faithful native messenger onboarding, pinned by the product brief and strengthened with a university verification thread as the single signature move. `seed:6579ec02d090585c`.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

Unresolved: production API base URLs and university-specific logo assets are not supplied. Development uses environment configuration and an authored geometric messenger mark without pretending it is an official university logo.

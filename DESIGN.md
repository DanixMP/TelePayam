# Design System

<!-- impeccable:design-schema 1 -->

## Direction

University Messenger uses a Telegram-familiar Material 3 interface with one product-specific signature: a verification thread connecting phone, identity, review, and access. Messaging screens prioritize recognition and speed over ornament. University identity appears through verified professor markers, clear role/state language, and restrained navy support colors rather than administrative portal styling.

## Color

All application code consumes semantic `ColorScheme` roles. Brand and status values live in `AppTokens`.

| Token | Light | Dark | Use |
|---|---:|---:|---|
| Primary | `#1769AA` | `#70BAF2` | Actions, selection, unread state |
| Hero blue | `#1769AA` | `#0D4775` | Identity-flow field with white content |
| Navy | `#153B61` | `#8ABBE0` | Institutional support tone |
| Success | `#16885A` | `#72D6A1` | Completed verification state |
| Warning | `#9A5B00` | `#FFD18A` | Pending/corrective attention |

Chat surfaces use `surface`, `surfaceContainerLow`, `primaryContainer`, and `outlineVariant`; raw brand values should not be repeated in feature widgets.

## Type

Material display, headline, title, body, and label roles define the scale. Headlines use 700–800 weight with compact tracking; body copy uses 1.5–1.55 line height. The messenger bundles Vazirmatn Regular and Bold for Persian and Latin content, including offline web rendering. IDs, OTPs, phone numbers, and timestamps stay LTR/tabular inside an otherwise RTL-aware interface.

## Shape And Spacing

- Page padding: 24dp; dense list padding: 12–14dp.
- Controls: 14dp radius and at least 48dp touch height.
- Cards and transient surfaces: 14–16dp radius.
- Authentication mobile surface: 28dp top corners over a solid hero field.
- Message bubbles: 16dp corners with a 4dp directional tail corner.
- Dividers use `outlineVariant`; do not combine borders and broad shadows.

## Layout

Compact widths show one task at a time. Chat list opens a full conversation route with system Back recovery. At 900dp and above, the list holds a 390dp pane and the selected conversation fills the remaining width. Authentication switches at 840dp from a stacked mobile composition to a 40/60 identity-and-form split.

## Components

- `AuthScaffold`: adaptive identity flow shell.
- `VerificationThread`: current/completed account stages; honors reduced motion.
- `MessengerMark`: temporary geometric product mark, not a university logo.
- `ChatListPane`: local-stream inbox, unread counts, search, and refresh.
- `ChatScreen`: header, sequence-backed history, local read updates, and composer.
- Message bubble: mixed-direction text, optimistic state, sent ticks, failure retry.
- `AsyncPrimaryButton` and `InlineError`: shared loading and recoverable error behavior.

## Motion And State

Motion is short Material easing and disappears when platform animation reduction is enabled. Messages enter locally as `sending`, reconcile to `sent`, and remain actionable as `failed`. Typing expires locally after six seconds. Network failures preserve cached identity, conversations, and messages; errors must state the recovery action.

## Accessibility

Maintain 48dp Android targets, semantic labels, keyboard focus, large-text reflow, safe areas, edge-to-edge insets, and color contrast. Never use color alone for delivery, approval, or error state. Persian/English direction is selected per message body while structural direction follows the selected locale.

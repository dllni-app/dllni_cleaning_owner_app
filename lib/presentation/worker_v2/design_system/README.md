# S01 worker rebuild visual kit — WR-U0

Import only `design_system.dart`. This library is independent of legacy visual widgets, app services, navigation, DI and HTTP. S00 integrates its light theme and root routes after WR-U0. All text labels, statuses, explanations and displayed amounts are supplied by the consumer in the selected language; widgets do not translate server enums or calculate prices.

| Public API | Required inputs | Optional inputs and behavior |
|---|---|---|
| `WorkerV2Theme.light` | None | Cairo Material 3 light theme; no dark-mode contract |
| `WrPageFrame` | `title`, `child` | `subtitle`, `headerAction`, `bottomAction`; scrollable body, safe action dock |
| `WrSectionPanel` | `child` | `title`, `subtitle`, `action`; bordered surface |
| `WrActionButton` | `label` | `onPressed`, `role`, `busy`, `busyLabel`, `disabledExplanation`, `leadingIcon`, `expand`; 52px minimum, disabled while busy; **supply localized `busyLabel` if `busy: true`** for live progress semantics, distinct from an unavailable action |
| `WrIconAction` | `icon`, `label` | `onPressed`, `busy`, `busyLabel`; 48px minimum; **supply localized `busyLabel` when busy** |
| `WrField` | `label` | Controller, hint, error, callback, keyboard/direction, enabled, obscure and suffix; input-associated floating label remains visible even without a hint |
| `WrPhoneField`, `WrTimeField` | `label` | Controller, callback, error, hint, enabled; entry is LTR inside RTL layout |
| `WrPasswordField` | `label`, `revealLabel`, `hideLabel` | Controller, callback, hint, error, enabled; accessible visibility toggle |
| `WrStatusBadge` | `label` | `tone`, `icon`; semantic text beyond color |
| `WrEligibilityNotice` | `title`, `message` | `tone`, `actionLabel`, `onAction`; caller decides actual permission and remedy |
| `WrFeedbackPanel` | `kind`, `title` | `message`, `retainedContent`, retry label/callback; distinct initial vs retained refresh failures and offline/forbidden/unavailable/empty/loading |
| `WrSheetFrame` | `title`, `child` | Optional actions and submitting state; **supply localized `submittingLabel` when submitting**; safe-area and keyboard inset padding; caller controls modal lifecycle |
| `WrConfirmDialog` | Title, message, confirm/cancel labels | Confirm/cancel callbacks, busy and destructive tone; **supply localized `busyLabel` when busy**; caller owns authority and dismiss |
| `WrNavigationItem` | Label, icon | Selected state/callback; 48px target and responsive labels, no internal navigation |
| `WrListRow` | Title | Subtitle/leading/trailing/tap and optional `subtitleDirection` for LTR UTC/code spans in RTL rows; wraps long labels |
| `WrAmountText` | Nullable `MoneyValue`, unavailable label | Displays exact decimal and currency as an LTR span; preserves legitimate zero and visibly labels null |

Tokens: `WrColors`, `WrSpace`, `WrRadius`, `WrMotion`, `WrType`. Primary navy `#1E2A7B` on white is 12.56:1; navy text on teal is 5.79:1. Teal/white (2.17:1), original orange/white (3.19:1) are not used as small-text color pairs. State colors include explicit text and labels.

Gallery: `examples/component_gallery.dart` composes synthetic WR-C0 V1 fixtures (current/next visit, overlapping/gapped UTC sample intervals, supervisor-controlled mission, zero vs unreconciled money, and five tabs). Its displayed interval strings are explicitly `UTC` **example data**, not booking-local Syria times; feature controllers must prepare localized Asia/Damascus labels before passing them to row widgets. Goldens `test/worker_rebuild/design_system/goldens/gallery_{ar,en}_430.png` load the registered Cairo asset and MaterialIcons from the active Flutter SDK and have been visually inspected. Scrollable content is inside a fixed safe-area dock; the test also scrolls to the final earnings line at width 320 and text scale 2.

Acceptance boundary: All screens and API/authorization/finance logic remain S04–S08/S00/S03/S02 responsibilities. Root `lib/app.dart` currently clamps global text scaling to 1.2 and needs S00 integration adjustment for device-scale 1.5/2.0; isolated S01 widgets and gallery are tested without that clamp. WR-U0 still requires independent R00 review.

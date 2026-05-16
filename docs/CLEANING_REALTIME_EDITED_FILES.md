# CLEANING_REALTIME_EDITED_FILES

Implementation audit date: 2026-05-13

## Owner app (`dllni_cleaninig_owner_app`)

| File path | What changed | Why it changed | Related API/event/flow step | Risk notes |
|---|---|---|---|---|
| `lib/features/orders/view/widgets/accept_order_bottom_sheet.dart` (new) | Added restaurant-style accept confirmation sheet for cleaning orders. | Match design image 2 and confirm accept before action dispatch. | `POST /api/v1/cleaning-bookings/{id}/accept` | UI-only risk; action wiring depends on existing accept API success handling. |
| `lib/core/widgets/order_card.dart` | Rebuilt owner order card UI and lifecycle CTA routing (pending accept/reject, start travel/cancel, follow-up). | Match design image 1 and keep lifecycle actions consistent from list level. | Pending/assigned/travel lifecycle entrypoints | Constructor changed; dependent screens were updated to new signature. |
| `lib/features/home/view/screens/home_screen.dart` | Updated `OrderCard` usage to new constructor (`data`). | Keep home list compile-safe after `OrderCard` refactor. | Home quick-orders surface | Low. |
| `lib/features/orders/view/screens/orders_screen.dart` | Unified list rendering to use new `OrderCard` component. | Consistent lifecycle card behavior in orders list. | Owner orders list flow | Low. |
| `lib/features/orders/view/widgets/order_details/order_details_body.dart` | Accept now opens confirmation sheet; start-travel + cancel branch retained for assigned jobs. | Enforce designed flow at details-level body 1/2. | Accept/start-travel/cancel gates | Low. |
| `lib/core/widgets/cancel_order_dialog.dart` | Replaced cancel dialog with warning-style design (image 3). | Match required warning UX before cancel submit. | `POST /api/v1/cleaning-bookings/{id}/cancel` | Copy/wording can be tuned later; functional behavior unchanged. |
| `lib/features/orders/view/widgets/order_details/order_details_map_body.dart` | Added strict gating: map stage now handles arrive + waiting-for-customer-verification state; security code fetch/render; live location posting retained. | Enforce `arrive -> customer secure-code verification -> mission` with no worker bypass. | `POST /arrive`, `GET /security-code`, `POST /location` | Depends on security-code endpoint availability and payload consistency. |
| `lib/features/orders/view/widgets/order_details/order_details_mission_body.dart` | Redesigned mission body (image 4 style), dynamic task list from services/addons, finish-work waiting-confirmation behavior. | Match mission UI and worker waiting state after finish action. | `POST /complete`, status `awaiting_customer_completion` | Realtime updates can retrigger wait prompts if backend status flaps. |
| `lib/features/orders/view/screens/order_details_screen.dart` | Hardened realtime payload parsing for extension requests; kept 4-body lifecycle routing with map-stage verification gate path. | Improve reliability across camelCase/snake_case payload variations. | `ServiceExtensionRequested` + booking sync events | If backend sends unexpected keys, fallback defaults are shown. |
| `lib/features/orders/view/manager/bloc/orders_bloc.dart` | Fixed invalid arrive step transition (`4` -> correct mapped steps), preserving 4-body lifecycle flow. | Prevent unreachable/incorrect UI state after arrive. | `ArriveEvent` state transition | Low. |
| `lib/features/orders/view/manager/order_notifier.dart` | Added active lifecycle multi-status filter constant. | Support in-progress tab showing all active realtime statuses. | `GET /cleaning-bookings?filter[status]=...` | Backend must support multi-status filtering format. |
| `lib/features/orders/view/widgets/orders_type_tab_bar.dart` | Wired in-progress tab to active lifecycle filter set. | Keep tab data aligned with realtime lifecycle statuses. | Owner in-progress listing | Low. |
| `lib/features/orders/domain/usecases/reject_extension_usecase_use_case.dart` | Added optional `message` in reject-extension request body. | Support apology/reason from extension reject sheet. | `POST /cleaning-time-warnings/{id}/reject` | Backend may ignore message if not implemented. |
| `lib/features/orders/view/widgets/extension_request_action_sheet.dart` | Redesigned extension request sheet (image 7 style), enriched payload display, reject-message wiring. | Match design and complete extension decision UX. | `ServiceExtensionRequested`, accept/reject extension APIs | Depends on backend payload enrichment for best display fidelity. |
| `pubspec.yaml` / `pubspec.lock` | Added direct `intl` dependency used by formatting in new/updated widgets. | Remove analyze dependency-reference warnings and keep build clean. | Build/tooling | Low. |

## User app (`dllni-user-app`)

| File path | What changed | Why it changed | Related API/event/flow step | Risk notes |
|---|---|---|---|---|
| `lib/core/realtime/cleaning_booking_pusher_service.dart` | Added customer-channel support and multi-booking subscription capability. | Enable app-level global verification prompting and avoid single-channel limitation. | Realtime channels (`private-cleaning-booking.*`, `private-cleaning-customer.*`) | Requires backend customer-channel support; otherwise fallback polling is used. |
| `lib/core/realtime/cleaning_global_verification_gate_coordinator.dart` (new) | Added global coordinator for secure-code dialog from anywhere in app, with polling fallback. | Implement image 8 behavior globally, not only in details screen. | Start verification gate (`awaiting_start_verification`) | Poll fallback introduces slight delay when realtime channel unavailable. |
| `lib/app.dart` | Bootstrapped and lifecycle-managed global verification coordinator. | Ensure gate listener is active app-wide. | App-level realtime gate orchestration | Low. |
| `lib/features/auth/view/screens/login_screen.dart` | Persisted `customer_id` at login success. | Needed for customer-scoped realtime subscription setup. | Login/session bootstrap | If legacy sessions lack this key, fallback polling still works. |
| `lib/features/orders/view/screens/cleaning_order_details_screen.dart` | Kept realtime sync, added extension-reject reopen loop handling for completion sheet, retained gate UI surfaces. | Ensure completion gate reopens when extension gets rejected and keep status sync robust. | `CompletionDecisionMade`, `cleaning_order.awaiting_customer_completion` | Behavior depends on backend event semantics consistency. |
| `lib/features/orders/view/widgets/cleaning_start_verification_dialog.dart` | Redesigned verification dialog to match target visual style (image 8). | UX parity for secure-code entry. | `POST /start-verification/confirm` | Low. |
| `lib/features/orders/view/widgets/cleaning_completion_decision_sheet.dart` | Redesigned completion decision sheet (image 5 style), confirm/reject/extend actions retained. | UX parity and proper completion gate actions. | `completion/confirm`, `completion/reject`, `completion/extend-time` | Low; backend constraints still apply for extend values and reject reason handling. |
| `lib/features/orders/view/screens/cleaning_worker_rating_screen.dart` | Redesigned rating screen (image 6 style) and fixed submit success/failure branch logic. | Match required UX and correct review submission behavior. | `POST /api/v1/user/cleaning/orders/{id}/review` | Endpoint contract should remain stable for optional tags/comment fields. |

## Validation executed

- Owner app:
  - `flutter analyze` => passed with no issues.
  - `flutter test` => passed.
- User app:
  - Targeted analyze for edited files => passed.
  - `flutter test` => passed.
  - Full-project `flutter analyze` still reports many pre-existing unrelated warnings in untouched modules.

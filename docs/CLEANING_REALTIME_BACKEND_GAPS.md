# CLEANING_REALTIME_BACKEND_GAPS

Test date: 2026-05-13
Scope: `dllni_cleaninig_owner_app` + `dllni-user-app` realtime cleaning lifecycle implementation.

## Findings

| Endpoint/Event | Missing field/behavior | Where used in app | Impact severity | Repro/test evidence | Temporary client fallback | Required backend fix |
|---|---|---|---|---|---|---|
| `private-cleaning-customer.{customerId}` (customer-scoped realtime channel) | Channel and auth behavior are required for truly global secure-code prompting, but not fully guaranteed by current contract files. | `dllni-user-app/lib/core/realtime/cleaning_global_verification_gate_coordinator.dart` | High | Global gate implemented; no backend payload capture in local test run to confirm channel exists in all environments. | Polling fallback every 12s for `awaiting_start_verification` orders. | Provide and document customer-scoped private channel with stable event names and auth rules. |
| `ServiceExtensionRequested` payload | Enriched fields are not guaranteed in all payloads: `customerName`, `additionalAmount`, `currency`, `paymentMethod` (camel/snake variations). | `dllni_cleaninig_owner_app/lib/features/orders/view/screens/order_details_screen.dart` and `.../widgets/extension_request_action_sheet.dart` | Medium | Client parser now accepts multiple key variants; local tests cannot assert production payload completeness. | Defaults are shown when fields are missing. | Always broadcast complete enriched payload with documented schema/version. |
| `POST /api/v1/cleaning-time-warnings/{id}/reject` | Optional reject apology `message` handling is required for UX parity but backend support may vary by environment. | `dllni_cleaninig_owner_app/lib/features/orders/domain/usecases/reject_extension_usecase_use_case.dart` and `.../widgets/extension_request_action_sheet.dart` | Medium | Client now sends `message`; no live API assertion in local run to verify persistence/forwarding. | Request still works with `{}` body if message is ignored. | Accept, validate (max 150), store, and expose reject `message` consistently. |
| `GET /api/v1/cleaning-bookings` filter behavior | Active in-progress tab now sends multi-status filter set (`in_progress,awaiting_start_verification,awaiting_customer_completion,time_extension_requested`). Backend multi-value filtering may not be supported in all deployments. | `dllni_cleaninig_owner_app/lib/features/orders/view/manager/order_notifier.dart` and `.../widgets/orders_type_tab_bar.dart` | Medium | Client switched to active lifecycle filter constant; no backend integration assertion in local-only tests. | Existing manual tab refresh still works; statuses may appear partial if backend ignores multi-value filter. | Support documented multi-status filtering (array or CSV) for `filter[status]`. |
| Extension rejection signal back to customer completion gate | Customer app needs deterministic signal when worker rejects extension so completion decision sheet reopens. Current behavior can be ambiguous if event semantics vary. | `dllni-user-app/lib/features/orders/view/screens/cleaning_order_details_screen.dart` | High | Reopen loop implemented using `CompletionDecisionMade` + status refetch; exact worker-reject event mapping not guaranteed by contract text. | Client refetch + force reopen when completion gate returns to `awaiting_customer_completion`. | Emit explicit worker-extension-rejected event (or deterministic `CompletionDecisionMade` payload) with booking id and decision reason. |

## Validation context

- Static checks:
  - Owner app: `flutter analyze` => no issues.
  - User app: targeted analyze on changed files => no issues.
- Automated tests:
  - Owner app: `flutter test` passed.
  - User app: `flutter test` passed.
- Limitation:
  - No live backend payload capture was available in this run, so realtime payload completeness/channel availability is marked as backend confirmation items.

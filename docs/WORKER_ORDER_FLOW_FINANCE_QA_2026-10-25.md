# Worker Order Flow and Financial UI QA — 2026-10-25

## Scope

Flutter worker app `dllni_cleaning_owner_app`, Laravel `Modules/Cleaning`, worker booking response, time warnings, worker financial amounts, test seed fixtures, home/list/detail/active-session UI. This audit was prompted by worker app screenshots taken 2026-10-25.

## Financial source of truth

* Laravel backend is authoritative for booking/worker financial snapshots and time-extension quotes; Flutter must not invent an amount or a commission rate.
* Worker service share includes the work allocated to **that worker**, including applicable selected special services, not the entire multi-worker booking.
* Worker payout is `serviceShareAmount + travelFee`; `adminMarginAmount` is charged additionally to the customer and is **not subtracted again** from this payout.
* The UI should show service/special service share, worker travel allowance, customer-facing admin margin and its effective percentage, and final worker payable amount. An expense-adjusted net **profit** cannot be calculated without cost data; label the amount as `صافي مستحق العامل`, not accounting profit.
* Extension quote fields: `quoted_base_amount`, `quoted_admin_margin_amount`, `quoted_amount`, `quoted_currency` plus `additional_minutes`. Persist these as a signed snapshot at request time; never estimate acceptance terms locally. On accept, add base amount to service share and customer margin only to customer-side admin margin; apply only once.

## Per-status UX and operational contract

| Backend / worker status | Display | Relevant action / safeguard |
| --- | --- | --- |
| `pending`, unaccepted | Available offer: neighborhood-level location, requested room types/sizes/counts/cleaning modes, special-service preview, **worker-specific** financial offer | Accept; `لا أرغب باستلام الطلب`. Hide exact customer address and personal contact until assigned. |
| `pending`, worker accepted and team incomplete | Accepted; waiting for other workers, room ownership, worker-specific acceptance badge | No second accept or decline-as-new-offer; wait for team fulfillment. |
| `worker_assigned` | Assignment, accurate address, schedule, worker-level payment, next step | Start travel when permitted; multi-worker actions depend on **my** assignment timestamps. |
| Traveling / arrived | Map and address, trip/arrival progress | Confirm travel / arrival; customer start-code gate. |
| `awaiting_start_verification` | Waiting for customer's four-digit code verification | Do not start work before verification. |
| `awaiting_worker_start_confirmation` | Start approval / waiting for other workers | Show per-worker approval; global session begins only once all required workers approved. |
| `in_progress` | Actual work timer, planned vs elapsed duration, requested rooms/sizes/modes, special services, worker payable and SOS | Completion request and operational actions; no speculative countdown. |
| `awaiting_customer_completion` | Worker finished; awaiting customer response | Prevent duplicate completion and clearly explain waiting status. |
| `time_extension_requested` | Customer's requested minutes and **authoritative** service/admin/total breakdown | Allow worker acceptance only with complete quote fields; re-fetch warning API if embedded/push payload incomplete; idempotent accept/reject. |
| `partially_completed` | Partial completion and which tasks remain | **Follow-up QA:** backend enum supports this; verify explicit Flutter mapping and whether remaining tasks remain actionable. Current high-level `OrderDetailsUiState` lacks a dedicated case. |
| `under_dispute` | Dispute status, relevant operational explanation, not a new offer | No accept/reject; redirect resolution to authorized support. |
| `completed` | Historical room/tasks and final worker financials | Read-only completion and payout information, no active timer. |
| `cancelled` | Cancellation details, relevant payout / penalty information | Read-only, no worker action. |
| Worker-scoped rejected offer | Not available for *that worker* | Persist in `cleaning_booking_worker_rejections`, filter from home/orders/all worker query branches, `404` on direct show; do not cancel the customer booking for other workers. |

## Implementation reviewed

1. Backend booking response includes safe `roomRequirements` and `locationSummary` for pending offers, and extended `workerFinancials`. Legacy bookings without rows can derive **recorded** counts and sizes from property details, without fake room IDs or assigned workers.
2. `CleaningTimeWarningService` adds extension base amount to worker service share, without double-paying margin; `CleaningBookingResource` serializes warning breakdown consistently with warning resource.
3. Worker rejection visibility is worker-scoped; home/lists/detail refresh and navigation respond to success.
4. Flutter worker payment summary labels margin as customer-side, room information is displayed instead of an empty services card, and active session timer is redesigned. The estimated-price banner was removed from mission payment summary.
5. Synthetic extension Seeder now uses `CleaningExtendedTimePricingService::quoteForBooking` and persists explicit base/admin/total/currency, neighborhood, and room size breakdown. The test MySQL database was reseeded for synthetic extension scenarios.

## Actual database QA findings

The local MySQL test database had **68** cleaning bookings. At scan time, **58** had null `neighborhood_name` and **47** had no `cleaning_booking_rooms` rows; **39** regular-type bookings lacked rows. Not all records require rooms (e.g., event, open-time, older bookings). Do **not** backfill unknown physical room sizes or customer addresses with guessed values. New seed scenarios should always store location and size breakdown; historical customer bookings may need a migration only after domain-specific audit.

For the regenerated test extension scenarios:

| Minutes | Worker service base | Customer admin margin | Total extension charge |
| ---: | ---: | ---: | ---: |
| 30 | 25 SYP | 3 SYP | 28 SYP |
| 45 | 50 SYP | 5 SYP | 55 SYP |
| 60 | 100 SYP | 10 SYP | 110 SYP |

These base prices come from configured test ranges. Product/business owners should confirm whether the sample Syrian Pound values are commercially appropriate. Do not silently replace configured amounts with invented figures.

## Validation evidence

* Laravel: 95 passed, 435 assertions across booking worker actions, worker endpoints/filters/dashboard, extension warning actions and room requirements.
* Flutter: 38 passed across room task mapping, worker summary, extension breakdown, extension modal navigation, session schedule retry, operational details and completion prompts.
* Targeted Dart analyzer: no issues in changed order model, components and helpers.
* Android debug APK: successful offline Gradle build using cached dependencies and local backend `http://10.0.2.2:8000`; installed/launched on existing `emulator-5556`.
* Emulator initial smoke: login screen rendered. Authenticated full order detail and extension navigation remain to be manually verified on this newly installed app.

## Open items / release gate

* Verify all *authenticated* status transitions on the actual emulator, with worker seed login and normal customer/supervisor coordination. Widget and API tests are not a substitute for an end-to-end customer-to-worker test.
* Audit the `partially_completed` UI mapping and dispute completion interactions against current backend semantics.
* Decide on backfilling older test/historical requests with legitimate neighborhoods or room sizes only when source values exist.
* Keep unrelated already-modified files untouched and obtain a clean reviewed diff before staging/releasing.

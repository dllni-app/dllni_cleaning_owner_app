# Multi-Day Event Assistance — Flutter Worker App UI Flow & API Implementation Plan

## 1. Objective

Update the cleaning worker Flutter app so workers can evaluate, accept, schedule, execute, and complete multi-day event-assistance bookings safely.

Repository:

`dllni-app/dllni_cleaning_owner_app`

The worker must understand that accepting a Phase-1 multi-day event commits them to all active event days.

## 2. Phase-1 Worker Rules

1. One multi-day event is one parent booking.
2. Every event day is an independent session.
3. Worker acceptance commits to all active future sessions.
4. If the worker conflicts with any session, acceptance must fail.
5. Travel/arrival/security/start/complete/SOS are session-scoped.
6. The same required worker team serves all sessions in Phase 1.
7. Completing one session does not complete the booking.
8. Worker earnings are snapshotted per session and aggregated.
9. Calendar displays one occurrence per session.
10. Existing single-day orders remain supported.

## 3. Current Worker-App Areas to Refactor

Primary files:

- `lib/features/orders/data/models/fetch_orders_usecase_model.dart`
- `lib/core/widgets/order_card.dart`
- `lib/features/orders/view/widgets/order_info_card.dart`
- `lib/features/orders/view/widgets/order_details/order_details_body.dart`
- `lib/features/orders/view/widgets/order_details/order_details_mission_body.dart`
- `lib/features/orders/view/widgets/accept_order_bottom_sheet.dart`
- `lib/features/calender/view/screens/calender_screen.dart`
- `lib/features/calender/view/widgets/week_calender.dart`
- `lib/features/calender/view/widgets/calender_order_card.dart`
- related order repository/usecase/API files
- related homepage Bloc/model/widgets
- tracking/location lifecycle code

Current order model is parent-oriented and must be extended with schedule/session data.

## 4. Worker Journey

Target flow:

```text
Receive multi-day event order
        |
        v
See all dates/times + total commitment
        |
        v
Backend verifies availability for every day
        |
        v
Accept parent booking
        |
        v
Calendar gets one entry per session
        |
        v
On each event day:
Travel -> Arrive -> Verify -> Start -> Complete
        |
        v
Wait for next session
        |
        v
Final session completes parent booking
```

## 5. Data Models

Add:

```dart
class WorkerBookingSessionModel {
  final int id;
  final int sequence;
  final DateTime date;
  final String time;
  final double hours;
  final String status;
  final bool isToday;
  final WorkerSessionAssignmentModel? assignment;
  final WorkerSessionFinancialModel? financial;
}
```

Add aggregate schedule:

```dart
class WorkerBookingScheduleModel {
  final String mode;
  final int daysCount;
  final int completedDaysCount;
  final int cancelledDaysCount;
  final double totalHours;
  final WorkerBookingSessionModel? nextSession;
  final List<WorkerBookingSessionModel> sessions;
}
```

Extend `FetchOrdersUsecaseModelDataItem` with:

```text
schedule
scheduleMode
daysCount
completedDaysCount
cancelledDaysCount
nextSession
sessions
```

Prefer one structured `schedule` model rather than many duplicated flattened fields if compatible with current code style.

## 6. Backward-Compatible Parsing

If backend response has `schedule`:

- parse sessions
- use session-aware UI

If `schedule` is missing:

- build a legacy one-session view from:
  - scheduled date
  - scheduled time
  - total hours
  - parent status

The app must not crash during staged backend rollout.

## 7. New Order Card

For a multi-day event, `order_card.dart` should show:

```text
مساعدة مناسبة
3 أيام
10 - 13 سبتمبر
12 ساعة إجمالية
الجلسة القادمة: 11 سبتمبر - 5:00 م
عدد العمال المطلوب
السعر/المستحق حسب current business UI
```

Use a clear badge:

`طلب متعدد الأيام`

Do not show only the first date; that would hide the worker commitment.

## 8. Accept Order Bottom Sheet

Update `accept_order_bottom_sheet.dart`.

Before acceptance show every required active date:

```text
الخميس 10 سبتمبر — 6:00 م — 4 ساعات
الجمعة 11 سبتمبر — 5:00 م — 5 ساعات
الأحد 13 سبتمبر — 7:00 م — 3 ساعات
```

Show summary:

```text
عدد الأيام: 3
إجمالي الساعات: 12
```

Critical confirmation copy:

```text
بقبول الطلب أنت توافق على تنفيذ جميع أيام المناسبة الموضحة أعلاه.
```

Primary CTA:

`قبول جميع الأيام`

## 9. Acceptance API

Acceptance remains a parent booking decision in Phase 1 unless backend explicitly introduces a separate route.

The backend must re-check:

- schedule conflicts for every active session
- worker dispatch eligibility
- solvency/financial allowance
- gender/coverage requirements
- team constraints

Client handles structured error:

```json
{
  "reasonCode": "schedule_conflict",
  "conflicts": []
}
```

UI should show the conflicting date(s), not a generic failure only.

## 10. Conflict Error UX

Example:

```text
لا يمكنك قبول هذا الطلب لأن لديك تعارضاً في:
الجمعة 11 سبتمبر — 5:00 م إلى 10:00 م
```

Do not allow user to "accept remaining days" in Phase 1.

## 11. Calendar Model

One parent booking can create multiple calendar entries.

Create presentation model:

```dart
class WorkerCalendarSessionEntry {
  final int bookingId;
  final int sessionId;
  final int sequence;
  final int totalSessions;
  final DateTime date;
  final String time;
  final double hours;
  final String status;
}
```

Expansion:

```text
1 booking with 3 sessions
    ->
3 calendar entries
```

Each entry opens the same booking details with `selectedSessionId`.

## 12. Calendar UI

Update:

- `calender_screen.dart`
- `week_calender.dart`
- `calender_order_card.dart`

Card example:

```text
طلب #CL-1001
اليوم 2 من 3
الجمعة 11 سبتمبر
5:00 م
5 ساعات
```

Behavior:

- completed historical sessions remain visible according to current calendar policy
- cancelled session uses cancelled style
- active session highlights today
- opening card selects correct session

## 13. Order Details

Update order details to include:

### Parent summary

```text
booking number
customer
event type
location
days count
completed progress
required workers
team status
aggregate price/payout if shown
```

### Session selector

Use:

- horizontal chips for few sessions, or
- vertical timeline/list for better scalability

Each item:

```text
اليوم 1
التاريخ
الوقت
المدة
الحالة
```

Selected session drives mission actions.

## 14. Mission Screen

`order_details_mission_body.dart` must no longer use parent total hours as the active timer duration for a multi-day booking.

The mission context must contain:

```text
bookingId
sessionId
sessionDate
sessionTime
sessionHours
sessionStatus
sessionAssignmentStatus
```

All operational CTAs use the selected/active session.

## 15. Session Lifecycle API Calls

Use session routes for multi-day bookings:

```text
POST /cleaning-bookings/{booking}/sessions/{session}/start-travel
POST /cleaning-bookings/{booking}/sessions/{session}/location
POST /cleaning-bookings/{booking}/sessions/{session}/arrive
GET  /cleaning-bookings/{booking}/sessions/{session}/security-code
POST /cleaning-bookings/{booking}/sessions/{session}/start-work
POST /cleaning-bookings/{booking}/sessions/{session}/complete
POST /cleaning-bookings/{booking}/sessions/{session}/sos
```

Legacy one-session bookings continue to use existing endpoints until migration is complete.

Centralize route selection in repository/data-source methods rather than branching inside widgets.

## 16. Start Travel

Before enabling:

- selected session is today/eligible
- worker has accepted booking
- session assignment is active
- backend says action is allowed

After success:

- update selected session only
- start location tracking for this session
- emit/refetch parent state if needed

Do not mutate future sessions.

## 17. Location Tracking

Tracking payload must identify the session.

Recommended repository method:

```dart
updateSessionLocation({
  required int bookingId,
  required int sessionId,
  required double latitude,
  required double longitude,
})
```

On session completion/cancellation:

- stop location stream for that session
- future session tracking does not begin automatically

## 18. Arrive / Security Code / Start Work

All three are session-scoped.

Security code UI:

- code for Session 1 is not reused for Session 2
- refresh code state when switching sessions
- do not cache one booking-level code blindly

Start Work:

- timer uses selected session duration
- session-specific start timestamp

## 19. Work Timer

Timer source of truth:

```text
session.workStartedAt
session.durationHours
session extension state
```

Not:

```text
parent.totalHours
```

If extension is approved:

- update active session timer only
- reflect new session end time
- do not alter other session cards

## 20. Complete Session

Completion request targets selected session.

After Session 1/3 worker completion:

```text
session -> awaiting customer completion / completed per existing lifecycle
parent -> not completed
```

Worker UI should show:

```text
تم إنهاء عمل اليوم الأول.
بانتظار تأكيد العميل.
```

After customer confirms non-final day:

```text
تم إكمال اليوم الأول.
موعدك القادم: الجمعة 11 سبتمبر، 5:00 م.
```

Do not show whole-booking completion UI.

## 21. Final Session Completion

After final required session:

- parent booking becomes completed
- normal booking-completed UX applies
- aggregated earnings refresh
- booking moves to completed history according to current behavior

## 22. Extension Flow

Any extension request/response must display active session context:

```text
اليوم 2 من 3
المدة الأصلية
المدة الإضافية
المستحق الإضافي
```

Backend remains financial source of truth.

## 23. SOS

SOS must include:

```text
bookingId
sessionId
```

UI must indicate which day/session triggered the SOS.

Do not attach all future session context as if the entire booking is in emergency state unless backend parent status explicitly changes.

## 24. Homepage

Update homepage models and widgets to support session-aware backend response.

Recommended concepts:

```text
todayBookingsCount
todaySessionsCount
todayEarnings
upcomingSessions
sessionsWeeklyChart
```

Worker home should show the next actionable session, not only parent first date.

Example:

```text
اليوم لديك جلستان
القادم: طلب #CL-1001 — اليوم 2/3 — 5:00 م
```

## 25. New Orders Visibility

Backend should already exclude multi-day orders when any session conflicts.

Client responsibilities:

- render returned available orders
- show multi-day badge
- show all commitment dates before acceptance
- handle acceptance conflict if state changed between fetch and tap

Never rely on client-only schedule checking.

## 26. Earnings

If app shows earnings per order/day:

- parse session worker financial snapshots
- today earnings should use sessions executed/scheduled per backend business semantics
- parent order can still show aggregate worker earning
- session detail can show session payout when product wants it

Avoid summing displayed strings client-side as authoritative finance logic.

## 27. Team Status

Same worker team is expected on all sessions in Phase 1.

Parent summary can show:

```text
2 / 3 workers accepted
1 worker remaining
```

Session details may show assignment state for each worker if backend returns it.

Do not let worker assume team fulfillment on one day means a different team on another day.

## 28. Realtime Events

Handle:

```text
bookingId
sessionId
sessionSequence
sessionDate
```

Recommended event types:

```text
cleaning_session.worker_travel_started
cleaning_session.worker_location_updated
cleaning_session.worker_arrived
cleaning_session.start_verified
cleaning_session.started
cleaning_session.awaiting_customer_completion
cleaning_session.extension_requested
cleaning_session.completed
cleaning_session.cancelled
```

Update only matching session.

Refetch parent details when aggregate team/status/financial values may have changed.

## 29. Notifications / Deep Links

Notification navigation should support:

```text
bookingId
sessionId
```

When opened:

1. open booking details
2. select/highlight session
3. show relevant action state

Examples:

- today's session reminder
- customer confirmed start
- extension accepted/rejected
- session cancelled
- next session reminder

## 30. State Management

Suggested state additions:

```text
selectedSessionId
schedule
sessionActionStatusById
```

Avoid one global lifecycle loading flag if it blocks unrelated UI.

Potential events:

```text
SelectBookingSession
StartSessionTravel
ArriveForSession
FetchSessionSecurityCode
StartSessionWork
CompleteSessionWork
SendSessionSos
RefreshBooking
```

Follow existing Bloc/usecase/repository architecture.

## 31. API Repository Design

Prefer methods with explicit session context:

```dart
startTravel({bookingId, sessionId})
updateLocation({bookingId, sessionId, lat, lng})
arrive({bookingId, sessionId})
getSecurityCode({bookingId, sessionId})
startWork({bookingId, sessionId, code})
complete({bookingId, sessionId, message})
sendSos({bookingId, sessionId, ...})
```

Repository may internally fall back to legacy booking routes for one-session legacy bookings.

## 32. UI States and Empty Cases

Required:

```text
لا توجد جلسة قادمة.
لا توجد مهام لهذا اليوم.
تم إلغاء هذه الجلسة.
تم إكمال هذه الجلسة.
بانتظار موعد الجلسة القادمة.
```

If parent has sessions but all future sessions cancelled, show historical completed sessions plus aggregate cancelled/completed parent state from backend.

## 33. RTL / Responsiveness

- Arabic RTL
- cards fit small devices
- date ranges wrap correctly
- long customer address does not overflow
- session chips scroll or wrap safely
- acceptance sheet can scroll when many days exist
- CTA remains reachable
- existing visual design system is preserved

## 34. Worker App Tests

### Models

- parse multi-day schedule
- parse session assignments
- legacy fallback
- unknown status safe fallback

### Order card / accept

- multi-day badge visible
- all dates shown in acceptance sheet
- confirm copy present
- conflict error lists date(s)

### Calendar

- one booking expands to all sessions
- each card opens correct session
- completed/cancelled session styling

### Details / mission

- selected session controls CTAs
- session timer uses session duration
- switching session changes mission state
- future session cannot start early

### API

- lifecycle calls contain session id
- location contains session id
- SOS contains session id
- legacy route fallback works

### Completion

- first session completion does not show booking completed
- next session shown
- final completion shows booking completed

### Realtime

- correct session updates
- unrelated events ignored
- parent refetch after aggregate update

### Homepage / earnings

- next session shown
- today counts parsed
- today earnings use backend values

## 35. Implementation Order

### Phase A — Models / repository

- schedule/session parsing
- explicit session APIs
- legacy fallback

### Phase B — browse / acceptance

- order cards
- multi-day badge
- accept bottom sheet
- conflict errors

### Phase C — calendar / details

- session calendar entries
- session selector
- next-session UI

### Phase D — mission lifecycle

- travel
- location
- arrive
- security code
- start
- timer
- complete
- extension
- SOS

### Phase E — homepage / realtime

- session metrics
- next session
- earnings
- notifications
- deep links

### Phase F — QA

- legacy regression
- RTL/small screens
- lifecycle race conditions
- network recovery

## 36. Definition of Done

Worker app work is complete when:

- multi-day orders clearly show all worker commitments before acceptance
- worker cannot mistakenly think only the first day is accepted
- conflict errors identify affected dates
- calendar renders one occurrence per event session
- details allow selecting the correct session
- every mission action sends session id
- timer and security code are session-scoped
- completing one day does not complete the parent
- next session is shown after non-final completion
- final session completes the booking
- homepage/earnings use session-aware backend data
- realtime and notifications target the correct session
- existing single-day worker flows continue to work

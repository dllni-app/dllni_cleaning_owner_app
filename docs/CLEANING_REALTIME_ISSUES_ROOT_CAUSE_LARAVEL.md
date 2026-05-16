# Laravel-Side Root Causes (Cleaning Realtime QA)

Date: 2026-05-13
Scope: API validation, realtime event delivery, and auth/session behavior affecting cleaning lifecycle gates.

## Issue 1: Secure-code dialog did not consistently appear at `awaiting_start_verification`

### Observed behavior
- Worker reached arrival gate and backend state moved to `awaiting_start_verification`.
- User UI did not always receive/show a global verification prompt.

### Most likely Laravel/backend causes
- Missing or inconsistent customer-scoped realtime event for verification gate:
  - Event may be emitted only to order-specific channels or not emitted on all transition paths.
- Event payload may be insufficient for app-global routing:
  - Missing stable fields like `order_id`, `booking_number`, `gate_type`, `issued_at`.
- Broadcast ordering/idempotency gaps:
  - If status update and event publish are not atomic/idempotent, client can observe state without prompt event.

### Laravel fixes
- Emit mandatory customer-scoped gate event on every transition to `awaiting_start_verification`.
- Standardize payload contract for gate events.
- Ensure transactional consistency between status transition and broadcast dispatch.

---

## Issue 2: `filter[status]=awaiting_start_verification` returns 422

### Observed behavior
- Endpoint:
  - `GET /api/v1/user/cleaning/orders?filter[status]=awaiting_start_verification`
- Response:
  - HTTP `422`, `The selected filter.status is invalid.`

### Most likely Laravel/backend causes
- Validation rule for `filter.status` is out of sync with lifecycle statuses used by realtime/state machine.
- API contract and implementation diverged:
  - Realtime/status machine recognizes gate status, list-filter validator does not.

### Laravel fixes
- Align `filter.status` validation enum with full lifecycle states used in cleaning workflow.
- Add regression tests for each lifecycle status in list/filter endpoints.
- Publish canonical status dictionary used by both API validators and realtime emitters.

---

## Issue 3: Session/token instability under parallel QA

### Observed behavior
- Active app sessions were occasionally invalidated and required relogin.

### Most likely Laravel/backend causes
- Token policy may invalidate prior tokens on new login for same account/device set.
- Auth middleware may treat transient token checks as hard logout events.
- Multiple token issuers (worker/customer apps + QA scripts) may conflict without clear session policy.

### Laravel fixes
- Clarify and enforce explicit multi-session policy:
  - allow concurrent sessions per device/account where intended.
- If single-session policy is required, return explicit reason codes so clients can handle gracefully.
- Add auth audit logs for token revocation source and timestamp.

---

## Recommended backend verification tests
- Transition to `awaiting_start_verification` emits exactly one customer-scoped gate event.
- `filter.status` accepts all lifecycle values used by state machine and realtime.
- Parallel logins do not unexpectedly revoke active app sessions unless policy explicitly requires it.

## Confidence note
- These are runtime QA-driven root-cause hypotheses and should be confirmed with server logs, event bus traces, and request validator rules.


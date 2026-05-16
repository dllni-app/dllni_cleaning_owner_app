# Flutter-Side Root Causes (Cleaning Realtime QA)

Date: 2026-05-13
Scope: `dllni_cleaninig_owner_app` + `dllni-user-app` client behavior observed during two-device live QA.

## Issue 1: Secure-code dialog did not consistently appear at `awaiting_start_verification`

### Observed behavior
- Order reached `awaiting_start_verification` on backend.
- User app did not always show the secure-code dialog when user was outside order-details flow.

### Most likely Flutter/client causes
- Verification prompt trigger is not fully app-global:
  - Dialog display logic appears tied to a specific screen/bloc lifecycle instead of a top-level app gate coordinator.
- Realtime subscription scope mismatch:
  - Client may subscribe only to order-details or active-order stream, not a persistent customer-scoped gate stream.
- Foreground/resume race:
  - Event can arrive while screen tree is rebuilding, then be dropped if no durable queue/state replay exists.

### Flutter fixes
- Keep a single app-level verification gate coordinator mounted under app root (always alive).
- Persist pending verification intents in app state and replay on resume/rebuild.
- Decouple dialog triggering from order-details page visibility.

---

## Issue 2: `filter[status]=awaiting_start_verification` produced 422 in user app flows

### Observed behavior
- User app requested:
  - `GET /api/v1/user/cleaning/orders?filter[status]=awaiting_start_verification`
- Backend returned HTTP `422` with message: `The selected filter.status is invalid.`

### Most likely Flutter/client causes
- Client enum/value list contains `awaiting_start_verification`, but endpoint currently validates against a different status whitelist.
- Client assumes contract parity between realtime status values and list-filter values without fallback mapping.

### Flutter fixes
- Add defensive status mapping layer before sending list filters.
- If backend rejects a status filter, fallback to unfiltered fetch + local filter while logging mismatch.
- Surface contract mismatch in diagnostics (non-fatal) to avoid breaking realtime UX.

---

## Issue 3: Session/token instability during parallel QA

### Observed behavior
- Sessions were occasionally forced back to login during parallel/device/API testing.

### Most likely Flutter/client causes
- Tokens can be overwritten/rotated in shared storage when multiple login paths run during QA.
- Realtime/auth retry flow may treat transient auth failures as terminal and navigate to login too aggressively.
- App does not isolate manual QA API logins from in-app session context.

### Flutter fixes
- Harden token lifecycle handling:
  - avoid immediate logout on first auth failure,
  - retry once and refresh profile/session state.
- Add session diagnostics (token issue timestamp/source).
- In QA scripts, avoid account re-login while app session is active.

---

## Evidence sources (from QA run)
- User app logs showed repeated 422 for `filter[status]=awaiting_start_verification`.
- UI state checks showed missing secure-code modal in some global-navigation contexts.
- Device sessions showed relogin interrupts during parallel auth/test operations.

## Confidence note
- These are evidence-based root-cause hypotheses from runtime QA; exact ownership must be confirmed with backend contract and event tracing.

